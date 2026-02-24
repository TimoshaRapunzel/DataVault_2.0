# utils/telegram.py
import requests
import json
from airflow.models import Variable
from utils.constants import TG_SECRETS_VAR, TG_SUBSCRIBERS_VAR, TG_API_URL_BASE

def update_subscribers_and_get_list() -> list:
    """Проверяет новые сообщения боту и обновляет базу подписчиков"""
    bot_token = Variable.get(TG_SECRETS_VAR)
    subscribers_str = Variable.get(TG_SUBSCRIBERS_VAR, default_var="[]")
    
    try:
        subscribers = set(json.loads(subscribers_str))
    except json.JSONDecodeError:
        subscribers = set()

    url = f"{TG_API_URL_BASE}{bot_token}/getUpdates"
    try:
        response = requests.get(url).json()
        if response.get("ok"):
            for update in response["result"]:
                if "message" in update and "chat" in update["message"]:
                    new_chat_id = str(update["message"]["chat"]["id"])
                    subscribers.add(new_chat_id)
            
            Variable.set(TG_SUBSCRIBERS_VAR, json.dumps(list(subscribers)))
    except Exception as e:
        print(f"Ошибка при обновлении подписчиков: {e}")

    return list(subscribers)

def send_local_photo(text: str, image_path: str):
    """Рассылает картинку с текстом всем подписчикам"""
    bot_token = Variable.get(TG_SECRETS_VAR)
    subscribers = update_subscribers_and_get_list()
    
    if not subscribers:
        return

    url = f"{TG_API_URL_BASE}{bot_token}/sendPhoto"
    
    for chat_id in subscribers:
        data = {'chat_id': chat_id, 'caption': text, 'parse_mode': 'HTML'}
        try:
            with open(image_path, 'rb') as photo_file:
                files = {'photo': photo_file}
                requests.post(url, data=data, files=files)
        except Exception as e:
            print(f"Ошибка отправки: {e}")