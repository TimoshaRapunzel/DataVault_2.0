import requests
from airflow.models import Variable
from loguru import logger

# Строго импортируем константы
from utils.constants import TG_CHAT_ID_VAR, TG_SECRETS_VAR


def send_telegram_message(text: str):
    """Send telegram notification via Bot API."""
    # Получаем значения по именам констант (без хардкода)
    token = Variable.get(TG_SECRETS_VAR, default_var=None)
    chat_id = Variable.get(TG_CHAT_ID_VAR, default_var=None)

    if not token or not chat_id:
        logger.warning("Telegram credentials not found in Airflow Variables")
        return

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {"chat_id": chat_id, "text": text, "parse_mode": "HTML"}

    try:
        # Added timeout=10 to prevent blocking (Fixes S113)
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        # Catch specific request exceptions (Fixes BLE001)
        logger.error(f"Telegram API error: {e}")
