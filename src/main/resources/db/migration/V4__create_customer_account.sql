CREATE TABLE customer_account (
                                  account_id BIGSERIAL PRIMARY KEY,
                                  customer_id BIGINT NOT NULL,
                                  account_number VARCHAR(20) NOT NULL UNIQUE,
                                  account_type VARCHAR(20) NOT NULL,
                                  balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
                                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                  CONSTRAINT fk_customer_account_customer
                                      FOREIGN KEY (customer_id)
                                          REFERENCES customer(customer_id)
);