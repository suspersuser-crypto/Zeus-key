import os
import time
import random
import string
import telebot
from telebot import types
import psycopg2
import psycopg2.extras

# --- НАСТРОЙКИ ---
BOT_TOKEN = os.environ.get("BOT_TOKEN", "8965266590:AAGKQ_1vW5LTdgbdwGhnrnfYsMLpgy_FreE")
DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://zeus:cyr9wdEdeCFjKAjlJ8dlgVrj3bOnaIag@dpg-db33plu0tbcc738k5stg-a/zeus_x')
ADMIN_ID = int(os.environ.get("ADMIN_ID", "8882559913")) # Твой Telegram ID (для админ-команд)

bot = telebot.TeleBot(BOT_TOKEN)

def get_db():
    return psycopg2.connect(DATABASE_URL)

def generate_random_key():
    def part(n): return ''.join(random.choices(string.ascii_uppercase + string.digits, k=n))
    return f"VANTA-{part(4)}-{part(4)}-{part(4)}"

# --- КОМАНДЫ ---
@bot.message_handler(commands=['start'])
def start(message):
    markup = types.InlineKeyboardMarkup()
    btn_buy = types.InlineKeyboardButton("💳 Купить ключ", callback_data="buy")
    btn_info = types.InlineKeyboardButton("ℹ️ Информация", callback_data="info")
    markup.add(btn_buy, btn_info)
    
    text = (
        f"👋 Привет, {message.from_user.first_name}!\n\n"
        "Это официальный бот проекта **Zeus-X**.\n"
        "Здесь ты можешь приобрести ключ доступа к премиум-софту.\n\n"
        "Выбери действие ниже:"
    )
    bot.send_message(message.chat.id, text, reply_markup=markup, parse_mode="Markdown")

@bot.callback_query_handler(func=lambda call: True)
def callback_inline(call):
    if call.data == "info":
        bot.answer_callback_query(call.id)
        text = (
            "🛡 **Zeus-X Premium**\n\n"
            "• Aimbot / Silent Aim\n"
            "• ESP / Wallhack\n"
            "• Triggerbot\n"
            "• Обходы античитов\n\n"
            "Ключи выдаются автоматически после оплаты."
        )
        bot.send_message(call.message.chat.id, text, parse_mode="Markdown")
        
    elif call.data == "buy":
        bot.answer_callback_query(call.id)
        markup = types.InlineKeyboardMarkup()
        btn_1d = types.InlineKeyboardButton("1 день — 50₽", callback_data="pay_1")
        btn_7d = types.InlineKeyboardButton("7 дней — 250₽", callback_data="pay_7")
        btn_30d = types.InlineKeyboardButton("30 дней — 700₽", callback_data="pay_30")
        btn_back = types.InlineKeyboardButton("⬅️ Назад", callback_data="back_start")
        markup.add(btn_1d, btn_7d, btn_30d, btn_back)
        bot.edit_message_text("Выбери тариф:", call.message.chat.id, call.message.message_id, reply_markup=markup)

    elif call.data.startswith("pay_"):
        bot.answer_callback_query(call.id, "Оплата в разработке (нужно подключить ЮKassa/CryptoBot)")
        # ЗДЕСЬ БУДЕТ ЛОГИКА ОПЛАТЫ
        
    elif call.data == "back_start":
        bot.answer_callback_query(call.id)
        start(call.message)

# --- АДМИН-КОМАНДА ДЛЯ ВЫДАЧИ ---
@bot.message_handler(commands=['gen'])
def gen_key(message):
    if message.from_user.id != ADMIN_ID:
        bot.reply_to(message, "⛔ У тебя нет прав.")
        return
    
    try:
        days = int(message.text.split()[1])
    except:
        bot.reply_to(message, "Использование: /gen <дней>")
        return

    now = int(time.time())
    key = generate_random_key()
    try:
        with get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO keys (key, expiry, hwid, used, activated_at, ip, username, banned, last_hwid_reset, version) VALUES (%s, %s, NULL, FALSE, NULL, NULL, NULL, FALSE, 0, 'unknown')", (key, now + days * 86400))
            conn.commit()
        bot.reply_to(message, f"✅ Ключ на {days} дн. создан:\n`{key}`", parse_mode="Markdown")
    except Exception as e:
        bot.reply_to(message, f"❌ Ошибка БД: {e}")

if __name__ == '__main__':
    print("[Zeus-X Bot] Бот запущен...")
    bot.infinity_polling()