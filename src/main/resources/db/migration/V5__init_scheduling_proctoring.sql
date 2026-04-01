-- ===================================================================================
-- Migration   : V5
-- Title       : Init Scheduling & Proctoring
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Exam schedules, exam rooms, registrations, live exam sessions,
--               proctor assignments, and cheating event logs
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: exam_schedules
-- Description: Scheduled time windows for running an exam
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_schedules (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id             UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    start_time          TIMESTAMPTZ     NOT NULL,
    end_time            TIMESTAMPTZ     NOT NULL,
    max_participants    INT,
    location            VARCHAR(255),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CHECK (end_time > start_time)
);

CREATE INDEX idx_exam_schedules_exam_id     ON exam_schedules (exam_id);
CREATE INDEX idx_exam_schedules_start_time  ON exam_schedules (start_time);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_rooms
-- Description: Virtual or physical rooms for taking exams (browser lockdown config)
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_rooms (
    id                          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                   UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    name                        VARCHAR(255)    NOT NULL,
    type                        VARCHAR(50)     NOT NULL DEFAULT 'virtual'
                                    CHECK (type IN ('virtual', 'physical', 'hybrid')),
    capacity                    INT,
    browser_lockdown_config     JSONB,
    is_active                   BOOLEAN         NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_exam_rooms_tenant_id ON exam_rooms (tenant_id);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_registrations
-- Description: Student enrolls for a specific exam + schedule slot
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_registrations (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id         UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    schedule_id     UUID            NOT NULL REFERENCES exam_schedules (id) ON DELETE CASCADE,
    status          VARCHAR(50)     NOT NULL DEFAULT 'registered'
                        CHECK (status IN ('registered', 'confirmed', 'cancelled', 'no_show', 'completed')),
    registered_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (exam_id, user_id, schedule_id)
);

CREATE INDEX idx_exam_registrations_exam_id     ON exam_registrations (exam_id);
CREATE INDEX idx_exam_registrations_user_id     ON exam_registrations (user_id);
CREATE INDEX idx_exam_registrations_schedule_id ON exam_registrations (schedule_id);

-- -----------------------------------------------------------------------------------
-- TABLE: exam_sessions
-- Description: One active exam sitting for a student — tracks device/IP and proctoring
-- -----------------------------------------------------------------------------------
CREATE TABLE exam_sessions (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id             UUID            NOT NULL REFERENCES exams (id) ON DELETE CASCADE,
    schedule_id         UUID            REFERENCES exam_schedules (id) ON DELETE SET NULL,
    room_id             UUID            REFERENCES exam_rooms (id) ON DELETE SET NULL,
    student_id          UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    start_time          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    end_time            TIMESTAMPTZ,
    ip_address          VARCHAR(45),
    device_info         TEXT,
    is_proctored        BOOLEAN         NOT NULL DEFAULT FALSE,
    browser_lockdown    BOOLEAN         NOT NULL DEFAULT FALSE,
    webcam_required     BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_exam_sessions_exam_id      ON exam_sessions (exam_id);
CREATE INDEX idx_exam_sessions_student_id   ON exam_sessions (student_id);
CREATE INDEX idx_exam_sessions_schedule_id  ON exam_sessions (schedule_id);
CREATE INDEX idx_exam_sessions_room_id      ON exam_sessions (room_id);

-- -----------------------------------------------------------------------------------
-- TABLE: proctor_assignments
-- Description: Proctors assigned to an exam session
-- -----------------------------------------------------------------------------------
CREATE TABLE proctor_assignments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID            NOT NULL REFERENCES exam_sessions (id) ON DELETE CASCADE,
    proctor_id      UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role            VARCHAR(50)     NOT NULL DEFAULT 'observer'
                        CHECK (role IN ('observer', 'lead', 'assistant')),
    assigned_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (session_id, proctor_id)
);

CREATE INDEX idx_proctor_assignments_session_id  ON proctor_assignments (session_id);
CREATE INDEX idx_proctor_assignments_proctor_id  ON proctor_assignments (proctor_id);

-- -----------------------------------------------------------------------------------
-- TABLE: cheating_logs
-- Description: Records of suspicious activity detected during a session
-- -----------------------------------------------------------------------------------
CREATE TABLE cheating_logs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID            NOT NULL REFERENCES exam_sessions (id) ON DELETE CASCADE,
    event           VARCHAR(100)    NOT NULL,
    detail          TEXT,
    severity        VARCHAR(20)     NOT NULL DEFAULT 'low'
                        CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    screenshot_url  TEXT,
    event_time      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cheating_logs_session_id  ON cheating_logs (session_id);
CREATE INDEX idx_cheating_logs_severity    ON cheating_logs (severity);
CREATE INDEX idx_cheating_logs_event_time  ON cheating_logs (event_time);
