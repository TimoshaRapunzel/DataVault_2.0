# utils/callbacks.py
import os
from datetime import datetime

from utils.telegram import send_local_photo


def get_image_path(image_name: str) -> str:
    """Вспомогательная функция для получения пути до картинки"""
    # Поднимаемся на уровень выше из utils/ и заходим в dags/images/
    base_dir = os.path.dirname(os.path.dirname(__file__))
    return os.path.join(base_dir, "dags", "images", image_name)


def on_failure_callback(context):
    """Коллбек для упавшей таски"""
    task_instance = context.get("task_instance")
    task_id = task_instance.task_id if task_instance else "Неизвестная таска"
    dag_id = task_instance.dag_id if task_instance else "Неизвестный даг"
    end_time = datetime.now().strftime("%d.%m.%Y %H:%M:%S")

    image_path = get_image_path("failed.jpeg")

    message = (
        f"❌ <b>Поражение</b>\n\n"
        f"<b>Название дага:</b> <code>{dag_id}</code>\n"
        f"<b>Название таски:</b> <code>{task_id}</code>\n"
        f"<b>Время окончания:</b> {end_time}"
    )
    send_local_photo(message, image_path)


def on_success_callback(context):
    """Коллбек для успешного ДАГА"""
    dag = context.get("dag")
    dag_id = dag.dag_id if dag else "Неизвестный даг"
    end_time = datetime.now().strftime("%d.%m.%Y %H:%M:%S")

    image_path = get_image_path("success.jpeg")

    message = (
        f"✅ <b>Победа</b>\n\n"
        f"<b>Название дага:</b> <code>{dag_id}</code>\n"
        f"<b>Время окончания:</b> {end_time}"
    )
    send_local_photo(message, image_path)
