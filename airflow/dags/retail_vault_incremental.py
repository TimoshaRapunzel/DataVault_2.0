import os
import requests
import json
from datetime import datetime
from airflow.decorators import dag
from airflow.models import Variable
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping

# =====================================================================
# 1. ЛОГИКА ТЕЛЕГРАМ-БОТА
# =====================================================================

def update_subscribers_and_get_list(bot_token):
    subscribers_str = Variable.get("telegram_subscribers", default_var="[]")
    try:
        subscribers = set(json.loads(subscribers_str))
    except json.JSONDecodeError:
        subscribers = set()

    url = f"https://api.telegram.org/bot{bot_token}/getUpdates"
    try:
        response = requests.get(url).json()
        if response.get("ok"):
            for update in response["result"]:
                if "message" in update and "chat" in update["message"]:
                    new_chat_id = str(update["message"]["chat"]["id"])
                    subscribers.add(new_chat_id)
            
            Variable.set("telegram_subscribers", json.dumps(list(subscribers)))
    except Exception as e:
        print(f"Ошибка при обновлении подписчиков: {e}")

    return list(subscribers)

def send_local_photo(bot_token, text, image_path):
    subscribers = update_subscribers_and_get_list(bot_token)
    if not subscribers:
        return

    url = f"https://api.telegram.org/bot{bot_token}/sendPhoto"
    for chat_id in subscribers:
        data = {'chat_id': chat_id, 'caption': text, 'parse_mode': 'HTML'}
        try:
            with open(image_path, 'rb') as photo_file:
                files = {'photo': photo_file}
                requests.post(url, data=data, files=files)
        except Exception as e:
            print(f"Ошибка отправки: {e}")

def on_failure_callback(context):
    bot_token = Variable.get("telegram_secret_token")
    task_instance = context.get('task_instance')
    task_id = task_instance.task_id if task_instance else "Неизвестная таска"
    dag_id = task_instance.dag_id if task_instance else "Неизвестный даг"
    end_time = datetime.now().strftime('%d.%m.%Y %H:%M:%S')

    base_dir = os.path.dirname(__file__)
    image_path = os.path.join(base_dir, 'images', 'failed.jpeg')

    message = (
        f"❌ <b>Поражение</b>\n\n"
        f"<b>Название дага:</b> <code>{dag_id}</code>\n"
        f"<b>Название таски:</b> <code>{task_id}</code>\n"
        f"<b>Время окончания:</b> {end_time}"
    )
    send_local_photo(bot_token, message, image_path)

def on_success_callback(context):
    bot_token = Variable.get("telegram_secret_token")
    dag = context.get('dag')
    dag_id = dag.dag_id if dag else "Неизвестный даг"
    end_time = datetime.now().strftime('%d.%m.%Y %H:%M:%S')

    base_dir = os.path.dirname(__file__)
    image_path = os.path.join(base_dir, 'images', 'success.jpeg')

    message = (
        f"✅ <b>Победа</b>\n\n"
        f"<b>Название дага:</b> <code>{dag_id}</code>\n"
        f"<b>Время окончания:</b> {end_time}"
    )
    send_local_photo(bot_token, message, image_path)


# =====================================================================
# 2. НАСТРОЙКИ DBT COSMOS
# =====================================================================

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", "/opt/dbt_core")

_profile_config = ProfileConfig(
    profile_name="retail_vault",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake_default",
        profile_args={
            "account": os.environ.get("SNOWFLAKE_ACCOUNT"),
            "database": os.environ.get("SNOWFLAKE_DATABASE", "RETAIL_VAULT"),
            "schema": "STAGING",
            "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
            "role": os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
        },
    ),
)

_project_config = ProjectConfig(dbt_project_path=DBT_PROJECT_DIR)
_execution_config = ExecutionConfig(dbt_executable_path="dbt")

# =====================================================================
# 3. ОПРЕДЕЛЕНИЕ DAG
# =====================================================================

default_args = {
    "on_failure_callback": on_failure_callback
}

@dag(
    default_args=default_args,
    dag_id="retail_vault_incremental",
    schedule_interval="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    on_success_callback=on_success_callback,
    tags=["retail_vault", "incremental"],
)
def retail_vault_incremental():
    
    tg = DbtTaskGroup(
        group_id="load_vault",
        project_config=_project_config,
        profile_config=_profile_config,
        execution_config=_execution_config,
        render_config=RenderConfig(
            select=["path:models/staging", "path:models/raw_vault", "path:models/business_vault", "path:models/marts", "path:models/presentation"],
        ),
        operator_args={"full_refresh": False}
    )

retail_vault_incremental()