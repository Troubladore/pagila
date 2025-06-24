
CREATE TABLE IF NOT EXISTS stress_test_data (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    amount NUMERIC(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
