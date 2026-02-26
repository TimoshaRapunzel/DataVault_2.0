import logging
import os
from datetime import datetime

from utils.telegram import send_local_photo

logger = logging.getLogger("airflow.task")


def get_image_path(image_name: str) -> str:
    """Get the absolute path to an image file."""
    base_dir = os.path.dirname(os.path.dirname(__file__))
    return os.path.join(base_dir, "images", image_name)


def on_success_callback(context):
    try:
        print("!!! DEBUG: Запуск on_success_callback !!!")

        dag = context.get("dag")
        dag_id = dag.dag_id if dag else "Unknown DAG"
        end_time = datetime.now().strftime("%H:%M:%S")

        image_path = get_image_path("success.jpeg")
        message = f"✅ <b>Победа в DAG:</b> <code>{dag_id}</code>\n<b>Время:</b> {end_time}"

        send_local_photo(message, image_path)
        print(f"!!! DEBUG: Сообщение для {dag_id} успешно вызвано !!!")
    # BLE001 ИСПРАВЛЕНИЕ: Добавляем noqa, чтобы линтер игнорировал эту строчку
    except Exception as e:  # noqa: BLE001
        print(f"!!! CALLBACK SUCCESS ERROR: {e}")


def on_failure_callback(context):
    try:
        print("!!! DEBUG: Запуск on_failure_callback !!!")
        task_instance = context.get("task_instance")
        task_id = task_instance.task_id

        image_path = get_image_path("failed.jpeg")
        message = f"❌ <b>Поражение в таске:</b> <code>{task_id}</code>"

        send_local_photo(message, image_path)
    # BLE001 ИСПРАВЛЕНИЕ: Добавляем noqa
    except Exception as e:  # noqa: BLE001
        print(f"!!! CALLBACK FAILURE ERROR: {e}")
