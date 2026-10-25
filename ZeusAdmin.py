import webview
import os

# Настройки
SERVER = "https://zeus-key-mjep.onrender.com"

def main():
    # Создаем окно без рамок Windows (frameless)
    window = webview.create_window(
        title="Zeus-X · Mega Admin",
        url="admin_ui.html", # Ссылка на HTML файл
        width=1300,
        height=850,
        frameless=True,      # Убирает верхнюю панель Windows
        easy_drag=True,      # Позволяет таскать окно за фон
        background_color="#05040a"
    )
    webview.start()

if __name__ == '__main__':
    main()