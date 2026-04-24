-- =========================================
-- ACCESS CONTROL DATABASE SCHEMA
-- =========================================

CREATE TABLE vehicle_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    plate_text VARCHAR(10) NOT NULL,
    plate_confidence DOUBLE DEFAULT 0.0,
    entry_timestamp DATETIME,
    exit_timestamp DATETIME,
    slot_id BIGINT,
    payment_status VARCHAR(10) DEFAULT 'PENDING',
    session_status VARCHAR(15) DEFAULT 'ACTIVE',
    user_id BIGINT,
    created_at DATETIME,
    updated_at DATETIME
);

CREATE TABLE access_barriers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    barrier_code VARCHAR(20) UNIQUE NOT NULL,
    position VARCHAR(10),
    status VARCHAR(10) DEFAULT 'CLOSED',
    facility_id BIGINT,
    created_at DATETIME,
    updated_at DATETIME
);