import json, time, os
from flask import Flask, request, jsonify

app = Flask(__name__)
KEYS_FILE = 'keys.json'

def load_keys():
    if not os.path.exists(KEYS_FILE):
        return {}
    with open(KEYS_FILE, 'r') as f:
        return json.load(f)

def save_keys(keys):
    with open(KEYS_FILE, 'w') as f:
        json.dump(keys, f, indent=2)

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