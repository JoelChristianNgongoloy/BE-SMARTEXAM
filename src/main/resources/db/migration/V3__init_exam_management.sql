-- ===================================================================================
-- Migration   : V3
-- Title       : Init Exam Management
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Exam categories (tree), exams (core entity), exam sections
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: exam_categories
-- Description: Hierarchical categorization of exams (self-referencing tree)
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_categories (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    slug            VARCHAR(255)    NOT NULL,
    description     TEXT,
    parent_id       UUID            REFERENCES exam_categories (id) ON DELETE SET NULL,
    position        INT             NOT NULL DEFAULT 0,
    UNIQUE (tenant_id, slug)
);

CREATE INDEX idx_exam_categories_tenant_id  ON exam_categories (tenant_id);
CREATE INDEX idx_exam_categories_parent_id  ON exam_categories (parent_id);
CREATE INDEX idx_exam_categories_slug       ON exam_categories (slug);

-- -----------------------------------------------------------------------------------
-- TABLE: exams
-- Description: Core exam entity — configures rules, scoring, proctoring behaviour
-- -----------------------------------------------------------------------------------
CREATE TABLE exams (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    category_id             UUID            REFERENCES exam_categories (id) ON DELETE SET NULL,
    title                   VARCHAR(255)    NOT NULL,
    slug                    VARCHAR(255)    NOT NULL,
    description             TEXT,
    exam_type               VARCHAR(100)    NOT NULL DEFAULT 'standard'
                                CHECK (exam_type IN ('standard', 'practice', 'mock', 'certification', 'midterm', 'final')),
    time_limit_minutes      INT,
    max_attempts            INT             NOT NULL DEFAULT 1,
    pass_percentage         INT             NOT NULL DEFAULT 60
                                CHECK (pass_percentage BETWEEN 0 AND 100),
    total_score             NUMERIC(10, 2)  NOT NULL DEFAULT 100,
    random_questions        BOOLEAN         NOT NULL DEFAULT FALSE,
    random_answers          BOOLEAN         NOT NULL DEFAULT FALSE,
    show_result_mode        VARCHAR(50)     NOT NULL DEFAULT 'after_submit'
                                CHECK (show_result_mode IN ('after_submit', 'after_review', 'manual', 'never')),
    allow_review            BOOLEAN         NOT NULL DEFAULT TRUE,
    shuffle_sections        BOOLEAN         NOT NULL DEFAULT FALSE,
    require_proctoring      BOOLEAN         NOT NULL DEFAULT FALSE,
    feedback_type           VARCHAR(50)     NOT NULL DEFAULT 'summary'
                                CHECK (feedback_type IN ('none', 'summary', 'detailed')),
    instructions            TEXT,
    status                  VARCHAR(50)     NOT NULL DEFAULT 'draft'
                                CHECK (status IN ('draft', 'published', 'archived')),
    created_by              UUID            NOT NULL REFERENCES users (id),
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,
    UNIQUE (tenant_id, slug)
);

CREATE INDEX idx_exams_tenant_id    ON exams (tenant_id);
CREATE INDEX idx_exams_category_id  ON exams (category_id);
CREATE INDEX idx_exams_created_by   ON exams (created_by);
CREATE INDEX idx_exams_status       ON exams (status);
CREATE INDEX idx_exams_deleted_at   ON exams (deleted_at);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_sections
-- Description: Logical sections inside an exam (e.g. Part A, Essay, Listening)
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_sections (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id             UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    title               VARCHAR(255)    NOT NULL,
    instruction         TEXT,
    position            INT             NOT NULL DEFAULT 0,
    time_limit_seconds  INT,
    question_count      INT             NOT NULL DEFAULT 0
);

CREATE INDEX idx_exam_sections_exam_id ON exam_sections (exam_id);
