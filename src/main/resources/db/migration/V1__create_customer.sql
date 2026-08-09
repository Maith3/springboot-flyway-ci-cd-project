CREATE TABLE customer (
                          customer_id BIGSERIAL PRIMARY KEY,
                          first_name VARCHAR(100) NOT NULL,
                          last_name VARCHAR(100) NOT NULL,
                          email VARCHAR(255) UNIQUE NOT NULL,
                          phone VARCHAR(20),
                          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);