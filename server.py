import json, time, os
from flask import Flask, request, jsonify

app = Flask(__name__)

def load_keys():
    raw = os.environ.get('KEYS_JSON', '{}')
    try:
        return json.loads(raw)
    except Exception:
        return {}

def save_keys(keys):
    # сохраняем локально в файл (на случай перезапуска в рамках сессии)
    # но главный источник — env переменная KEYS_JSON на Render
    try:
        with open('keys_runtime.json', 'w') as f:
            json.dump(keys, f, indent=2)
    except:
        pass

@app.route('/')
def index():
    return "Zeus-X keygate is running"

@app.route('/check')
def check():
    token = request.args.get('token', '')
    hwid = request.args.get('hwid', '')

    keys = load_keys()
    if token not in keys:
        return jsonify({"ok": False, "reason": "invalid"})

    info = keys[token]

    if not info.get("hwid"):
        info["hwid"] = hwid
        save_keys(keys)
    elif info["hwid"] != hwid:
        return jsonify({"ok": False, "reason": "hwid_mismatch"})

    if time.time() > info.get("expiry", 0):
        return jsonify({"ok": False, "reason": "expired"})

    return jsonify({"ok": True, "left": int(info["expiry"] - time.time())})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)