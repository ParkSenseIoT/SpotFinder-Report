-- =========================================
-- NOTIFICATION MANAGEMENT DATABASE SCHEMA
-- =========================================

CREATE TABLE notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    type VARCHAR(25),
    title VARCHAR(200),
    body VARCHAR(1000),
    data TEXT,
    status VARCHAR(15) DEFAULT 'PENDING',
    channel VARCHAR(10) DEFAULT 'PUSH',
    error_detail VARCHAR(500),
    created_at DATETIME,
    sent_at DATETIME,
    read_at DATETIME,
    updated_at DATETIME
);

CREATE TABLE notification_preferences (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    notification_type VARCHAR(25),
    enabled BOOLEAN DEFAULT TRUE,
    created_at DATETIME,
    updated_at DATETIME,
    UNIQUE (user_id, notification_type)
);

CREATE TABLE notification_templates (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    type VARCHAR(25),
    title_template VARCHAR(200),
    body_template VARCHAR(1000),
    language VARCHAR(5) DEFAULT 'es_PE',
    created_at DATETIME,
    updated_at DATETIME,
    UNIQUE (type, language)
);