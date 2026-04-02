-- ===================================================================================
-- Migration   : V8
-- Title       : Init Certificates
-- Author      : JiilanTj
-- Date        : 2026-04-01
-- Description : Certificate templates and issued certificates per exam result
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: certificate_templates
-- Description: Reusable visual template for certificates (with field layout in JSON)
-- -----------------------------------------------------------------------------------
CREATE TABLE certificate_templates (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255)    NOT NULL,
    description         TEXT,
    orientation         VARCHAR(20)     NOT NULL DEFAULT 'landscape'
                            CHECK (orientation IN ('landscape', 'portrait')),
    background_url      TEXT,
    fields              JSONB,
    is_default          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_by          UUID            NOT NULL REFERENCES users (id),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cert_templates_created_by ON certificate_templates (created_by);

-- -----------------------------------------------------------------------------------
-- TABLE: certificates
-- Description: Certificate issued to a user upon passing an exam
-- -----------------------------------------------------------------------------------
CREATE TABLE certificates (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    exam_id             UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    template_id         UUID            NOT NULL REFERENCES certificate_templates (id),
    certificate_number  VARCHAR(100)    NOT NULL UNIQUE,
    certificate_url     TEXT,
    metadata            JSONB,
    issued_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_certificates_user_id          ON certificates (user_id);
CREATE INDEX idx_certificates_exam_id          ON certificates (exam_id);
CREATE INDEX idx_certificates_template_id      ON certificates (template_id);
CREATE INDEX idx_certificates_cert_number      ON certificates (certificate_number);
