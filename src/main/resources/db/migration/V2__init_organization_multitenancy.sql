-- ===================================================================================
-- Migration   : V2
-- Title       : Init Organization & Multitenancy
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Tenants (schools/institutions), tenant membership, organizations
--               (faculties/departments), and org membership
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: tenants
-- Description: Top-level tenant — represents an institution (e.g. Telkom University)
-- -----------------------------------------------------------------------------------
CREATE TABLE tenants (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255)    NOT NULL,
    domain          VARCHAR(255)    UNIQUE,
    logo            TEXT,
    status          VARCHAR(50)     NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_domain ON tenants (domain);
CREATE INDEX idx_tenants_status ON tenants (status);

-- -----------------------------------------------------------------------------------
-- TABLE: tenant_users
-- Description: Users who belong to a tenant with a tenant-scoped role
-- -----------------------------------------------------------------------------------
CREATE TABLE tenant_users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role            VARCHAR(100)    NOT NULL DEFAULT 'member',
    UNIQUE (tenant_id, user_id)
);

CREATE INDEX idx_tenant_users_tenant_id ON tenant_users (tenant_id);
CREATE INDEX idx_tenant_users_user_id   ON tenant_users (user_id);

-- -----------------------------------------------------------------------------------
-- TABLE: organizations
-- Description: Sub-unit inside a tenant (e.g. Faculty, Department, Division)
-- -----------------------------------------------------------------------------------
CREATE TABLE organizations (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    type            VARCHAR(100),
    description     TEXT
);

CREATE INDEX idx_organizations_tenant_id ON organizations (tenant_id);

-- -----------------------------------------------------------------------------------
-- TABLE: organization_users
-- Description: Users who belong to an organization with an org-scoped role
-- -----------------------------------------------------------------------------------
CREATE TABLE organization_users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role            VARCHAR(100)    NOT NULL DEFAULT 'member',
    UNIQUE (organization_id, user_id)
);

CREATE INDEX idx_organization_users_organization_id ON organization_users (organization_id);
CREATE INDEX idx_organization_users_user_id         ON organization_users (user_id);
