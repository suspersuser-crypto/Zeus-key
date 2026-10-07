import json
import time
import os
import random
import string
import psycopg2
import psycopg2.extras
from flask import Flask, request, jsonify

app = Flask(__name__)

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
                    key TEXT PRIMARY KEY,
                    expiry BIGINT NOT NULL,
                    hwid TEXT,
                    used BOOLEAN DEFAULT FALSE,
                    activated_at BIGINT,
                    ip TEXT,
                    username TEXT,
                    banned BOOLEAN DEFAULT FALSE
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS settings (
                    name TEXT PRIMARY KEY,
                    value TEXT
                )
            """)
            cur.execute("SELECT value FROM settings WHERE name='activations_left'")
            row = cur.fetchone()
            if row is None:
                cur.execute("INSERT INTO settings (name, value) VALUES ('activations_left', %s)",
                            (str(MAX_ACTIVATIONS),))
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
    def part(n):
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=n))
    return f"VANTA-{part(4)}-{part(4)}-{part(4)}"

def generate_keys_db(count=50, min_days=1, max_days=20):
    now = int(time.time())
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM keys")
            for _ in range(count):
                key = generate_random_key()
                while True:
                    cur.execute("SELECT 1 FROM keys WHERE key=%s", (key,))
                    if cur.fetchone() is None:
                        break
                    key = generate_random_key()
                days = random.randint(min_days, max_days)
                cur.execute("""
                    INSERT INTO keys (key, expiry, hwid, used, activated_at, ip, username, banned)
                    VALUES (%s, %s, NULL, FALSE, NULL, NULL, NULL, FALSE)
                """, (key, now + days * 86400))
            cur.execute("UPDATE settings SET value=%s WHERE name='activations_left'", (str(count),))
        conn.commit()

def get_client_ip():
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr or "unknown"

def is_blocked(ip):
    if ip not in failed_attempts:
        return False
    info = failed_attempts[ip]
    if info.get("blocked_until", 0) > time.time():
        return True
    if info.get("blocked_until", 0) > 0:
        failed_attempts[ip] = {"count": 0, "blocked_until": 0}
    return False

def register_fail(ip):
    if ip not in failed_attempts:
        failed_attempts[ip] = {"count": 0, "blocked_until": 0}
    failed_attempts[ip]["count"] += 1
    if failed_attempts[ip]["count"] >= MAX_FAILED:
        failed_attempts[ip]["blocked_until"] = time.time() + BLOCK_TIME

def check_admin_auth():
    ip = get_client_ip()
    if is_blocked(ip):
        return False, "too_many_attempts"
    login = request.args.get('login', '')
    pwd = request.args.get('pwd', '')
    if not ADMIN_PASSWORD:
        return False, "admin_password_not_set"
    if login != ADMIN_LOGIN or pwd != ADMIN_PASSWORD:
        register_fail(ip)
        return False, "wrong_credentials"
    if ip in failed_attempts:
        failed_attempts[ip] = {"count": 0, "blocked_until": 0}
    return True, "ok"

@app.route('/check')
def check():
    token = request.args.get('token', '').strip()
    hwid = request.args.get('hwid', '').strip()
    username = request.args.get('username', '').strip()
    ip = get_client_ip()

    if token == ADMIN_KEY:
        return jsonify({"ok": True, "left": 9999999999, "admin": True})

    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM keys WHERE key=%s", (token,))
            info = cur.fetchone()
            if not info:
                return jsonify({"ok": False, "reason": "invalid"})
            if info["banned"]:
                return jsonify({"ok": False, "reason": "banned"})
            if info["hwid"] and info["hwid"] != hwid:
                return jsonify({"ok": False, "reason": "hwid_mismatch"})
            if time.time() > info["expiry"]:
                return jsonify({"ok": False, "reason": "expired"})

            if not info["used"]:
                left = get_activations_left()
                if left <= 0:
                    return jsonify({"ok": False, "reason": "no_activations"})
                cur.execute("""
                    UPDATE keys
                    SET used=TRUE, hwid=%s, activated_at=%s, ip=%s, username=%s
                    WHERE key=%s
                """, (hwid, int(time.time()), ip, username, token))
                set_activations_left(left - 1)

    return jsonify({
        "ok": True,
        "left": int(info["expiry"] - time.time()),
        "activations_left": get_activations_left()
    })

@app.route('/admin/login')
def admin_login():
    ok, reason = check_admin_auth()
    if ok:
        return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": reason})

@app.route('/admin/keys')
def admin_keys():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})

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
        if banned:
            status = "red"
        elif expired:
            status = "red"
        elif used:
            status = "green"
        else:
            status = "grey"
        result.append({
            "key": info["key"],
            "status": status,
            "used": used,
            "banned": banned,
            "expired": expired,
            "hwid": info["hwid"],
            "activated_at": info["activated_at"],
            "ip": info["ip"],
            "username": info["username"],
            "expiry": info["expiry"],
            "days_left": max(0, int((info["expiry"] - now) / 86400)),
        })

    return jsonify({
        "ok": True,
        "activations_left": get_activations_left(),
        "total_keys": len(rows),
        "keys": result
    })

@app.route('/admin/regenerate')
def admin_regenerate():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})
    generate_keys_db()
    return jsonify({
        "ok": True,
        "message": "50 ключей сгенерированы заново",
        "activations_left": get_activations_left(),
        "total_keys": 50
    })

@app.route('/admin/ban')
def admin_ban():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})
    key = request.args.get('key', '')
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE keys SET banned=TRUE WHERE key=%s", (key,))
        conn.commit()
    return jsonify({"ok": True})

@app.route('/admin/unban')
def admin_unban():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})
    key = request.args.get('key', '')
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE keys SET banned=FALSE WHERE key=%s", (key,))
        conn.commit()
    return jsonify({"ok": True})

@app.route('/admin/stats')
def admin_stats():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM keys")
            total = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM keys WHERE used=TRUE")
            used = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM keys WHERE used=TRUE AND banned=FALSE AND expiry > %s", (time.time(),))
            active = cur.fetchone()[0]
    return jsonify({
        "ok": True,
        "activations_left": get_activations_left(),
        "total_keys": total,
        "used_keys": used,
        "active_keys": active,
    })

@app.route('/')
def index():
    return "Zeus-X keygate is running (postgres)"

if __name__ == '__main__':
    init_db()
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)

# при первом запуске создаём таблицы
with app.app_context():
    try:
        init_db()
    except Exception as e:
        print("[init_db error]", e)