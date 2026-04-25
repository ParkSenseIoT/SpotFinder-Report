-- =========================================
-- ANALYTICS & REPORTING DATABASE SCHEMA
-- =========================================

CREATE TABLE reports (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    report_type VARCHAR(15),
    period_start DATE,
    period_end DATE,
    generated_at DATETIME,
    generated_by BIGINT,
    file_url VARCHAR(500),
    status VARCHAR(15) DEFAULT 'GENERATING',
    facility_id BIGINT,
    created_at DATETIME,
    updated_at DATETIME
);

CREATE TABLE slot_status_snapshots (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    slot_id BIGINT,
    status VARCHAR(20),
    snapshot_timestamp DATETIME,
    created_at DATETIME
);