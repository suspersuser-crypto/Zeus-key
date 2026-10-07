import json
import random
import string
import time

def gen_key():
    """Генерирует ключ вида VANTA-XXXX-XXXX-XXXX"""
    def part(n):
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=n))
    return f"VANTA-{part(4)}-{part(4)}-{part(4)}"

def gen_keys(count=50, min_days=1, max_days=20, admin_key="zeushack"):
    db = {
        "admin_key": admin_key,
        "activations_left": count,
        "keys": {}
    }

    now = int(time.time())
    for i in range(count):
        key = gen_key()
        while key in db["keys"]:  # избегаем дублей
            key = gen_key()

        days = random.randint(min_days, max_days)
        expiry = now + days * 86400

        db["keys"][key] = {
            "expiry": expiry,
            "hwid": None,
            "used": False,
            "activated_at": None,
            "ip": None,
            "username": None,
            "banned": False,
            "days": days  # для удобства, сколько было изначально
        }

    return db

if __name__ == "__main__":
    db = gen_keys(count=50, min_days=1, max_days=20, admin_key="zeushack")

    with open("keys.json", "w") as f:
        json.dump(db, f, indent=2)

    print("=" * 60)
    print("Zeus-X · сгенерировано 50 ключей")
    print("=" * 60)
    print(f"Админ-ключ: {db['admin_key']} (бессрочно, любое устройство)")
    print(f"Активаций всего: {db['activations_left']}")
    print("-" * 60)
    print("Ключи:")
    for k, info in db["keys"].items():
        print(f"  {k}  →  {info['days']} дн.  (до {time.strftime('%Y-%m-%d', time.localtime(info['expiry']))})")
    print("=" * 60)
    print("Файл keys.json создан в текущей папке.")