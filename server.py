import json
import time
import os
from flask import Flask, request, jsonify

app = Flask(__name__)

KEYS_FILE = 'keys.json'
MAX_ACTIVATIONS = 50

# ============================================================
# СТРУКТУРА keys.json:
# {
#   "admin_key": "zeushack",
#   "activations_left": 50,
#   "keys": {
#     "VANTA-XXXX-YYYY": {
#       "expiry": 1795000000,
#       "hwid": null,
#       "used": false,
#       "activated_at": null,
#       "ip": null,
#       "username": null,
#       "banned": false
#     },
#     ...
#   }
# }
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

def get_client_ip():
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr or "unknown"

# ============================================================
# /check — проверка ключа
# ============================================================
@app.route('/check')
def check():
    token = request.args.get('token', '').strip()
    hwid = request.args.get('hwid', '').strip()
    username = request.args.get('username', '').strip()
    ip = get_client_ip()

    db = load_db()

    # 1. Админ-ключ — бессрочно, без HWID, без счётчика
    if token == db.get("admin_key", "zeushack"):
        return jsonify({"ok": True, "left": 9999999999, "admin": True})

    # 2. Обычный ключ
    keys = db.get("keys", {})
    if token not in keys:
        return jsonify({"ok": False, "reason": "invalid"})

    info = keys[token]

    # забанен админом?
    if info.get("banned"):
        return jsonify({"ok": False, "reason": "banned"})

    # уже использован на другом HWID?
    if info.get("hwid") and info["hwid"] != hwid:
        return jsonify({"ok": False, "reason": "hwid_mismatch"})

    # истёк?
    if time.time() > info.get("expiry", 0):
        return jsonify({"ok": False, "reason": "expired"})

    # первый ввод ключа → активация
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
# /admin/keys — список ключей (только с паролем)
# ============================================================
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "admin_change_me")

@app.route('/admin/keys')
def admin_keys():
    pwd = request.args.get('pwd', '')
    if pwd != ADMIN_PASSWORD:
        return jsonify({"ok": False, "reason": "wrong_password"})

    db = load_db()
    keys = db.get("keys", {})
    now = time.time()

    result = []
    for key, info in keys.items():
        expired = now > info.get("expiry", 0)
        used = info.get("used", False)
        banned = info.get("banned", False)

        if banned:
            status = "red"  # забанен
        elif expired:
            status = "red"  # истёк
        elif used:
            status = "green"  # активен
        else:
            status = "grey"  # не активирован

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
# /admin/ban — забанить ключ
# ============================================================
@app.route('/admin/ban')
def admin_ban():
    pwd = request.args.get('pwd', '')
    key = request.args.get('key', '')
    if pwd != ADMIN_PASSWORD:
        return jsonify({"ok": False, "reason": "wrong_password"})

    db = load_db()
    if key in db.get("keys", {}):
        db["keys"][key]["banned"] = True
        save_db(db)
        return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": "key_not_found"})

# ============================================================
# /admin/unban — разбанить
# ============================================================
@app.route('/admin/unban')
def admin_unban():
    pwd = request.args.get('pwd', '')
    key = request.args.get('key', '')
    if pwd != ADMIN_PASSWORD:
        return jsonify({"ok": False, "reason": "wrong_password"})

    db = load_db()
    if key in db.get("keys", {}):
        db["keys"][key]["banned"] = False
        save_db(db)
        return jsonify({"ok": True})
    return jsonify({"ok": False, "reason": "key_not_found"})

# ============================================================
# /admin/stats — общая инфа
# ============================================================
@app.route('/admin/stats')
def admin_stats():
    pwd = request.args.get('pwd', '')
    if pwd != ADMIN_PASSWORD:
        return jsonify({"ok": False, "reason": "wrong_password"})

    db = load_db()
    keys = db.get("keys", {})
    used = sum(1 for k in keys.values() if k.get("used"))
    active = sum(1 for k in keys.values() if k.get("used") and not k.get("banned") and time.time() < k.get("expiry", 0))

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