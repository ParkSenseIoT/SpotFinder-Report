-- =========================================
-- PAYMENT PROCESSING DATABASE SCHEMA
-- =========================================

CREATE TABLE payments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id BIGINT NOT NULL,
    amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'PEN',
    payment_method VARCHAR(15),
    status VARCHAR(15) DEFAULT 'PENDING',
    transaction_id VARCHAR(100) UNIQUE,
    receipt_url VARCHAR(500),
    paid_at DATETIME,
    fee_duration_seconds BIGINT DEFAULT 0,
    fee_rate_per_hour DECIMAL(10,2) DEFAULT 0.00,
    fee_hours_charged INT DEFAULT 0,
    error_detail VARCHAR(500),
    user_id BIGINT,
    created_at DATETIME,
    updated_at DATETIME
);