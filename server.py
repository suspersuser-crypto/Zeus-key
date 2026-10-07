import json
import time
import os
from flask import Flask, request, jsonify

app = Flask(__name__)
@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response

KEYS_FILE = '/etc/secrets/keys.json'
MAX_ACTIVATIONS = 50

# ============================================================
# ЛОГИН И ПАРОЛЬ АДМИНКИ — читаются из Environment
# В самом файле пароля НЕТ. Он лежит только на Render.
# ============================================================
ADMIN_LOGIN = os.environ.get("ADMIN_LOGIN", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "")

# ============================================================
# ЗАЩИТА ОТ ПОДБОРА ПАРОЛЯ
# ============================================================
failed_attempts = {}  # {ip: {"count": N, "blocked_until": timestamp}}
MAX_FAILED = 5
BLOCK_TIME = 3600  # 1 час

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
    # разблокировался — сбрасываем
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
    """Проверяет логин/пароль админа. Возвращает (ok, message)"""
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

    # успех — сбрасываем счётчик неудач
    if ip in failed_attempts:
        failed_attempts[ip] = {"count": 0, "blocked_until": 0}

    return True, "ok"

# ============================================================
# БАЗА ДАННЫХ
# ============================================================
def load_db():
    if not os.path.exists(KEYS_FILE):
        return {"admin_key": "zeushack", "activations_left": MAX_ACTIVATIONS, "keys": {}}
    try:
        with open(KEYS_FILE, 'r') as f:
            return json.load(f)
    except Exception:
        return {"admin_key": "zeushack", "activations_left": MAX_ACTIVATIONS, "keys": {}}

def save_db(db):
    try:
        with open(KEYS_FILE, 'w') as f:
            json.dump(db, f, indent=2)
    except Exception as e:
        print("[save_db error]", e)

# ============================================================
# /check — для чита
# ============================================================
@app.route('/check')
def check():
    token = request.args.get('token', '').strip()
    hwid = request.args.get('hwid', '').strip()
    username = request.args.get('username', '').strip()
    ip = get_client_ip()

    db = load_db()

    # админ-ключ
    if token == db.get("admin_key", "zeushack"):
        return jsonify({"ok": True, "left": 9999999999, "admin": True})

    keys = db.get("keys", {})
    if token not in keys:
        return jsonify({"ok": False, "reason": "invalid"})

    info = keys[token]

    if info.get("banned"):
        return jsonify({"ok": False, "reason": "banned"})

    if info.get("hwid") and info["hwid"] != hwid:
        return jsonify({"ok": False, "reason": "hwid_mismatch"})

    if time.time() > info.get("expiry", 0):
        return jsonify({"ok": False, "reason": "expired"})

    if not info.get("used"):
        if db.get("activations_left", 0) <= 0:
            return jsonify({"ok": False, "reason": "no_activations"})

        info["used"] = True
        info["hwid"] = hwid
        info["activated_at"] = int(time.time())
        info["ip"] = ip
        info["username"] = username
        db["activations_left"] = db.get("activations_left", MAX_ACTIVATIONS) - 1
        save_db(db)

    return jsonify({
        "ok": True,
        "left": int(info["expiry"] - time.time()),
        "activations_left": db.get("activations_left", 0)
    })

# ============================================================
# /admin/login — проверка логина/пароля
# ============================================================
@app.route('/admin/login')
def admin_login():
    ok, reason = check_admin_auth()
    if ok:
        return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": reason})

# ============================================================
# /admin/keys — список ключей
# ============================================================
@app.route('/admin/keys')
def admin_keys():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})

    db = load_db()
    keys = db.get("keys", {})
    now = time.time()

    result = []
    for key, info in keys.items():
        expired = now > info.get("expiry", 0)
        used = info.get("used", False)
        banned = info.get("banned", False)

        if banned:
            status = "red"
        elif expired:
            status = "red"
        elif used:
            status = "green"
        else:
            status = "grey"

        result.append({
            "key": key,
            "status": status,
            "used": used,
            "banned": banned,
            "expired": expired,
            "hwid": info.get("hwid"),
            "activated_at": info.get("activated_at"),
            "ip": info.get("ip"),
            "username": info.get("username"),
            "expiry": info.get("expiry"),
            "days_left": max(0, int((info.get("expiry", 0) - now) / 86400)),
        })

    return jsonify({
        "ok": True,
        "activations_left": db.get("activations_left", 0),
        "total_keys": len(keys),
        "keys": result
    })

# ============================================================
# /admin/ban
# ============================================================
@app.route('/admin/ban')
def admin_ban():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})

    key = request.args.get('key', '')
    db = load_db()
    if key in db.get("keys", {}):
        db["keys"][key]["banned"] = True
        save_db(db)
        return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": "key_not_found"})

# ============================================================
# /admin/unban
# ============================================================
@app.route('/admin/unban')
def admin_unban():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})

    key = request.args.get('key', '')
    db = load_db()
    if key in db.get("keys", {}):
        db["keys"][key]["banned"] = False
        save_db(db)
        return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": "key_not_found"})

# ============================================================
# /admin/stats
# ============================================================
@app.route('/admin/stats')
def admin_stats():
    ok, reason = check_admin_auth()
    if not ok:
        return jsonify({"ok": False, "reason": reason})

    db = load_db()
    keys = db.get("keys", {})
    used = sum(1 for k in keys.values() if k.get("used"))
    active = sum(1 for k in keys.values()
                 if k.get("used")
                 and not k.get("banned")
                 and time.time() < k.get("expiry", 0))

    return jsonify({
        "ok": True,
        "activations_left": db.get("activations_left", 0),
        "total_keys": len(keys),
        "used_keys": used,
        "active_keys": active,
    })

@app.route('/')
def index():
    return "Zeus-X keygate is running"

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)