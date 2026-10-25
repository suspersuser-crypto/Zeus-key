import json
import time
import os
import random
import string
import threading
import psycopg2
import psycopg2.extras
from flask import Flask, request, jsonify

app = Flask(__name__)

START_TIME = time.time()
CHECK_COUNTER = {"total": 0, "ok": 0, "fail": 0}
DOWNLOAD_COUNTER = {"full": 0, "lite": 0, "aggressive": 0}
DB_BACKUP_DIR = "/tmp/zeusx_backups"

CURRENT_VERSIONS = {
    "lite": "3.4",
    "aggressive": "1.0"
}

BASE_SCRIPT_URL = os.environ.get(
    "BASE_SCRIPT_URL",
    "https://suspersuser-crypto.github.io/Zeus-key"
).rstrip("/")

@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response

DATABASE_URL = os.environ.get('DATABASE_URL', '')
MAX_ACTIVATIONS = 50
ADMIN_LOGIN = os.environ.get("ADMIN_LOGIN", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "")
ADMIN_KEY = os.environ.get("ADMIN_KEY", "zeushack")
HWID_RESET_COOLDOWN_DAYS = int(os.environ.get("HWID_RESET_COOLDOWN_DAYS", "30"))

CHECK_RATE = {}
CHECK_LIMIT_PER_MIN = 30
CHECK_BLOCK_SEC = 60

failed_attempts = {}
MAX_FAILED = 3

def get_db():
    return psycopg2.connect(DATABASE_URL)

def init_db():
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS keys (
                    key TEXT PRIMARY KEY, expiry BIGINT NOT NULL, hwid TEXT,
                    used BOOLEAN DEFAULT FALSE, activated_at BIGINT, ip TEXT,
                    username TEXT, banned BOOLEAN DEFAULT FALSE,
                    last_hwid_reset BIGINT DEFAULT 0, version TEXT DEFAULT 'unknown',
                    tg_username TEXT DEFAULT '—', tg_id BIGINT DEFAULT 0
                )
            """)
            cur.execute("CREATE TABLE IF NOT EXISTS settings (name TEXT PRIMARY KEY, value TEXT)")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS activations (
                    id SERIAL PRIMARY KEY, key TEXT NOT NULL, hwid TEXT, ip TEXT,
                    username TEXT, version TEXT, activated_at BIGINT NOT NULL,
                    tg_username TEXT DEFAULT '—', tg_id BIGINT DEFAULT 0
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS check_log (
                    id SERIAL PRIMARY KEY, key TEXT, hwid TEXT, ip TEXT,
                    username TEXT, version TEXT, checked_at BIGINT NOT NULL
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS downloads (
                    id SERIAL PRIMARY KEY, version TEXT NOT NULL, ip TEXT, downloaded_at BIGINT NOT NULL
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS promocodes (
                    code TEXT PRIMARY KEY, days INTEGER NOT NULL,
                    max_uses INTEGER NOT NULL, uses INTEGER DEFAULT 0
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS bot_users (
                    tg_id BIGINT PRIMARY KEY, username TEXT, first_name TEXT,
                    promo_used TEXT, join_date BIGINT NOT NULL, last_seen BIGINT NOT NULL
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS temp_admins (
                    login TEXT PRIMARY KEY, password TEXT NOT NULL, expires_at BIGINT NOT NULL,
                    last_ip TEXT DEFAULT '—', last_agent TEXT DEFAULT '—', last_login BIGINT DEFAULT 0
                )
            """)
            cur.execute("SELECT value FROM settings WHERE name='activations_left'")
            if cur.fetchone() is None:
                cur.execute("INSERT INTO settings (name, value) VALUES ('activations_left', %s)", (str(MAX_ACTIVATIONS),))
            for alter in [
                "ALTER TABLE keys ADD COLUMN IF NOT EXISTS last_hwid_reset BIGINT DEFAULT 0",
                "ALTER TABLE keys ADD COLUMN IF NOT EXISTS version TEXT DEFAULT 'unknown'",
                "ALTER TABLE keys ADD COLUMN IF NOT EXISTS tg_username TEXT DEFAULT '—'",
                "ALTER TABLE keys ADD COLUMN IF NOT EXISTS tg_id BIGINT DEFAULT 0",
                "ALTER TABLE activations ADD COLUMN IF NOT EXISTS tg_username TEXT DEFAULT '—'",
                "ALTER TABLE activations ADD COLUMN IF NOT EXISTS tg_id BIGINT DEFAULT 0",
                "ALTER TABLE temp_admins ADD COLUMN IF NOT EXISTS last_ip TEXT DEFAULT '—'",
                "ALTER TABLE temp_admins ADD COLUMN IF NOT EXISTS last_agent TEXT DEFAULT '—'",
                "ALTER TABLE temp_admins ADD COLUMN IF NOT EXISTS last_login BIGINT DEFAULT 0",
                "CREATE INDEX IF NOT EXISTS idx_check_log_time ON check_log (checked_at)",
                "CREATE INDEX IF NOT EXISTS idx_downloads_time ON downloads (downloaded_at)",
            ]:
                try: cur.execute(alter)
                except: pass
        conn.commit()
def get_activations_left():
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT value FROM settings WHERE name='activations_left'")
            row = cur.fetchone()
            return int(row[0]) if row else 0

def set_activations_left(n):
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE settings SET value=%s WHERE name='activations_left'", (str(n),))
        conn.commit()

def generate_random_key():
    def part(n): return ''.join(random.choices(string.ascii_uppercase + string.digits, k=n))
    return f"VANTA-{part(4)}-{part(4)}-{part(4)}"

def generate_keys_db(count=50, min_days=1, max_days=20):
    now = int(time.time())
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM keys")
            cur.execute("DELETE FROM activations")
            for _ in range(count):
                key = generate_random_key()
                while True:
                    cur.execute("SELECT 1 FROM keys WHERE key=%s", (key,))
                    if cur.fetchone() is None: break
                    key = generate_random_key()
                days = random.randint(min_days, max_days)
                cur.execute("""
                    INSERT INTO keys (key, expiry, hwid, used, activated_at, ip, username, banned, last_hwid_reset, version, tg_username, tg_id)
                    VALUES (%s, %s, NULL, FALSE, NULL, NULL, NULL, FALSE, 0, 'unknown', '—', 0)
                """, (key, now + days * 86400))
            cur.execute("UPDATE settings SET value=%s WHERE name='activations_left'", (str(count),))
        conn.commit()

def get_client_ip():
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr or "unknown"

# === ЖЕСТКАЯ БЛОКИРОВКА ===
def is_blocked(ip):
    if ip not in failed_attempts: return False
    info = failed_attempts[ip]
    # Если счетчик больше или равен 3, значит заблокирован навсегда
    return info.get("count", 0) >= MAX_FAILED

def register_fail(ip):
    if ip not in failed_attempts: failed_attempts[ip] = {"count": 0}
    failed_attempts[ip]["count"] += 1

def check_admin_auth():
    ip = get_client_ip()
    user_agent = request.headers.get('User-Agent', 'Unknown')[:100]
    
    # Если IP в черном списке — сразу отказ
    if is_blocked(ip): 
        return False, "banned_ip"
        
    login = request.args.get('login', '')
    pwd = request.args.get('pwd', '')
    
    # 1. Главный админ
    if ADMIN_PASSWORD and login == ADMIN_LOGIN and pwd == ADMIN_PASSWORD:
        return True, "ok"
        
    # 2. Временный админ
    try:
        with get_db() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("SELECT * FROM temp_admins WHERE login=%s AND password=%s", (login, pwd))
                temp = cur.fetchone()
                if temp:
                    if time.time() < temp["expires_at"]:
                        cur.execute("UPDATE temp_admins SET last_ip=%s, last_agent=%s, last_login=%s WHERE login=%s",
                                    (ip, user_agent, int(time.time()), login))
                        conn.commit()
                        return True, "ok"
                    else:
                        cur.execute("DELETE FROM temp_admins WHERE login=%s", (login,))
                        conn.commit()
                        return False, "expired"
    except:
        pass
        
    # Если пароль неверный — регистрируем провал
    register_fail(ip)
    return False, "wrong_credentials"

def check_root_auth():
    login = request.args.get('login', '')
    pwd = request.args.get('pwd', '')
    return bool(ADMIN_PASSWORD and login == ADMIN_LOGIN and pwd == ADMIN_PASSWORD)

def check_rate_limit(ip):
    now = time.time()
    if ip in CHECK_RATE: CHECK_RATE[ip] = [t for t in CHECK_RATE[ip] if now - t < CHECK_BLOCK_SEC]
    else: CHECK_RATE[ip] = []
    if len(CHECK_RATE[ip]) >= CHECK_LIMIT_PER_MIN: return False
    CHECK_RATE[ip].append(now)
    return True

@app.route('/version')
def version():
    ver_type = request.args.get('type', 'lite').lower()
    if ver_type not in CURRENT_VERSIONS:
        return jsonify({"ok": False, "reason": "unknown_type"})
    url = f"{BASE_SCRIPT_URL}/cheat-{ver_type}.lua"
    return jsonify({"ok": True, "version": CURRENT_VERSIONS[ver_type], "url": url})

@app.route('/check')
def check():
    token = request.args.get('token', '').strip()
    hwid = request.args.get('hwid', '').strip()
    username = request.args.get('username', '').strip()
    version = request.args.get('ver', 'unknown').strip()
    tg_username = request.args.get('tg_username', '—').strip()
    tg_id = int(request.args.get('tg_id', 0))
    ip = get_client_ip()

    if token != ADMIN_KEY and not check_rate_limit(ip):
        return jsonify({"ok": False, "reason": "too_many_attempts"})

    CHECK_COUNTER["total"] += 1

    if token == ADMIN_KEY:
        CHECK_COUNTER["ok"] += 1
        return jsonify({"ok": True, "left": 9999999999, "admin": True})

    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM keys WHERE key=%s", (token,))
            info = cur.fetchone()
            if not info: return jsonify({"ok": False, "reason": "invalid"})
            if info["banned"]: return jsonify({"ok": False, "reason": "banned"})
            if info["hwid"] and info["hwid"] != hwid: return jsonify({"ok": False, "reason": "hwid_mismatch"})
            if time.time() > info["expiry"]: return jsonify({"ok": False, "reason": "expired"})

            cur.execute("SELECT value FROM settings WHERE name='activations_left'")
            row = cur.fetchone()
            activations_left = int(row["value"]) if row else 0

            if not info["used"]:
                if activations_left <= 0:
                    return jsonify({"ok": False, "reason": "no_activations"})
                now = int(time.time())
                cur.execute("UPDATE keys SET used=TRUE, hwid=%s, activated_at=%s, ip=%s, username=%s, version=%s, tg_username=%s, tg_id=%s WHERE key=%s",
                            (hwid, now, ip, username, version, tg_username, tg_id, token))
                cur.execute("INSERT INTO activations (key, hwid, ip, username, version, activated_at, tg_username, tg_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                            (token, hwid, ip, username, version, now, tg_username, tg_id))
                cur.execute("UPDATE settings SET value=%s WHERE name='activations_left'", (str(activations_left - 1),))
                activations_left -= 1
            else:
                cur.execute("UPDATE keys SET username=%s, tg_username=%s, tg_id=%s, ip=%s WHERE key=%s", (username, tg_username, tg_id, ip, token))
            conn.commit()

    return jsonify({
        "ok": True,
        "left": int(info["expiry"] - time.time()),
        "activations_left": activations_left,
    })
@app.route('/admin/login')
def admin_login():
    ok, reason = check_admin_auth()
    if ok: return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": reason})

@app.route('/admin/keys')
def admin_keys():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    now = time.time()
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM keys ORDER BY used ASC, expiry DESC")
            rows = cur.fetchall()
    result = []
    for info in rows:
        expired = now > info["expiry"]
        used = info["used"]
        banned = info["banned"]
        status = "red" if (banned or expired) else ("green" if used else "grey")
        result.append({
            "key": info["key"], "status": status, "used": used, "banned": banned,
            "expired": expired, "hwid": info["hwid"], "activated_at": info["activated_at"],
            "ip": info["ip"], "username": info["username"], "expiry": info["expiry"],
            "days_left": max(0, int((info["expiry"] - now) / 86400)),
            "version": info.get("version") or "unknown",
            "tg_username": info.get("tg_username") or "—",
            "tg_id": info.get("tg_id") or 0,
        })
    return jsonify({"ok": True, "activations_left": get_activations_left(), "total_keys": len(rows), "keys": result})

@app.route('/admin/activations')
def admin_activations():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM activations ORDER BY activated_at DESC LIMIT 200")
            rows = cur.fetchall()
    return jsonify({"ok": True, "activations": rows})

@app.route('/admin/bot_users')
def admin_bot_users():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM bot_users ORDER BY join_date DESC")
            rows = cur.fetchall()
    return jsonify({"ok": True, "users": rows})

@app.route('/admin/create_promo')
def admin_create_promo():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    code = request.args.get('code', '').strip().upper()
    days = int(request.args.get('days', '3'))
    max_uses = int(request.args.get('max_uses', '10'))
    if not code: return jsonify({"ok": False, "reason": "empty_code"})
    with get_db() as conn:
        with conn.cursor() as cur:
            try:
                cur.execute("INSERT INTO promocodes (code, days, max_uses, uses) VALUES (%s, %s, %s, 0)", (code, days, max_uses))
                conn.commit()
                return jsonify({"ok": True, "code": code})
            except psycopg2.errors.UniqueViolation:
                conn.rollback()
                return jsonify({"ok": False, "reason": "code_exists"})

@app.route('/admin/stats')
def admin_stats():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    now = time.time()
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM keys"); total = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM keys WHERE used=TRUE"); used = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM keys WHERE used=TRUE AND banned=FALSE AND expiry > %s", (now,)); active = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM keys WHERE banned=TRUE"); banned = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM activations WHERE activated_at > %s", (now - 86400,)); act_today = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM activations WHERE activated_at > %s", (now - 7 * 86400,)); act_week = cur.fetchone()[0]
            cur.execute("SELECT COUNT(DISTINCT hwid) FROM check_log WHERE checked_at > %s", (now - 300,)); online_5min = cur.fetchone()[0]
    return jsonify({
        "ok": True, "activations_left": get_activations_left(), "total_keys": total, "used_keys": used,
        "active_keys": active, "banned_keys": banned, "activations_today": act_today,
        "activations_week": act_week, "online_5min": online_5min
    })

@app.route('/admin/ban')
def admin_ban():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    key = request.args.get('key', '')
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE keys SET banned=TRUE WHERE key=%s", (key,))
        conn.commit()
    return jsonify({"ok": True})

@app.route('/admin/unban')
def admin_unban():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    key = request.args.get('key', '')
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE keys SET banned=FALSE WHERE key=%s", (key,))
        conn.commit()
    return jsonify({"ok": True})

@app.route('/admin/reset_hwid')
def admin_reset_hwid():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    key = request.args.get('key', '')
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE keys SET hwid=NULL, used=FALSE, last_hwid_reset=0 WHERE key=%s", (key,))
        conn.commit()
    return jsonify({"ok": True})

# === ЭНДПОИНТЫ ДЛЯ БЛОКИРОВКИ IP ===
@app.route('/admin/blocked_ips')
def admin_blocked_ips():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    
    blocked_list = []
    for ip, data in failed_attempts.items():
        if data.get("count", 0) >= MAX_FAILED:
            blocked_list.append({"ip": ip, "attempts": data["count"]})
    return jsonify({"ok": True, "blocked": blocked_list})

@app.route('/admin/unblock_ip')
def admin_unblock_ip():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    
    ip = request.args.get('ip', '')
    if ip in failed_attempts:
        del failed_attempts[ip]
    return jsonify({"ok": True})

# === ЭНДПОИНТЫ ДЛЯ ROOT-ПАНЕЛИ ===
@app.route('/root/create_temp')
def root_create_temp():
    if not check_root_auth(): return jsonify({"ok": False, "reason": "access_denied"})
    minutes = int(request.args.get('minutes', '30'))
    now = int(time.time())
    def rand_str(n): return ''.join(random.choices(string.ascii_lowercase + string.digits, k=n))
    login = "mod_" + rand_str(5)
    pwd = rand_str(8)
    expires_at = now + (minutes * 60)
    with get_db() as conn:
        with conn.cursor() as cur:
            try:
                cur.execute("INSERT INTO temp_admins (login, password, expires_at) VALUES (%s, %s, %s)", (login, pwd, expires_at))
                conn.commit()
                return jsonify({"ok": True, "login": login, "pwd": pwd, "minutes": minutes})
            except Exception as e:
                return jsonify({"ok": False, "reason": str(e)})

@app.route('/root/temp_list')
def root_temp_list():
    if not check_root_auth(): return jsonify({"ok": False, "reason": "access_denied"})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM temp_admins ORDER BY expires_at DESC")
            rows = cur.fetchall()
    return jsonify({"ok": True, "admins": rows})

@app.route('/api/bot_start')
def api_bot_start():
    user_id = request.args.get('userId')
    username = request.args.get('username', 'no_username')
    first_name = request.args.get('firstName', 'User')
    if not user_id:
        return jsonify({"ok": False, "reason": "no_user_id"})
    now = int(time.time())
    promo = None
    is_new = False
    try:
        with get_db() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("SELECT * FROM bot_users WHERE tg_id=%s", (user_id,))
                user = cur.fetchone()
                if not user:
                    is_new = True
                    promo = generate_random_key().replace('VANTA', 'PROMO')
                    cur.execute("INSERT INTO promocodes (code, days, max_uses, uses) VALUES (%s, 3, 1, 0)", (promo,))
                    cur.execute("INSERT INTO bot_users (tg_id, username, first_name, promo_used, join_date, last_seen) VALUES (%s, %s, %s, %s, %s, %s)", (user_id, username, first_name, promo, now, now))
                else:
                    cur.execute("UPDATE bot_users SET last_seen=%s WHERE tg_id=%s", (now, user_id))
            conn.commit()
    except Exception as e:
        print("[API BOT ERROR]", e)
        return jsonify({"ok": False, "reason": "db_error"})
    return jsonify({"ok": True, "is_new": is_new, "promo": promo})
def _backup_worker():
    os.makedirs(DB_BACKUP_DIR, exist_ok=True)
    while True:
        try:
            with get_db() as conn:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute("SELECT * FROM keys"); keys = cur.fetchall()
                    cur.execute("SELECT * FROM activations ORDER BY id DESC LIMIT 1000"); acts = cur.fetchall()
            snap = {"ts": int(time.time()), "keys": [dict(k) for k in keys], "activations": [dict(a) for a in acts]}
            fname = os.path.join(DB_BACKUP_DIR, f"backup_{int(time.time())}.json")
            with open(fname, "w") as f: json.dump(snap, f, indent=2, default=str)
            files = sorted([f for f in os.listdir(DB_BACKUP_DIR) if f.startswith("backup_")])
            for old in files[:-7]:
                try: os.remove(os.path.join(DB_BACKUP_DIR, old))
                except: pass
        except Exception as e: print("[backup error]", e)
        time.sleep(86400)

@app.route('/')
def index():
    return "Zeus-X v3.4 keygate is running (postgres)"

try:
    init_db()
    print("[zeusx] database initialized")
    threading.Thread(target=_backup_worker, daemon=True).start()
except Exception as e:
    print("[init_db error]", e)
@app.route('/root/create_temp')
def root_create_temp():
    ...

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)