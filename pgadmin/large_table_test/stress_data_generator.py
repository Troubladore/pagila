
from pyspark.sql import SparkSession
import psycopg2
import random
import multiprocessing
import argparse

# Generate random data
def generate_random_data(num_rows):
    return [
        (
            random.randint(1, 1000),  # customer_id
            round(random.uniform(1.0, 100.0), 2)  # amount
        )
        for _ in range(num_rows)
    ]
 
# Insert data into PostgreSQL
def insert_data(data, conn_params):
    try:
        conn = psycopg2.connect(**conn_params)
        cur = conn.cursor()
        cur.executemany("""
            INSERT INTO stress_test_data (customer_id, amount)
            VALUES (%s, %s)
        """, data)
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error inserting data: {e}")

# Worker function for multiprocessing
def worker(batch_size, conn_params):
    data = generate_random_data(batch_size)
    insert_data(data, conn_params)

# Main function
def main(num_rows, batch_size, concurrency):
    conn_params = {
        'dbname': 'pagila',
        'user': 'your_username',
        'password': 'your_password',
        'host': 'localhost',
        'port': '5432'
    }

    # Initialize Spark session
    spark = SparkSession.builder \
        .appName("PagilaStressTestDataGenerator") \
        .getOrCreate()

    num_batches = num_rows // batch_size
    pool = multiprocessing.Pool(concurrency)

    for _ in range(num_batches):
        pool.apply_async(worker, args=(batch_size, conn_params))

    pool.close()
    pool.join()
    spark.stop()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate and insert random data into PostgreSQL.")
    parser.add_argument('--num_rows', type=int, default=5000000, help='Total number of rows to generate')
    parser.add_argument('--batch_size', type=int, default=10000, help='Number of rows per batch')
    parser.add_argument('--concurrency', type=int, default=4, help='Number of concurrent workers')

    args = parser.parse_args()
    main(args.num_rows, args.batch_size, args.concurrency)
