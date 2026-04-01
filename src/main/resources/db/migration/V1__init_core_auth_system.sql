-- ===================================================================================
-- Migration   : V1
-- Title       : Init Core Auth System
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Users, RBAC (roles & permissions), sessions, password resets
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: users
-- Description: Core user account — auth identity, no tenant context here
-- -----------------------------------------------------------------------------------
CREATE TABLE users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    phone           VARCHAR(50),
    picture         TEXT,
    locale          VARCHAR(10)     NOT NULL DEFAULT 'id',
    timezone        VARCHAR(100)    NOT NULL DEFAULT 'Asia/Jakarta',
    status          VARCHAR(50)     NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_users_email       ON users (email);
CREATE INDEX idx_users_status      ON users (status);
CREATE INDEX idx_users_deleted_at  ON users (deleted_at);

-- -----------------------------------------------------------------------------------
-- TABLE: roles
-- Description: Application roles (e.g. admin, student, proctor)
-- -----------------------------------------------------------------------------------
CREATE TABLE roles (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL UNIQUE,
    description     TEXT
);

-- -----------------------------------------------------------------------------------
-- TABLE: permissions
-- Description: Granular permission flags (e.g. exam:create, result:view)
-- -----------------------------------------------------------------------------------
CREATE TABLE permissions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(150)    NOT NULL UNIQUE,
    description     TEXT
);

-- -----------------------------------------------------------------------------------
-- TABLE: user_roles
-- Description: M:N mapping — users can have multiple roles
-- -----------------------------------------------------------------------------------
CREATE TABLE user_roles (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id         UUID            NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    UNIQUE (user_id, role_id)
);

CREATE INDEX idx_user_roles_user_id ON user_roles (user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles (role_id);

-- -----------------------------------------------------------------------------------
-- TABLE: role_permissions
-- Description: M:N mapping — roles carry specific permissions
-- -----------------------------------------------------------------------------------
CREATE TABLE role_permissions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id         UUID            NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    permission_id   UUID            NOT NULL REFERENCES permissions (id) ON DELETE CASCADE,
    UNIQUE (role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role_id       ON role_permissions (role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions (permission_id);

-- -----------------------------------------------------------------------------------
-- TABLE: user_sessions
-- Description: Active login sessions per user (for multi-device management)
-- -----------------------------------------------------------------------------------
CREATE TABLE user_sessions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    device          VARCHAR(255),
    last_active     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expired_at      TIMESTAMPTZ     NOT NULL
);

CREATE INDEX idx_user_sessions_user_id     ON user_sessions (user_id);
CREATE INDEX idx_user_sessions_expired_at  ON user_sessions (expired_at);

-- -----------------------------------------------------------------------------------
-- TABLE: password_resets
-- Description: One-time password reset tokens
-- -----------------------------------------------------------------------------------
CREATE TABLE password_resets (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token           VARCHAR(255)    NOT NULL UNIQUE,
    expired_at      TIMESTAMPTZ     NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_resets_user_id    ON password_resets (user_id);
CREATE INDEX idx_password_resets_token      ON password_resets (token);
CREATE INDEX idx_password_resets_expired_at ON password_resets (expired_at);
