import logging
import os

import requests
from airflow.models import Variable

# E402 ИСПРАВЛЕНИЕ: Импорты подняты на самый верх
from utils.constants import TG_CHAT_ID_VAR, TG_SECRETS_VAR

logger = logging.getLogger("airflow.task")


def send_telegram_message(text: str):
    """Send a simple text message."""
    token = Variable.get(TG_SECRETS_VAR, default_var=None)
    chat_id = Variable.get(TG_CHAT_ID_VAR, default_var=None)

    if not token or not chat_id:
        logger.error("Telegram credentials (token/chat_id) are missing!")
        return

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    try:
        r = requests.post(
            url, json={"chat_id": chat_id, "text": text, "parse_mode": "HTML"}, timeout=10
        )
        r.raise_for_status()
    # BLE001 ИСПРАВЛЕНИЕ: Ловим конкретную ошибку сети
    except requests.exceptions.RequestException as e:
        logger.error(f"TG Text Error: {e}")


def send_local_photo(text: str, photo_path: str):
    # RUF002 ИСПРАВЛЕНИЕ: Английский докстринг без "опасных" кириллических букв
    """Send photo with caption. Fallback to text if photo is missing."""
    token = Variable.get(TG_SECRETS_VAR, default_var=None)
    chat_id = Variable.get(TG_CHAT_ID_VAR, default_var=None)

    if not token or not chat_id:
        return None

    if not os.path.exists(photo_path):
        logger.warning(f"Photo not found at {photo_path}. Sending text only.")
        return send_telegram_message(text)

    url = f"https://api.telegram.org/bot{token}/sendPhoto"
    try:
        with open(photo_path, "rb") as f:
            r = requests.post(
                url,
                data={"chat_id": chat_id, "caption": text, "parse_mode": "HTML"},
                files={"photo": f},
                timeout=10,
            )
            r.raise_for_status()
    # BLE001 ИСПРАВЛЕНИЕ: Ловим конкретную ошибку сети
    except requests.exceptions.RequestException as e:
        logger.error(f"TG Photo Error: {e}")
        send_telegram_message(text)
