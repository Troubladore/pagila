
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2025, 6, 24),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG('pagila_stress_test',
         default_args=default_args,
         schedule_interval='@hourly',
         catchup=False) as dag:

    generate_data = BashOperator(
        task_id='generate_stress_data',
        bash_command='spark-submit /path/to/stress_data_generator.py --num_rows 1000000 --batch_size 10000 --concurrency 4'
    )
