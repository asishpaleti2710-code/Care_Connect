-- =============================================================================
-- CareConnect Enterprise Production PostgreSQL Database Schema
-- Dialect: PostgreSQL 14+ / 16+
-- =============================================================================

-- Enable UUID extension if required
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. USERS & RBAC TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'caregiver',
    phone VARCHAR(50),
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- -----------------------------------------------------------------------------
-- 2. RESIDENTS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS residents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    full_name VARCHAR(255) NOT NULL,
    age INTEGER,
    room_number VARCHAR(50),
    address TEXT,
    emergency_contact VARCHAR(100),
    medical_notes TEXT,
    blood_group VARCHAR(10),
    status VARCHAR(50) DEFAULT 'safe',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_residents_room ON residents(room_number);
CREATE INDEX IF NOT EXISTS idx_residents_status ON residents(status);

-- -----------------------------------------------------------------------------
-- 3. GUARDIANS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS guardians (
    id SERIAL PRIMARY KEY,
    resident_id INTEGER NOT NULL REFERENCES residents(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    notify_sms BOOLEAN DEFAULT TRUE,
    notify_email BOOLEAN DEFAULT TRUE,
    notify_push BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_guardians_resident_id ON guardians(resident_id);

-- -----------------------------------------------------------------------------
-- 4. SECURITY & RESPONDERS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS security_personnel (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    badge_number VARCHAR(100) UNIQUE,
    on_duty BOOLEAN DEFAULT TRUE,
    current_location VARCHAR(255),
    shift VARCHAR(50) DEFAULT 'DAY',
    phone VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS volunteers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    certified_first_aid BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    distance_km FLOAT DEFAULT 0.0,
    phone VARCHAR(50)
);

-- -----------------------------------------------------------------------------
-- 5. SOS EMERGENCY ALERTS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sos_alerts (
    id SERIAL PRIMARY KEY,
    resident_id INTEGER NOT NULL REFERENCES residents(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    alert_type VARCHAR(100) DEFAULT 'Medical Emergency',
    category VARCHAR(100) DEFAULT 'Medical Emergency',
    message TEXT,
    latitude FLOAT,
    longitude FLOAT,
    maps_url TEXT,
    priority VARCHAR(50) DEFAULT 'CRITICAL',
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    responding_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    responder_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    responder_name VARCHAR(255),
    responder_role VARCHAR(50),
    response_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_status ON sos_alerts(status);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_created_at ON sos_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_resident ON sos_alerts(resident_id);

-- -----------------------------------------------------------------------------
-- 6. SOS AUDIT LOGS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sos_audit_logs (
    id SERIAL PRIMARY KEY,
    sos_id INTEGER NOT NULL REFERENCES sos_alerts(id) ON DELETE CASCADE,
    previous_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    action_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action_by_name VARCHAR(255),
    action_by_role VARCHAR(50),
    notes TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sos_audit_sos_id ON sos_audit_logs(sos_id);

-- -----------------------------------------------------------------------------
-- 7. MULTI-CHANNEL NOTIFICATIONS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    sos_id INTEGER REFERENCES sos_alerts(id) ON DELETE SET NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    recipient_role VARCHAR(50),
    recipient_name VARCHAR(255),
    recipient_contact VARCHAR(255),
    channel VARCHAR(50) NOT NULL, -- IN_APP, EMAIL, SMS, PUSH
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'DELIVERED', -- SENT, DELIVERED, READ, FAILED
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sos_id ON notifications(sos_id);
CREATE INDEX IF NOT EXISTS idx_notifications_channel ON notifications(channel);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
