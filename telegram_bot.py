import os
import time
import random
import string
import telebot
from telebot import types
import psycopg2
import psycopg2.extras

# --- НАСТРОЙКИ (в Render они подтянутся из Environment) ---
BOT_TOKEN = os.environ.get("BOT_TOKEN", "8965266590:AAGKQ_1vW5LTdgbdwGhnrnfYsMLpgy_FreE")
DATABASE_URL = os.environ.get('DATABASE_URL', '')
ADMIN_ID = int(os.environ.get("ADMIN_ID", "8882559913"))

bot = telebot.TeleBot(BOT_TOKEN)

def get_db():
    return psycopg2.connect(DATABASE_URL)

def generate_random_promo():
    def part(n): return ''.join(random.choices(string.ascii_uppercase + string.digits, k=n))
    return f"PROMO-{part(4)}-{part(4)}"

# --- ЛОГИКА ЗАХОДА ---
@bot.message_handler(commands=['start'])
def start(message):
    user_id = message.from_user.id
    username = message.from_user.username or "no_username"
    first_name = message.from_user.first_name or "User"
    
    now = int(time.time())
    promo_code = None
    is_new = False

    try:
        with get_db() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                # Проверяем, есть ли юзер в базе
                cur.execute("SELECT * FROM bot_users WHERE tg_id=%s", (user_id,))
                user = cur.fetchone()

                if not user:
                    # Юзер новый! Генерируем промокод
                    is_new = True
                    promo_code = generate_random_promo()
                    
                    # Добавляем промокод в базу (на 3 дня, 1 активация)
                    cur.execute("INSERT INTO promocodes (code, days, max_uses, uses) VALUES (%s, 3, 1, 0)", (promo_code,))
                    
                    # Записываем юзера в базу и сохраняем, какой промокод он получил
                    cur.execute("""
                        INSERT INTO bot_users (tg_id, username, first_name, promo_used, join_date, last_seen)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (user_id, username, first_name, promo_code, now, now))
                else:
                    # Юзер старый, просто обновляем время последнего визита
                    cur.execute("UPDATE bot_users SET last_seen=%s WHERE tg_id=%s", (now, user_id))
            conn.commit()
    except Exception as e:
        print(f"[DB ERROR] {e}")

    # Отправляем сообщение
    text = f"👋 Привет, <b>{first_name}</b>!\n\n"
    
    if is_new and promo_code:
        text += "🎁 Мы дарим тебе <b>пробный промокод на 3 дня</b>!\n\n"
        text += f"Твой код: <code>{promo_code}</code>\n\n"
        text += "Перейди на наш сайт, введи свой ключ и активируй этот промокод в личном кабинете, чтобы получить +3 дня."
    else:
        text += "Рады видеть тебя снова! Выбери действие в меню ниже:"

    # Кнопки
    markup = types.InlineKeyboardMarkup()
    btn_site = types.InlineKeyboardButton("🌐 Перейти на сайт", url="https://zeuspremium.hixo.dev/")
    markup.add(btn_site)
    
    bot.send_message(message.chat.id, text, reply_markup=markup, parse_mode="HTML")

if __name__ == '__main__':
    print("[Zeus-X Bot] Бот запущен...")
    bot.infinity_polling()