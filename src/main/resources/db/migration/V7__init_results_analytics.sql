-- ===================================================================================
-- Migration   : V7
-- Title       : Init Results & Analytics
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Formal exam results, appeal system, and aggregate analytics
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: exam_results
-- Description: Official result record produced from a submitted attempt
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_results (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id          UUID            NOT NULL UNIQUE REFERENCES exam_attempts (id) ON DELETE CASCADE,
    user_id             UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    exam_id             UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    total_score         NUMERIC(10, 2)  NOT NULL,
    max_score           NUMERIC(10, 2)  NOT NULL,
    percentage          NUMERIC(5, 2)   NOT NULL,
    grade               VARCHAR(10),
    is_passed           BOOLEAN         NOT NULL,
    percentile_rank     NUMERIC(5, 2),
    published_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exam_results_user_id   ON exam_results (user_id);
CREATE INDEX idx_exam_results_exam_id   ON exam_results (exam_id);
CREATE INDEX idx_exam_results_is_passed ON exam_results (is_passed);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_appeals
-- Description: Student requests re-evaluation of their published result
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_appeals (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    result_id       UUID            NOT NULL REFERENCES exam_results (id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    reason          TEXT            NOT NULL,
    status          VARCHAR(50)     NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    resolution      TEXT,
    resolved_by     UUID            REFERENCES users (id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    resolved_at     TIMESTAMPTZ
);

CREATE INDEX idx_exam_appeals_result_id   ON exam_appeals (result_id);
CREATE INDEX idx_exam_appeals_user_id     ON exam_appeals (user_id);
CREATE INDEX idx_exam_appeals_status      ON exam_appeals (status);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_analytics
-- Description: Pre-computed aggregate statistics per exam
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_analytics (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id                 UUID            NOT NULL UNIQUE REFERENCES exams (id) ON DELETE CASCADE,
    total_participants      INT             NOT NULL DEFAULT 0,
    total_completions       INT             NOT NULL DEFAULT 0,
    avg_score               NUMERIC(10, 2),
    pass_rate               NUMERIC(5, 2),
    difficulty_index        NUMERIC(5, 4),
    discrimination_index    NUMERIC(5, 4),
    calculated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exam_analytics_exam_id ON exam_analytics (exam_id);
