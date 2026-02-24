from loguru import logger
from airflow.providers.telegram.operators.telegram import TelegramOperator
import os

# Путь для логов loguru
LOG_FILE = os.environ.get("AIRFLOW_HOME", "/opt/airflow") + "/logs/vault_pipeline.log"
logger.add(LOG_FILE, rotation="500 MB", format="{time} {level} {message}")

def on_failure_callback(context):
    """
    Отправляет уведомление в Telegram и записывает ошибку в Loguru при сбое таска.
    """
    dag_id = context['dag'].dag_id
    task_id = context['task'].task_id
    error = context.get('exception')
    
    msg = f"❌ Task Failed!\nDAG: {dag_id}\nTask: {task_id}\nError: {error}"
    logger.error(msg)
    
    # Отправка в Telegram через Airflow Variable или Connections
    # Предполагается, что в Airflow настроен Connection 'telegram_default'
    try:
        tg_op = TelegramOperator(
            task_id='send_error_tg',
            telegram_conn_id='telegram_default',
            chat_id=os.environ.get("TELEGRAM_CHAT_ID"),
            text=msg
        )
        tg_op.execute(context)
    except Exception as e:
        logger.warning(f"Failed to send Telegram notification: {e}")

def on_success_callback(context):
    """
    Логирует успех и опционально шлет пуш в Telegram.
    """
    dag_id = context['dag'].dag_id
    msg = f"✅ DAG {dag_id} completed successfully."
    logger.info(msg)
    
    # Можно добавить пуш в ТГ при успехе всего дага
