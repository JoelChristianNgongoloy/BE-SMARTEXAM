-- ===================================================================================
-- Migration   : V4
-- Title       : Init Question Bank
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Hierarchical question folders, categories, questions, answer
--               options, attachments, and exam-section-to-question mapping
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: question_bank_folders
-- Description: Folder tree for organizing questions (self-referencing)
-- -----------------------------------------------------------------------------------
CREATE TABLE question_bank_folders (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    parent_id       UUID            REFERENCES question_bank_folders (id) ON DELETE SET NULL,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    position        INT             NOT NULL DEFAULT 0
);

CREATE INDEX idx_qb_folders_tenant_id  ON question_bank_folders (tenant_id);
CREATE INDEX idx_qb_folders_parent_id  ON question_bank_folders (parent_id);

-- -----------------------------------------------------------------------------------
-- TABLE: question_categories
-- Description: Flat taxonomy for questions (e.g. Math, Logic, English)
-- -----------------------------------------------------------------------------------
CREATE TABLE question_categories (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    UNIQUE (tenant_id, name)
);

CREATE INDEX idx_question_categories_tenant_id ON question_categories (tenant_id);

-- -----------------------------------------------------------------------------------
-- TABLE: questions
-- Description: Individual question items in the bank
-- -----------------------------------------------------------------------------------
CREATE TABLE questions (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    category_id             UUID            REFERENCES question_categories (id) ON DELETE SET NULL,
    folder_id               UUID            REFERENCES question_bank_folders (id) ON DELETE SET NULL,
    question_text           TEXT            NOT NULL,
    description             TEXT,
    explanation             TEXT,
    type                    VARCHAR(50)     NOT NULL DEFAULT 'multiple_choice'
                                CHECK (type IN (
                                    'multiple_choice', 'multiple_answer', 'true_false',
                                    'short_answer', 'essay', 'fill_in_blank', 'matching'
                                )),
    points                  INT             NOT NULL DEFAULT 1,
    position                INT             NOT NULL DEFAULT 0,
    difficulty_level        VARCHAR(20)     NOT NULL DEFAULT 'medium'
                                CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    time_estimate_seconds   INT,
    picture                 TEXT,
    is_shared               BOOLEAN         NOT NULL DEFAULT FALSE,
    created_by              UUID            NOT NULL REFERENCES users (id),
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_questions_tenant_id    ON questions (tenant_id);
CREATE INDEX idx_questions_category_id  ON questions (category_id);
CREATE INDEX idx_questions_folder_id    ON questions (folder_id);
CREATE INDEX idx_questions_created_by   ON questions (created_by);
CREATE INDEX idx_questions_type         ON questions (type);
CREATE INDEX idx_questions_difficulty   ON questions (difficulty_level);

-- -----------------------------------------------------------------------------------
-- TABLE: options
-- Description: Answer choices for a question (used by MC, T/F, matching, etc.)
-- -----------------------------------------------------------------------------------
CREATE TABLE options (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id     UUID            NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    option_text     TEXT            NOT NULL,
    is_correct      BOOLEAN         NOT NULL DEFAULT FALSE,
    weight          NUMERIC(5, 2)   NOT NULL DEFAULT 0,
    position        INT             NOT NULL DEFAULT 0,
    feedback        TEXT
);

CREATE INDEX idx_options_question_id ON options (question_id);

-- -----------------------------------------------------------------------------------
-- TABLE: question_attachments
-- Description: Files/media attached to a question (images, audio, video)
-- -----------------------------------------------------------------------------------
CREATE TABLE question_attachments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id     UUID            NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    file_name       VARCHAR(255)    NOT NULL,
    file_path       TEXT            NOT NULL,
    file_type       VARCHAR(100),
    file_size       INT,
    position        INT             NOT NULL DEFAULT 0
);

CREATE INDEX idx_question_attachments_question_id ON question_attachments (question_id);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_questions
-- Description: Links exam sections to questions with ordering and per-question weight
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_questions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id      UUID            NOT NULL REFERENCES exam_sections (id) ON DELETE CASCADE,
    question_id     UUID            NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    position        INT             NOT NULL DEFAULT 0,
    weight          NUMERIC(5, 2)   NOT NULL DEFAULT 1,
    UNIQUE (section_id, question_id)
);

CREATE INDEX idx_exam_questions_section_id  ON exam_questions (section_id);
CREATE INDEX idx_exam_questions_question_id ON exam_questions (question_id);
