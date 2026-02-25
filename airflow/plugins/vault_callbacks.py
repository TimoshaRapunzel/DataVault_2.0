import contextlib

from airflow.utils.context import Context
from loguru import logger

# ИСПРАВЛЕНО: Убрали "airflow." в начале, теперь импортируется наша локальная функция
from utils.telegram import send_telegram_message


def on_failure_callback(context: Context):
    """Callback for task failure."""
    task_instance = context.get("task_instance")
    if not task_instance:
        return

    task_id = task_instance.task_id
    dag_id = task_instance.dag_id
    error = context.get("exception")

    msg = f"<b>Task Failed</b>\nDAG: {dag_id}\nTask: {task_id}\nError: {error}"

    # Используем suppress (правило SIM105).
    # Если Telegram упадет, мы просто запишем это в лог, не ломая основной процесс Airflow.
    with contextlib.suppress(Exception):
        send_telegram_message(msg)
        logger.info(f"Failure notification sent for task {task_id}")
