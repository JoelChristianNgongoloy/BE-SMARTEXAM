-- ===================================================================================
-- Migration   : V9
-- Title       : Init Communication
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Announcements, push/email notifications, notification preferences,
--               and direct messaging between users
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: announcements
-- Description: Broadcast messages from admins/staff to users within a tenant
-- -----------------------------------------------------------------------------------
CREATE TABLE announcements (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    title           VARCHAR(255)    NOT NULL,
    message         TEXT            NOT NULL,
    created_by      UUID            NOT NULL REFERENCES users (id),
    email_sent      BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_announcements_tenant_id   ON announcements (tenant_id);
CREATE INDEX idx_announcements_created_by  ON announcements (created_by);
CREATE INDEX idx_announcements_created_at  ON announcements (created_at);

-- -----------------------------------------------------------------------------------
-- TABLE: announcement_attachments
-- Description: Files attached to an announcement
-- -----------------------------------------------------------------------------------
CREATE TABLE announcement_attachments (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id     UUID            NOT NULL REFERENCES announcements (id) ON DELETE CASCADE,
    file_name           VARCHAR(255)    NOT NULL,
    file_path           TEXT            NOT NULL,
    file_type           VARCHAR(100),
    file_size           INT
);

CREATE INDEX idx_announcement_attachments_ann_id ON announcement_attachments (announcement_id);

-- -----------------------------------------------------------------------------------
-- TABLE: notifications
-- Description: In-app notifications per user
-- -----------------------------------------------------------------------------------
CREATE TABLE notifications (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type            VARCHAR(100)    NOT NULL,
    title           VARCHAR(255)    NOT NULL,
    message         TEXT            NOT NULL,
    is_read         BOOLEAN         NOT NULL DEFAULT FALSE,
    link            TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id    ON notifications (user_id);
CREATE INDEX idx_notifications_is_read    ON notifications (is_read);
CREATE INDEX idx_notifications_created_at ON notifications (created_at);

-- -----------------------------------------------------------------------------------
-- TABLE: notification_channels
-- Description: Per-user preference for each notification delivery channel
-- -----------------------------------------------------------------------------------
CREATE TABLE notification_channels (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    channel         VARCHAR(50)     NOT NULL
                        CHECK (channel IN ('email', 'push', 'sms', 'in_app')),
    is_enabled      BOOLEAN         NOT NULL DEFAULT TRUE,
    preferences     JSONB,
    UNIQUE (user_id, channel)
);

CREATE INDEX idx_notification_channels_user_id ON notification_channels (user_id);

-- -----------------------------------------------------------------------------------
-- TABLE: messages
-- Description: Direct messages between two users
-- -----------------------------------------------------------------------------------
CREATE TABLE messages (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id       UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    receiver_id     UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    subject         VARCHAR(255),
    content         TEXT            NOT NULL,
    is_read         BOOLEAN         NOT NULL DEFAULT FALSE,
    sent_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_sender_id   ON messages (sender_id);
CREATE INDEX idx_messages_receiver_id ON messages (receiver_id);
CREATE INDEX idx_messages_sent_at     ON messages (sent_at);

-- -----------------------------------------------------------------------------------
-- TABLE: message_attachments
-- Description: Files attached to a direct message
-- -----------------------------------------------------------------------------------
CREATE TABLE message_attachments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      UUID            NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    file_name       VARCHAR(255)    NOT NULL,
    file_path       TEXT            NOT NULL,
    file_type       VARCHAR(100),
    file_size       INT
);

CREATE INDEX idx_message_attachments_message_id ON message_attachments (message_id);
