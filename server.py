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
MAX_FAILED = 5
BLOCK_TIME = 3600

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
                    last_hwid_reset BIGINT DEFAULT 0, version TEXT DEFAULT 'unknown'
                )
            """)
            cur.execute("CREATE TABLE IF NOT EXISTS settings (name TEXT PRIMARY KEY, value TEXT)")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS activations (
                    id SERIAL PRIMARY KEY, key TEXT NOT NULL, hwid TEXT, ip TEXT,
                    username TEXT, version TEXT, activated_at BIGINT NOT NULL
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
            cur.execute("SELECT value FROM settings WHERE name='activations_left'")
            if cur.fetchone() is None:
                cur.execute("INSERT INTO settings (name, value) VALUES ('activations_left', %s)", (str(MAX_ACTIVATIONS),))
            for alter in [
                "ALTER TABLE keys ADD COLUMN IF NOT EXISTS last_hwid_reset BIGINT DEFAULT 0",
                "ALTER TABLE keys ADD COLUMN IF NOT EXISTS version TEXT DEFAULT 'unknown'",
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
                    INSERT INTO keys (key, expiry, hwid, used, activated_at, ip, username, banned, last_hwid_reset, version)
                    VALUES (%s, %s, NULL, FALSE, NULL, NULL, NULL, FALSE, 0, 'unknown')
                """, (key, now + days * 86400))
            cur.execute("UPDATE settings SET value=%s WHERE name='activations_left'", (str(count),))
        conn.commit()
def get_client_ip():
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr or "unknown"

def is_blocked(ip):
    if ip not in failed_attempts: return False
    info = failed_attempts[ip]
    if info.get("blocked_until", 0) > time.time(): return True
    if info.get("blocked_until", 0) > 0:
        failed_attempts[ip] = {"count": 0, "blocked_until": 0}
    return False

def register_fail(ip):
    if ip not in failed_attempts: failed_attempts[ip] = {"count": 0, "blocked_until": 0}
    failed_attempts[ip]["count"] += 1
    if failed_attempts[ip]["count"] >= MAX_FAILED:
        failed_attempts[ip]["blocked_until"] = time.time() + BLOCK_TIME

def check_admin_auth():
    ip = get_client_ip()
    if is_blocked(ip): return False, "too_many_attempts"
    login = request.args.get('login', '')
    pwd = request.args.get('pwd', '')
    if not ADMIN_PASSWORD: return False, "admin_password_not_set"
    if login != ADMIN_LOGIN or pwd != ADMIN_PASSWORD:
        register_fail(ip)
        return False, "wrong_credentials"
    if ip in failed_attempts: failed_attempts[ip] = {"count": 0, "blocked_until": 0}
    return True, "ok"

def check_rate_limit(ip):
    now = time.time()
    if ip in CHECK_RATE: CHECK_RATE[ip] = [t for t in CHECK_RATE[ip] if now - t < CHECK_BLOCK_SEC]
    else: CHECK_RATE[ip] = []
    if len(CHECK_RATE[ip]) >= CHECK_LIMIT_PER_MIN: return False
    CHECK_RATE[ip].append(now)
    return True

def log_check(token, hwid, ip, username, version, ok, reason):
    if token == ADMIN_KEY: return
    try:
        with get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO check_log (key, hwid, ip, username, version, checked_at)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (token, hwid, ip, username, version, int(time.time())))
                cur.execute("DELETE FROM check_log WHERE checked_at < %s", (int(time.time()) - 86400,))
            conn.commit()
    except: pass

@app.route('/version')
def version():
    ver_type = request.args.get('type', 'lite').lower()
    if ver_type not in CURRENT_VERSIONS:
        return jsonify({"ok": False, "reason": "unknown_type"})
    url = f"{BASE_SCRIPT_URL}/cheat-{ver_type}.lua"
    return jsonify({
        "ok": True,
        "version": CURRENT_VERSIONS[ver_type],
        "url": url
    })

@app.route('/check')
def check():
    token = request.args.get('token', '').strip()
    hwid = request.args.get('hwid', '').strip()
    username = request.args.get('username', '').strip()
    version = request.args.get('ver', 'unknown').strip()
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
                cur.execute("UPDATE keys SET used=TRUE, hwid=%s, activated_at=%s, ip=%s, username=%s, version=%s WHERE key=%s",
                            (hwid, now, ip, username, version, token))
                cur.execute("INSERT INTO activations (key, hwid, ip, username, version, activated_at) VALUES (%s, %s, %s, %s, %s, %s)",
                            (token, hwid, ip, username, version, now))
                cur.execute("UPDATE settings SET value=%s WHERE name='activations_left'", (str(activations_left - 1),))
                activations_left -= 1
            else:
                if version and version != info.get("version"):
                    cur.execute("UPDATE keys SET version=%s WHERE key=%s", (version, token))
            conn.commit()

    return jsonify({
        "ok": True,
        "left": int(info["expiry"] - time.time()),
        "activations_left": activations_left,
    })

@app.route('/user/info')
def user_info():
    token = request.args.get('token', '').strip()
    if not token: return jsonify({"ok": False, "reason": "no_token"})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM keys WHERE key=%s", (token,))
            info = cur.fetchone()
            if not info: return jsonify({"ok": False, "reason": "invalid"})
            now = int(time.time())
            return jsonify({
                "ok": True, "used": info["used"], "banned": info["banned"],
                "expired": now > info["expiry"], "hwid": info["hwid"],
                "username": info["username"], "expiry": info["expiry"],
                "days_left": max(0, int((info["expiry"] - now) / 86400)),
                "last_reset": info.get("last_hwid_reset") or 0
            })

@app.route('/hwid_reset')
def hwid_reset():
    token = request.args.get('token', '').strip()
    if token == ADMIN_KEY: return jsonify({"ok": True, "reset": True})
    if not token: return jsonify({"ok": False, "reason": "invalid"})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM keys WHERE key=%s", (token,))
            info = cur.fetchone()
            if not info: return jsonify({"ok": False, "reason": "invalid"})
            if info["banned"]: return jsonify({"ok": False, "reason": "banned"})
            if not info["hwid"]: return jsonify({"ok": False, "reason": "not_activated"})
            last_reset = info.get("last_hwid_reset") or 0
            cooldown_sec = HWID_RESET_COOLDOWN_DAYS * 86400
            now = int(time.time())
            if last_reset > 0 and (now - last_reset) < cooldown_sec:
                return jsonify({"ok": True, "reset": False, "days_left": int((cooldown_sec - (now - last_reset)) / 86400) + 1})
            cur.execute("UPDATE keys SET hwid=NULL, used=FALSE, last_hwid_reset=%s WHERE key=%s", (now, token))
        conn.commit()
    return jsonify({"ok": True, "reset": True})

@app.route('/download')
def download():
    version = request.args.get('ver', 'lite').strip().lower()
    if version not in ('full', 'lite', 'aggressive'): version = 'lite'
    try:
        with get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO downloads (version, ip, downloaded_at) VALUES (%s, %s, %s)", (version, get_client_ip(), int(time.time())))
            conn.commit()
        DOWNLOAD_COUNTER[version if version in DOWNLOAD_COUNTER else 'lite'] += 1
    except: pass
    return jsonify({"ok": True, "version": version})

@app.route('/status')
def status():
    now = int(time.time())
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM keys"); total_keys = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM keys WHERE used=TRUE AND banned=FALSE AND expiry > %s", (now,)); active_keys = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM activations"); total_activations = cur.fetchone()[0]
            cur.execute("SELECT COUNT(DISTINCT hwid) FROM check_log WHERE checked_at > %s", (now - 300,)); online_5min = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM downloads WHERE version='full'"); dl_full = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM downloads WHERE version='lite'"); dl_lite = cur.fetchone()[0]
    uptime = int(time.time() - START_TIME)
    days, hours, mins = uptime // 86400, (uptime % 86400) // 3600, (uptime % 3600) // 60
    return jsonify({
        "ok": True, "uptime_human": f"{days}д {hours}ч {mins}м",
        "total_keys": total_keys, "active_keys": active_keys, "activations_left": get_activations_left(),
        "total_activations": total_activations, "online_5min": online_5min,
        "downloads_full": dl_full, "downloads_lite": dl_lite
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
            "last_hwid_reset": info.get("last_hwid_reset") or 0,
            "version": info.get("version") or "unknown",
        })
    return jsonify({"ok": True, "activations_left": get_activations_left(), "total_keys": len(rows), "keys": result})

@app.route('/admin/generate_one')
def admin_generate_one():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    days = int(request.args.get('days', '7'))
    now = int(time.time())
    with get_db() as conn:
        with conn.cursor() as cur:
            key = generate_random_key()
            while True:
                cur.execute("SELECT 1 FROM keys WHERE key=%s", (key,))
                if cur.fetchone() is None: break
                key = generate_random_key()
            cur.execute("INSERT INTO keys (key, expiry, hwid, used, activated_at, ip, username, banned, last_hwid_reset, version) VALUES (%s, %s, NULL, FALSE, NULL, NULL, NULL, FALSE, 0, 'unknown')", (key, now + days * 86400))
        conn.commit()
    return jsonify({"ok": True, "key": key})

@app.route('/admin/regenerate')
def admin_regenerate():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    generate_keys_db()
    return jsonify({"ok": True, "message": "50 ключей сгенерированы заново"})

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

@app.route('/admin/ban_bulk')
def admin_ban_bulk():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    keys = request.args.get('keys', '').split(',')
    keys = [k.strip() for k in keys if k.strip()]
    if not keys: return jsonify({"ok": False, "reason": "empty"})
    with get_db() as conn:
        with conn.cursor() as cur:
            for k in keys: cur.execute("UPDATE keys SET banned=TRUE WHERE key=%s", (k,))
        conn.commit()
    return jsonify({"ok": True, "count": len(keys)})

@app.route('/admin/unban_bulk')
def admin_unban_bulk():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    keys = request.args.get('keys', '').split(',')
    keys = [k.strip() for k in keys if k.strip()]
    if not keys: return jsonify({"ok": False, "reason": "empty"})
    with get_db() as conn:
        with conn.cursor() as cur:
            for k in keys: cur.execute("UPDATE keys SET banned=FALSE WHERE key=%s", (k,))
        conn.commit()
    return jsonify({"ok": True, "count": len(keys)})

@app.route('/admin/extend_bulk')
def admin_extend_bulk():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    keys = request.args.get('keys', '').split(',')
    keys = [k.strip() for k in keys if k.strip()]
    days = int(request.args.get('days', '7'))
    if not keys: return jsonify({"ok": False, "reason": "empty"})
    add_sec = days * 86400
    now = int(time.time())
    with get_db() as conn:
        with conn.cursor() as cur:
            for k in keys: cur.execute("UPDATE keys SET expiry = GREATEST(expiry, %s) + %s WHERE key=%s", (now, add_sec, k))
        conn.commit()
    return jsonify({"ok": True, "count": len(keys), "days": days})

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

@app.route('/admin/find_key')
def admin_find_key():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    needle = request.args.get('q', '').strip().lower()
    if not needle: return jsonify({"ok": False, "reason": "empty"})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT * FROM keys WHERE LOWER(key) LIKE %s OR LOWER(COALESCE(username, '')) LIKE %s OR LOWER(COALESCE(hwid, '')) LIKE %s OR LOWER(COALESCE(ip, '')) LIKE %s
                ORDER BY used ASC, expiry DESC LIMIT 100
            """, (f"%{needle}%", f"%{needle}%", f"%{needle}%", f"%{needle}%"))
            rows = cur.fetchall()
    return jsonify({"ok": True, "results": rows})

@app.route('/admin/activations')
def admin_activations():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM activations ORDER BY activated_at DESC LIMIT 200")
            rows = cur.fetchall()
    return jsonify({"ok": True, "activations": rows})

@app.route('/admin/export')
def admin_export():
    ok, reason = check_admin_auth()
    if not ok: return jsonify({"ok": False, "reason": reason})
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT key, expiry, hwid, used, activated_at, ip, username, banned, version FROM keys ORDER BY key")
            rows = cur.fetchall()
    lines = ["key,expiry,days_left,hwid,used,activated_at,ip,username,banned,version"]
    now = int(time.time())
    for r in rows:
        days_left = max(0, int((r["expiry"] - now) / 86400))
        lines.append(",".join([str(r["key"]), str(r["expiry"]), str(days_left), str(r["hwid"] or ""), str(r["used"]), str(r["activated_at"] or ""), str(r["ip"] or ""), str(r["username"] or ""), str(r["banned"]), str(r["version"] or "")]))
    return "\n".join(lines), 200, {"Content-Type": "text/csv", "Content-Disposition": "attachment; filename=zeusx_keys.csv"}

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
            cur.execute("SELECT COUNT(*) FROM downloads WHERE version='full'"); dl_full = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM downloads WHERE version='lite'"); dl_lite = cur.fetchone()[0]
    return jsonify({
        "ok": True, "activations_left": get_activations_left(), "total_keys": total, "used_keys": used,
        "active_keys": active, "banned_keys": banned, "activations_today": act_today,
        "activations_week": act_week, "online_5min": online_5min, "downloads_full": dl_full, "downloads_lite": dl_lite
    })

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

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)