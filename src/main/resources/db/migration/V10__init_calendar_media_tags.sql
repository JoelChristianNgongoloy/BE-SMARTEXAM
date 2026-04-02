-- ===================================================================================
-- Migration   : V10
-- Title       : Init Calendar, Media & Tags
-- Author      : JiilanTj
-- Date        : 2026-04-01
-- Description : Calendar events linked to exams, central media file store,
--               polymorphic tag system
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- TABLE: calendar_events
-- Description: Scheduled events visible in user/tenant calendar
-- -----------------------------------------------------------------------------------
CREATE TABLE calendar_events (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID            NOT NULL REFERENCES tenants (id) ON DELETE CASCADE,
    user_id         UUID            REFERENCES users (id) ON DELETE SET NULL,
    exam_id         UUID            REFERENCES exams (id) ON DELETE CASCADE,
    title           VARCHAR(255)    NOT NULL,
    description     TEXT,
    color           VARCHAR(20),
    start_date      TIMESTAMPTZ     NOT NULL,
    end_date        TIMESTAMPTZ     NOT NULL,
    all_day         BOOLEAN         NOT NULL DEFAULT FALSE,
    repeat_type     VARCHAR(50)     DEFAULT 'none'
                        CHECK (repeat_type IN ('none', 'daily', 'weekly', 'monthly', 'yearly')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CHECK (end_date >= start_date)
);

CREATE INDEX idx_calendar_events_tenant_id  ON calendar_events (tenant_id);
CREATE INDEX idx_calendar_events_user_id    ON calendar_events (user_id);
CREATE INDEX idx_calendar_events_exam_id    ON calendar_events (exam_id);
CREATE INDEX idx_calendar_events_start_date ON calendar_events (start_date);

-- -----------------------------------------------------------------------------------
-- TABLE: media_files
-- Description: Central file/media registry — polymorphic via context + context_id
-- -----------------------------------------------------------------------------------
CREATE TABLE media_files (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id        UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    file_name       VARCHAR(255)    NOT NULL,
    file_path       TEXT            NOT NULL,
    file_type       VARCHAR(100),
    file_size       INT,
    context         VARCHAR(100),
    context_id      UUID,
    uploaded_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_media_files_owner_id   ON media_files (owner_id);
CREATE INDEX idx_media_files_context    ON media_files (context, context_id);

-- -----------------------------------------------------------------------------------
-- TABLE: tags
-- Description: Reusable flat tags (typed by domain, e.g. exam, question)
-- -----------------------------------------------------------------------------------
CREATE TABLE tags (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    type            VARCHAR(50),
    UNIQUE NULLS NOT DISTINCT (slug, type)
);

CREATE INDEX idx_tags_type ON tags (type);

-- -----------------------------------------------------------------------------------
-- TABLE: taggables
-- Description: Polymorphic join table — attach any tag to any entity
-- -----------------------------------------------------------------------------------
CREATE TABLE taggables (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tag_id          UUID            NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
    taggable_type   VARCHAR(100)    NOT NULL,
    taggable_id     UUID            NOT NULL,
    UNIQUE (tag_id, taggable_type, taggable_id)
);

CREATE INDEX idx_taggables_tag_id       ON taggables (tag_id);
CREATE INDEX idx_taggables_entity       ON taggables (taggable_type, taggable_id);
