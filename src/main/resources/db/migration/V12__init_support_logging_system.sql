-- ===================================================================================
-- Migration   : V12
-- Title       : Init Support, Logging & System
-- Author      : JiilanTj
-- Date        : 2026-04-01
-- Description : Support tickets, audit/activity/login logs, event bus log,
--               webhook integrations, feature flags, settings, user preferences
-- ===================================================================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SUPPORT TICKETS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- -----------------------------------------------------------------------------------
-- TABLE: ticket_categories
-- -----------------------------------------------------------------------------------
CREATE TABLE ticket_categories (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL UNIQUE,
    description     TEXT,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE
);

-- -----------------------------------------------------------------------------------
-- TABLE: ticket_priorities
-- -----------------------------------------------------------------------------------
CREATE TABLE ticket_priorities (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(50)     NOT NULL UNIQUE,
    color           VARCHAR(20),
    position        INT             NOT NULL DEFAULT 0
);

-- -----------------------------------------------------------------------------------
-- TABLE: ticket_statuses
-- -----------------------------------------------------------------------------------
CREATE TABLE ticket_statuses (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(50)     NOT NULL UNIQUE,
    color           VARCHAR(20),
    position        INT             NOT NULL DEFAULT 0
);

-- -----------------------------------------------------------------------------------
-- TABLE: tickets
-- Description: User-submitted support requests
-- -----------------------------------------------------------------------------------
CREATE TABLE tickets (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    exam_id         UUID            REFERENCES exams (id) ON DELETE SET NULL,
    category_id     UUID            REFERENCES ticket_categories (id) ON DELETE SET NULL,
    priority_id     UUID            REFERENCES ticket_priorities (id) ON DELETE SET NULL,
    status_id       UUID            REFERENCES ticket_statuses (id) ON DELETE SET NULL,
    code            VARCHAR(50)     NOT NULL UNIQUE,
    subject         VARCHAR(255)    NOT NULL,
    message         TEXT            NOT NULL,
    assigned_to     UUID            REFERENCES users (id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMPTZ
);

CREATE INDEX idx_tickets_user_id      ON tickets (user_id);
CREATE INDEX idx_tickets_exam_id      ON tickets (exam_id);
CREATE INDEX idx_tickets_category_id  ON tickets (category_id);
CREATE INDEX idx_tickets_status_id    ON tickets (status_id);
CREATE INDEX idx_tickets_assigned_to  ON tickets (assigned_to);
CREATE INDEX idx_tickets_created_at   ON tickets (created_at);

-- -----------------------------------------------------------------------------------
-- TABLE: ticket_messages
-- Description: Discussion thread within a ticket
-- -----------------------------------------------------------------------------------
CREATE TABLE ticket_messages (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id       UUID            NOT NULL REFERENCES tickets (id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    content         TEXT            NOT NULL,
    attachment_url  TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ticket_messages_ticket_id ON ticket_messages (ticket_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LOGGING & AUDIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- -----------------------------------------------------------------------------------
-- TABLE: events
-- Description: Application domain event log (event sourcing / analytics feed)
-- -----------------------------------------------------------------------------------
CREATE TABLE events (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            REFERENCES users (id) ON DELETE SET NULL,
    event_type      VARCHAR(100)    NOT NULL,
    entity_type     VARCHAR(100),
    entity_id       UUID,
    metadata        JSONB,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_events_user_id     ON events (user_id);
CREATE INDEX idx_events_event_type  ON events (event_type);
CREATE INDEX idx_events_entity      ON events (entity_type, entity_id);
CREATE INDEX idx_events_created_at  ON events (created_at);

-- -----------------------------------------------------------------------------------
-- TABLE: activity_logs
-- Description: User-visible activity trail (e.g. "You took Exam X")
-- -----------------------------------------------------------------------------------
CREATE TABLE activity_logs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            REFERENCES users (id) ON DELETE SET NULL,
    action          VARCHAR(150)    NOT NULL,
    entity_type     VARCHAR(100),
    entity_id       UUID,
    metadata        JSONB,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_logs_user_id    ON activity_logs (user_id);
CREATE INDEX idx_activity_logs_entity     ON activity_logs (entity_type, entity_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs (created_at);

-- -----------------------------------------------------------------------------------
-- TABLE: audit_logs
-- Description: Immutable record of data mutations (old_data / new_data)
-- -----------------------------------------------------------------------------------
CREATE TABLE audit_logs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            REFERENCES users (id) ON DELETE SET NULL,
    action          VARCHAR(50)     NOT NULL
                        CHECK (action IN ('create', 'update', 'delete', 'restore')),
    entity_type     VARCHAR(100)    NOT NULL,
    entity_id       UUID            NOT NULL,
    old_data        JSONB,
    new_data        JSONB,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id    ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_entity     ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at);

-- -----------------------------------------------------------------------------------
-- TABLE: login_logs
-- Description: Records every login and logout event per user/device
-- -----------------------------------------------------------------------------------
CREATE TABLE login_logs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            REFERENCES users (id) ON DELETE SET NULL,
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    device          VARCHAR(255),
    login_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    logout_at       TIMESTAMPTZ
);

CREATE INDEX idx_login_logs_user_id   ON login_logs (user_id);
CREATE INDEX idx_login_logs_login_at  ON login_logs (login_at);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WEBHOOKS / INTEGRATIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- -----------------------------------------------------------------------------------
-- TABLE: webhooks
-- Description: Outbound webhook endpoints registered per tenant
-- -----------------------------------------------------------------------------------
CREATE TABLE webhooks (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    url             TEXT            NOT NULL,
    secret          VARCHAR(255),
    events          TEXT            NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhooks_tenant_id ON webhooks (tenant_id);

-- -----------------------------------------------------------------------------------
-- TABLE: webhook_logs
-- Description: Delivery attempt log for each webhook trigger
-- -----------------------------------------------------------------------------------
CREATE TABLE webhook_logs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id      UUID            NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
    event           VARCHAR(100)    NOT NULL,
    payload         TEXT,
    response_code   INT,
    response_body   TEXT,
    sent_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhook_logs_webhook_id ON webhook_logs (webhook_id);
CREATE INDEX idx_webhook_logs_sent_at    ON webhook_logs (sent_at);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SYSTEM CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- -----------------------------------------------------------------------------------
-- TABLE: feature_flags
-- Description: Runtime feature toggles (enable/disable features without deploy)
-- -----------------------------------------------------------------------------------
CREATE TABLE feature_flags (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(150)    NOT NULL UNIQUE,
    is_enabled      BOOLEAN         NOT NULL DEFAULT FALSE,
    description     TEXT
);

-- -----------------------------------------------------------------------------------
-- TABLE: settings
-- Description: Global key-value configuration store (categorized)
-- -----------------------------------------------------------------------------------
CREATE TABLE settings (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    category        VARCHAR(100)    NOT NULL,
    key             VARCHAR(150)    NOT NULL,
    value           TEXT,
    UNIQUE (category, key)
);

CREATE INDEX idx_settings_category ON settings (category);

-- -----------------------------------------------------------------------------------
-- TABLE: user_preferences
-- Description: Per-user key-value preference store
-- -----------------------------------------------------------------------------------
CREATE TABLE user_preferences (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    key             VARCHAR(150)    NOT NULL,
    value           TEXT,
    UNIQUE (user_id, key)
);

CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id);
