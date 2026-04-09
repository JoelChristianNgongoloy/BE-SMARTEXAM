-- ===================================================================================
-- Migration   : V13
-- Title       : Seed Default Roles
-- Author      : JiilanTj
-- Date        : 2026-04-09
-- Description : Insert default application roles
-- ===================================================================================

INSERT INTO roles (id, name, description) VALUES
    (gen_random_uuid(), 'admin',   'Super administrator — full platform access'),
    (gen_random_uuid(), 'teacher', 'Teacher/lecturer — manage exams, questions, and view reports'),
    (gen_random_uuid(), 'student', 'Student — take exams, view results and history'),
    (gen_random_uuid(), 'proctor', 'Proctor — supervise exam sessions and flag violations')
ON CONFLICT (name) DO NOTHING;
