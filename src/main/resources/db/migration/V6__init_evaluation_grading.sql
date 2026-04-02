-- ===================================================================================
-- Migration   : V6
-- Title       : Init Evaluation & Grading
-- Author      : JiilanTj
-- Date        : 2026-04-01
-- Description : Exam attempts, per-question answers, grading rubrics for essays
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: exam_attempts
-- Description: Each attempt a student makes on an exam; final score stored here
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_attempts (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id             UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    student_id          UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_id          UUID            REFERENCES exam_sessions (id) ON DELETE SET NULL,
    score               NUMERIC(10, 2),
    passed              BOOLEAN,
    questions_answered  INT             NOT NULL DEFAULT 0,
    time_spent_seconds  INT             NOT NULL DEFAULT 0,
    ip_address          VARCHAR(45),
    device_info         TEXT,
    started_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    submitted_at        TIMESTAMPTZ
);

CREATE INDEX idx_exam_attempts_exam_id      ON exam_attempts (exam_id);
CREATE INDEX idx_exam_attempts_student_id   ON exam_attempts (student_id);
CREATE INDEX idx_exam_attempts_session_id   ON exam_attempts (session_id);
CREATE INDEX idx_exam_attempts_submitted_at ON exam_attempts (submitted_at);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_attempt_answers
-- Description: Student's answer to each question within an attempt
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_attempt_answers (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id          UUID            NOT NULL REFERENCES exam_attempts (id) ON DELETE CASCADE,
    question_id         UUID            NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    answer              TEXT,
    score               NUMERIC(10, 2),
    is_correct          BOOLEAN,
    time_spent_seconds  INT             NOT NULL DEFAULT 0,
    answered_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (attempt_id, question_id)
);

CREATE INDEX idx_attempt_answers_attempt_id  ON exam_attempt_answers (attempt_id);
CREATE INDEX idx_attempt_answers_question_id ON exam_attempt_answers (question_id);

-- -----------------------------------------------------------------------------------
-- TABLE: grading_rubrics
-- Description: Scoring rubric for open-ended / essay questions
-- -----------------------------------------------------------------------------------
CREATE TABLE grading_rubrics (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id     UUID            NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    title           VARCHAR(255)    NOT NULL,
    description     TEXT,
    max_score       NUMERIC(10, 2)  NOT NULL,
    created_by      UUID            NOT NULL REFERENCES users (id),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_grading_rubrics_question_id ON grading_rubrics (question_id);

-- -----------------------------------------------------------------------------------
-- TABLE: rubric_criteria
-- Description: Individual scoring criteria within a rubric
-- -----------------------------------------------------------------------------------
CREATE TABLE rubric_criteria (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    rubric_id       UUID            NOT NULL REFERENCES grading_rubrics (id) ON DELETE CASCADE,
    criterion       VARCHAR(255)    NOT NULL,
    description     TEXT,
    max_score       NUMERIC(10, 2)  NOT NULL,
    position        INT             NOT NULL DEFAULT 0
);

CREATE INDEX idx_rubric_criteria_rubric_id ON rubric_criteria (rubric_id);
