-- =========================================
-- PARKING MONITORING DATABASE SCHEMA
-- =========================================

CREATE TABLE parking_facilities (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    total_slots INT DEFAULT 0,
    address VARCHAR(255),
    created_at DATETIME,
    updated_at DATETIME
);

CREATE TABLE parking_slots (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    slot_code VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'AVAILABLE',
    sensor_id VARCHAR(50) UNIQUE NOT NULL,
    facility_id BIGINT NOT NULL,
    last_updated DATETIME,
    created_at DATETIME,
    updated_at DATETIME,

    CONSTRAINT fk_slot_facility
        FOREIGN KEY (facility_id) REFERENCES parking_facilities(id)
);

CREATE TABLE sensor_readings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sensor_id VARCHAR(50) NOT NULL,
    slot_id BIGINT NOT NULL,
    distance DOUBLE NOT NULL,
    reading_timestamp DATETIME,
    created_at DATETIME,

    CONSTRAINT fk_reading_slot
        FOREIGN KEY (slot_id) REFERENCES parking_slots(id)
);