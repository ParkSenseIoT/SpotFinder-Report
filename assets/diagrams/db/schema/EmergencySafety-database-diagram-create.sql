-- =========================================
-- EMERGENCY & SAFETY DATABASE SCHEMA
-- =========================================

CREATE TABLE emergency_alerts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sensor_id VARCHAR(50),
    gas_level INT,
    type VARCHAR(10),
    status VARCHAR(10) DEFAULT 'ACTIVE',
    triggered_at DATETIME,
    resolved_at DATETIME,
    resolved_by BIGINT,
    sensor_location VARCHAR(100),
    created_at DATETIME,
    updated_at DATETIME
);