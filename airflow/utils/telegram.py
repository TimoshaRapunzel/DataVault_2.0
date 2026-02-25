import requests
from airflow.models import Variable
from loguru import logger


def send_telegram_message(text: str):
    """Send telegram notification via Bot API."""
    token = Variable.get("telegram_token", default_var=None)
    chat_id = Variable.get("telegram_chat_id", default_var=None)

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
