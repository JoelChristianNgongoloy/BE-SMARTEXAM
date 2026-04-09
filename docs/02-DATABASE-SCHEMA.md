# SmartEdu Telu — Database Schema

> **Versi:** 1.0
> **Tanggal:** 2026-04-09
> **Database:** PostgreSQL 17
> **Total Tabel:** 68
> **PK Strategy:** UUID (`gen_random_uuid()`)
> **Timezone:** Semua timestamp menggunakan `TIMESTAMPTZ`
> **Soft Delete:** Tabel dengan kolom `deleted_at` mendukung soft delete

---

## Daftar Migrasi Flyway

| File | Domain | Jumlah Tabel |
|------|--------|:------------:|
| `V1__init_core_auth_system.sql` | Auth & User | 7 |
| `V2__init_organization_multitenancy.sql` | Tenant & Organisasi | 4 |
| `V3__init_exam_management.sql` | Manajemen Ujian | 3 |
| `V4__init_question_bank.sql` | Bank Soal | 6 |
| `V5__init_scheduling_proctoring.sql` | Penjadwalan & Proctoring | 6 |
| `V6__init_evaluation_grading.sql` | Evaluasi & Penilaian | 4 |
| `V7__init_results_analytics.sql` | Hasil & Analitik | 3 |
| `V8__init_certificates.sql` | Sertifikat | 2 |
| `V9__init_communication.sql` | Komunikasi | 6 |
| `V10__init_calendar_media_tags.sql` | Kalender, Media, Tag | 4 |
| `V11__init_gamification_billing.sql` | Gamifikasi & Billing | 9 |
| `V12__init_support_logging_system.sql` | Support, Logging, System | 14 |
| **Total** | | **68** |

---

## V1 — Core Auth System (7 tabel)

### `users`
Akun utama pengguna. Ini adalah identity table — tidak terikat tenant tertentu.
Satu user bisa tergabung di banyak tenant.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK, default `gen_random_uuid()` | Primary key |
| `name` | VARCHAR(255) | NOT NULL | Nama lengkap |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Email (digunakan untuk login) |
| `password_hash` | VARCHAR(255) | nullable | Hashed password (BCrypt) |
| `phone` | VARCHAR(50) | nullable | Nomor telepon |
| `picture` | TEXT | nullable | URL foto profil |
| `locale` | VARCHAR(10) | NOT NULL, default `'id'` | Bahasa preferensi |
| `timezone` | VARCHAR(100) | NOT NULL, default `'Asia/Jakarta'` | Timezone |
| `status` | VARCHAR(50) | NOT NULL, default `'active'` | Status: `active`, `inactive`, `suspended`, `pending` |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Waktu pembuatan |
| `updated_at` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Waktu update terakhir |
| `deleted_at` | TIMESTAMPTZ | nullable | Soft delete timestamp |

**Index:** `email`, `status`, `deleted_at`

---

### `roles`
Role aplikasi (contoh: admin, student, teacher, proctor).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | Nama role |
| `description` | TEXT | nullable | Penjelasan role |

---

### `permissions`
Hak akses granular (contoh: `exam:create`, `result:view`, `user:manage`).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `name` | VARCHAR(150) | NOT NULL, UNIQUE | Nama permission |
| `description` | TEXT | nullable | Penjelasan |

---

### `user_roles`
Relasi M:N antara users dan roles. Satu user bisa punya banyak role.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `user_id` | UUID | FK → `users(id)` ON DELETE CASCADE | User |
| `role_id` | UUID | FK → `roles(id)` ON DELETE CASCADE | Role |

**Unique:** `(user_id, role_id)` — Tidak boleh assign role yang sama 2x.

---

### `role_permissions`
Relasi M:N antara roles dan permissions. Satu role bisa punya banyak permission.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `role_id` | UUID | FK → `roles(id)` ON DELETE CASCADE | Role |
| `permission_id` | UUID | FK → `permissions(id)` ON DELETE CASCADE | Permission |

**Unique:** `(role_id, permission_id)`

---

### `user_sessions`
Sesi login aktif per user per device. Untuk manajemen multi-device (logout remote).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `user_id` | UUID | FK → `users(id)` ON DELETE CASCADE | Pemilik sesi |
| `ip_address` | VARCHAR(45) | nullable | IP address (IPv4/IPv6) |
| `user_agent` | TEXT | nullable | Browser user agent |
| `device` | VARCHAR(255) | nullable | Nama/tipe device |
| `last_active` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Aktivitas terakhir |
| `expired_at` | TIMESTAMPTZ | NOT NULL | Kadaluarsa token |

---

### `password_resets`
Token reset password satu kali pakai.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `user_id` | UUID | FK → `users(id)` ON DELETE CASCADE | User yang request reset |
| `token` | VARCHAR(255) | NOT NULL, UNIQUE | Token unik |
| `expired_at` | TIMESTAMPTZ | NOT NULL | Kadaluarsa token |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Dibuat kapan |

---

## V2 — Organization & Multitenancy (4 tabel)

### `tenants`
Institusi top-level (contoh: Telkom University, ITB). Semua data ujian ter-scope ke tenant.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `name` | VARCHAR(255) | NOT NULL | Nama tenant/institusi |
| `domain` | VARCHAR(255) | UNIQUE, nullable | Domain custom (opsional) |
| `logo` | TEXT | nullable | URL logo |
| `status` | VARCHAR(50) | NOT NULL, default `'active'` | `active`, `inactive`, `suspended` |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Waktu pembuatan |

---

### `tenant_users`
Keanggotaan user dalam tenant dengan role tenant-specific.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` ON DELETE CASCADE | Tenant |
| `user_id` | UUID | FK → `users(id)` ON DELETE CASCADE | User |
| `role` | VARCHAR(100) | NOT NULL, default `'member'` | Role di tenant ini |

**Unique:** `(tenant_id, user_id)` — 1 user hanya 1 keanggotaan per tenant.

---

### `organizations`
Sub-unit di dalam tenant (contoh: Fakultas Informatika, Jurusan IF).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` ON DELETE CASCADE | Milik tenant |
| `name` | VARCHAR(255) | NOT NULL | Nama organisasi |
| `type` | VARCHAR(100) | nullable | Tipe (fakultas, jurusan, divisi) |
| `description` | TEXT | nullable | Penjelasan |

---

### `organization_users`
Keanggotaan user di organisasi.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `organization_id` | UUID | FK → `organizations(id)` ON DELETE CASCADE | Organisasi |
| `user_id` | UUID | FK → `users(id)` ON DELETE CASCADE | User |
| `role` | VARCHAR(100) | NOT NULL, default `'member'` | Role di org ini |

**Unique:** `(organization_id, user_id)`

---

## V3 — Exam Management (3 tabel)

### `exam_categories`
Kategori ujian berbentuk tree/hierarki (parent → child). Contoh: "Teknik" → "Informatika" → "UTS".

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` ON DELETE CASCADE | Milik tenant |
| `name` | VARCHAR(255) | NOT NULL | Nama kategori |
| `slug` | VARCHAR(255) | NOT NULL | URL-friendly name |
| `description` | TEXT | nullable | Penjelasan |
| `parent_id` | UUID | FK → `exam_categories(id)` ON DELETE SET NULL | Parent (self-ref, tree) |
| `position` | INT | NOT NULL, default `0` | Urutan |

**Unique:** `(tenant_id, slug)`

---

### `exams`
**Entitas utama** — sebuah ujian dengan semua konfigurasinya.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` ON DELETE CASCADE | Milik tenant |
| `category_id` | UUID | FK → `exam_categories(id)` ON DELETE SET NULL | Kategori ujian |
| `title` | VARCHAR(255) | NOT NULL | Judul ujian |
| `slug` | VARCHAR(255) | NOT NULL | URL-friendly |
| `description` | TEXT | nullable | Deskripsi ujian |
| `exam_type` | VARCHAR(100) | NOT NULL, default `'standard'` | `standard`, `practice`, `mock`, `certification`, `midterm`, `final` |
| `time_limit_minutes` | INT | nullable | Durasi ujian (menit). NULL = tanpa batas |
| `max_attempts` | INT | NOT NULL, default `1` | Maksimal percobaan |
| `pass_percentage` | INT | NOT NULL, default `60`, CHECK 0-100 | Persentase kelulusan |
| `total_score` | NUMERIC(10,2) | NOT NULL, default `100` | Skor maksimal |
| `random_questions` | BOOLEAN | NOT NULL, default `FALSE` | Acak urutan soal? |
| `random_answers` | BOOLEAN | NOT NULL, default `FALSE` | Acak urutan jawaban? |
| `show_result_mode` | VARCHAR(50) | NOT NULL, default `'after_submit'` | `after_submit`, `after_review`, `manual`, `never` |
| `allow_review` | BOOLEAN | NOT NULL, default `TRUE` | Student boleh review jawaban? |
| `shuffle_sections` | BOOLEAN | NOT NULL, default `FALSE` | Acak urutan section? |
| `require_proctoring` | BOOLEAN | NOT NULL, default `FALSE` | Wajib proctoring? |
| `feedback_type` | VARCHAR(50) | NOT NULL, default `'summary'` | `none`, `summary`, `detailed` |
| `instructions` | TEXT | nullable | Instruksi sebelum ujian |
| `status` | VARCHAR(50) | NOT NULL, default `'draft'` | `draft`, `published`, `archived` |
| `created_by` | UUID | FK → `users(id)` | Pembuat ujian |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NOT NULL, default `NOW()` | — |
| `deleted_at` | TIMESTAMPTZ | nullable | Soft delete |

**Unique:** `(tenant_id, slug)`

---

### `exam_sections`
Bagian-bagian dalam 1 ujian (contoh: Part A - Pilihan Ganda, Part B - Essay).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `exam_id` | UUID | FK → `exams(id)` ON DELETE CASCADE | Milik ujian |
| `title` | VARCHAR(255) | NOT NULL | Judul section |
| `instruction` | TEXT | nullable | Instruksi section |
| `position` | INT | NOT NULL, default `0` | Urutan |
| `time_limit_seconds` | INT | nullable | Batas waktu section |
| `question_count` | INT | NOT NULL, default `0` | Jumlah soal (denormalized) |

---

## V4 — Question Bank (6 tabel)

### `question_bank_folders`
Struktur folder hierarkis untuk mengorganisasi soal. Self-referencing tree.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` | Milik tenant |
| `parent_id` | UUID | FK → self, ON DELETE SET NULL | Parent folder |
| `name` | VARCHAR(255) | NOT NULL | Nama folder |
| `description` | TEXT | nullable | Penjelasan |
| `position` | INT | NOT NULL, default `0` | Urutan |

---

### `question_categories`
Taksonomi flat untuk soal (contoh: Matematika, Logika, Bahasa Inggris).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` | Milik tenant |
| `name` | VARCHAR(255) | NOT NULL | Nama kategori |
| `description` | TEXT | nullable | Penjelasan |

**Unique:** `(tenant_id, name)`

---

### `questions`
Soal individual dalam bank soal.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` | Milik tenant |
| `category_id` | UUID | FK → `question_categories(id)` | Kategori |
| `folder_id` | UUID | FK → `question_bank_folders(id)` | Folder |
| `question_text` | TEXT | NOT NULL | Teks soal (bisa HTML/Markdown) |
| `description` | TEXT | nullable | Penjelasan tambahan |
| `explanation` | TEXT | nullable | Penjelasan jawaban (untuk review) |
| `type` | VARCHAR(50) | NOT NULL, default `'multiple_choice'` | `multiple_choice`, `multiple_answer`, `true_false`, `short_answer`, `essay`, `fill_in_blank`, `matching` |
| `points` | INT | NOT NULL, default `1` | Bobot poin |
| `position` | INT | NOT NULL, default `0` | Urutan |
| `difficulty_level` | VARCHAR(20) | NOT NULL, default `'medium'` | `easy`, `medium`, `hard` |
| `time_estimate_seconds` | INT | nullable | Estimasi waktu pengerjaan |
| `picture` | TEXT | nullable | URL gambar soal |
| `is_shared` | BOOLEAN | NOT NULL, default `FALSE` | Bisa dipakai lintas tenant? |
| `created_by` | UUID | FK → `users(id)` | Pembuat soal |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |
| `updated_at` | TIMESTAMPTZ | NOT NULL | — |

---

### `options`
Opsi jawaban untuk soal (MCQ, T/F, matching).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `question_id` | UUID | FK → `questions(id)` ON DELETE CASCADE | Milik soal |
| `option_text` | TEXT | NOT NULL | Teks opsi |
| `is_correct` | BOOLEAN | NOT NULL, default `FALSE` | Jawaban benar? |
| `weight` | NUMERIC(5,2) | NOT NULL, default `0` | Bobot (untuk scoring parsial) |
| `position` | INT | NOT NULL, default `0` | Urutan |
| `feedback` | TEXT | nullable | Feedback jika memilih opsi ini |

---

### `question_attachments`
File/media yang dilampirkan ke soal (gambar, audio, video).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `question_id` | UUID | FK → `questions(id)` ON DELETE CASCADE | Milik soal |
| `file_name` | VARCHAR(255) | NOT NULL | Nama file original |
| `file_path` | TEXT | NOT NULL | Path/URL file di storage |
| `file_type` | VARCHAR(100) | nullable | MIME type |
| `file_size` | INT | nullable | Ukuran file (bytes) |
| `position` | INT | NOT NULL, default `0` | Urutan |

---

### `exam_questions`
Mapping soal ke section ujian. Satu soal bisa dipakai di banyak ujian (reuse dari bank soal).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `section_id` | UUID | FK → `exam_sections(id)` ON DELETE CASCADE | Section ujian |
| `question_id` | UUID | FK → `questions(id)` ON DELETE CASCADE | Soal |
| `position` | INT | NOT NULL, default `0` | Urutan dalam section |
| `weight` | NUMERIC(5,2) | NOT NULL, default `1` | Bobot soal di ujian ini |

**Unique:** `(section_id, question_id)` — 1 soal hanya 1x per section.

---

## V5 — Scheduling & Proctoring (6 tabel)

### `exam_schedules`
Jadwal pelaksanaan ujian (time window).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `exam_id` | UUID | FK → `exams(id)` ON DELETE CASCADE | Ujian |
| `start_time` | TIMESTAMPTZ | NOT NULL | Waktu mulai |
| `end_time` | TIMESTAMPTZ | NOT NULL, CHECK `> start_time` | Waktu selesai |
| `max_participants` | INT | nullable | Kapasitas peserta |
| `location` | VARCHAR(255) | nullable | Lokasi (fisik/virtual link) |
| `is_active` | BOOLEAN | NOT NULL, default `TRUE` | Aktif/nonaktif |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

---

### `exam_rooms`
Ruang ujian virtual/fisik dengan konfigurasi browser lockdown.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `tenant_id` | UUID | FK → `tenants(id)` | Milik tenant |
| `name` | VARCHAR(255) | NOT NULL | Nama ruang |
| `type` | VARCHAR(50) | NOT NULL, default `'virtual'` | `virtual`, `physical`, `hybrid` |
| `capacity` | INT | nullable | Kapasitas |
| `browser_lockdown_config` | JSONB | nullable | Config lockdown browser (JSON) |
| `is_active` | BOOLEAN | NOT NULL, default `TRUE` | Aktif? |

---

### `exam_registrations`
Pendaftaran student ke ujian + jadwal tertentu.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `exam_id` | UUID | FK → `exams(id)` | Ujian |
| `user_id` | UUID | FK → `users(id)` | Student |
| `schedule_id` | UUID | FK → `exam_schedules(id)` | Jadwal dipilih |
| `status` | VARCHAR(50) | NOT NULL, default `'registered'` | `registered`, `confirmed`, `cancelled`, `no_show`, `completed` |
| `registered_at` | TIMESTAMPTZ | NOT NULL | — |

**Unique:** `(exam_id, user_id, schedule_id)`

---

### `exam_sessions`
Sesi ujian aktif — satu "duduk" mengerjakan ujian oleh student.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `exam_id` | UUID | FK → `exams(id)` | Ujian |
| `schedule_id` | UUID | FK → `exam_schedules(id)` | Jadwal |
| `room_id` | UUID | FK → `exam_rooms(id)` | Ruang |
| `student_id` | UUID | FK → `users(id)` | Student |
| `start_time` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Mulai |
| `end_time` | TIMESTAMPTZ | nullable | Selesai |
| `ip_address` | VARCHAR(45) | nullable | IP student |
| `device_info` | TEXT | nullable | Info device |
| `is_proctored` | BOOLEAN | NOT NULL, default `FALSE` | Diawasi? |
| `browser_lockdown` | BOOLEAN | NOT NULL, default `FALSE` | Browser terkunci? |
| `webcam_required` | BOOLEAN | NOT NULL, default `FALSE` | Webcam wajib? |

---

### `proctor_assignments`
Penugasan proctor ke sesi ujian.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `session_id` | UUID | FK → `exam_sessions(id)` ON DELETE CASCADE | Sesi |
| `proctor_id` | UUID | FK → `users(id)` ON DELETE CASCADE | Proctor (teacher) |
| `role` | VARCHAR(50) | NOT NULL, default `'observer'` | `observer`, `lead`, `assistant` |
| `assigned_at` | TIMESTAMPTZ | NOT NULL | — |

**Unique:** `(session_id, proctor_id)`

---

### `cheating_logs`
Log aktivitas mencurigakan selama sesi ujian.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `session_id` | UUID | FK → `exam_sessions(id)` ON DELETE CASCADE | Sesi |
| `event` | VARCHAR(100) | NOT NULL | Jenis event (tab_switch, copy_paste, face_not_detected) |
| `detail` | TEXT | nullable | Detail tambahan |
| `severity` | VARCHAR(20) | NOT NULL, default `'low'` | `low`, `medium`, `high`, `critical` |
| `screenshot_url` | TEXT | nullable | Bukti screenshot |
| `event_time` | TIMESTAMPTZ | NOT NULL, default `NOW()` | Waktu kejadian |

---

## V6 — Evaluation & Grading (4 tabel)

### `exam_attempts`
Setiap percobaan mengerjakan ujian oleh student.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `exam_id` | UUID | FK → `exams(id)` | Ujian |
| `student_id` | UUID | FK → `users(id)` | Student |
| `session_id` | UUID | FK → `exam_sessions(id)` | Sesi terkait |
| `score` | NUMERIC(10,2) | nullable | Skor total |
| `passed` | BOOLEAN | nullable | Lulus? |
| `questions_answered` | INT | NOT NULL, default `0` | Jumlah soal dijawab |
| `time_spent_seconds` | INT | NOT NULL, default `0` | Total waktu (detik) |
| `ip_address` | VARCHAR(45) | nullable | IP |
| `device_info` | TEXT | nullable | Device |
| `started_at` | TIMESTAMPTZ | NOT NULL | Mulai |
| `submitted_at` | TIMESTAMPTZ | nullable | Selesai submit |

---

### `exam_attempt_answers`
Jawaban per soal dalam satu attempt.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `attempt_id` | UUID | FK → `exam_attempts(id)` ON DELETE CASCADE | Attempt |
| `question_id` | UUID | FK → `questions(id)` ON DELETE CASCADE | Soal |
| `answer` | TEXT | nullable | Jawaban student (teks/ID opsi) |
| `score` | NUMERIC(10,2) | nullable | Skor jawaban |
| `is_correct` | BOOLEAN | nullable | Benar? |
| `time_spent_seconds` | INT | NOT NULL, default `0` | Waktu per soal |
| `answered_at` | TIMESTAMPTZ | NOT NULL | — |

**Unique:** `(attempt_id, question_id)` — 1 jawaban per soal per attempt.

---

### `grading_rubrics`
Rubrik penilaian untuk soal open-ended/essay.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `question_id` | UUID | FK → `questions(id)` ON DELETE CASCADE | Soal |
| `title` | VARCHAR(255) | NOT NULL | Judul rubrik |
| `description` | TEXT | nullable | Penjelasan |
| `max_score` | NUMERIC(10,2) | NOT NULL | Skor maksimal rubrik |
| `created_by` | UUID | FK → `users(id)` | Pembuat |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

---

### `rubric_criteria`
Kriteria individual dalam rubrik.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Primary key |
| `rubric_id` | UUID | FK → `grading_rubrics(id)` ON DELETE CASCADE | Rubrik |
| `criterion` | VARCHAR(255) | NOT NULL | Nama kriteria |
| `description` | TEXT | nullable | Penjelasan |
| `max_score` | NUMERIC(10,2) | NOT NULL | Skor maks kriteria |
| `position` | INT | NOT NULL, default `0` | Urutan |

---

## V7 — Results & Analytics (3 tabel)

### `exam_results`
Hasil resmi ujian yang dipublikasikan ke student.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `attempt_id` | UUID | FK → `exam_attempts(id)`, UNIQUE | 1 hasil per attempt |
| `user_id` | UUID | FK → `users(id)` | Student |
| `exam_id` | UUID | FK → `exams(id)` | Ujian |
| `total_score` | NUMERIC(10,2) | NOT NULL | Skor perolehan |
| `max_score` | NUMERIC(10,2) | NOT NULL | Skor maksimal |
| `percentage` | NUMERIC(5,2) | NOT NULL | Persentase |
| `grade` | VARCHAR(10) | nullable | Huruf mutu (A, B, C, dll) |
| `is_passed` | BOOLEAN | NOT NULL | Lulus/tidak |
| `percentile_rank` | NUMERIC(5,2) | nullable | Peringkat persentil |
| `published_at` | TIMESTAMPTZ | nullable | Kapan dipublikasikan |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

---

### `exam_appeals`
Pengajuan banding oleh student atas hasil ujian.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `result_id` | UUID | FK → `exam_results(id)` | Hasil yang dibanding |
| `user_id` | UUID | FK → `users(id)` | Student |
| `reason` | TEXT | NOT NULL | Alasan banding |
| `status` | VARCHAR(50) | NOT NULL, default `'pending'` | `pending`, `under_review`, `approved`, `rejected` |
| `resolution` | TEXT | nullable | Resolusi/keputusan |
| `resolved_by` | UUID | FK → `users(id)` | Siapa yang resolve |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |
| `resolved_at` | TIMESTAMPTZ | nullable | — |

---

### `exam_analytics`
Statistik agregat per ujian (pre-computed untuk performa).

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `exam_id` | UUID | FK → `exams(id)`, UNIQUE | 1 analitik per ujian |
| `total_participants` | INT | NOT NULL, default `0` | Total peserta |
| `total_completions` | INT | NOT NULL, default `0` | Yang menyelesaikan |
| `avg_score` | NUMERIC(10,2) | nullable | Rata-rata skor |
| `pass_rate` | NUMERIC(5,2) | nullable | Persentase kelulusan |
| `difficulty_index` | NUMERIC(5,4) | nullable | Indeks kesulitan |
| `discrimination_index` | NUMERIC(5,4) | nullable | Indeks daya beda |
| `calculated_at` | TIMESTAMPTZ | NOT NULL | Terakhir dihitung |

---

## V8 — Certificates (2 tabel)

### `certificate_templates`
Template visual sertifikat yang bisa dipakai ulang.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `name` | VARCHAR(255) | NOT NULL | Nama template |
| `description` | TEXT | nullable | Penjelasan |
| `orientation` | VARCHAR(20) | NOT NULL, default `'landscape'` | `landscape`, `portrait` |
| `background_url` | TEXT | nullable | URL gambar background |
| `fields` | JSONB | nullable | Layout field (posisi nama, tanggal, dll) |
| `is_default` | BOOLEAN | NOT NULL, default `FALSE` | Template default? |
| `created_by` | UUID | FK → `users(id)` | Pembuat |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

---

### `certificates`
Sertifikat yang diterbitkan ke user setelah lulus ujian.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `user_id` | UUID | FK → `users(id)` | Penerima |
| `exam_id` | UUID | FK → `exams(id)` | Ujian |
| `template_id` | UUID | FK → `certificate_templates(id)` | Template dipakai |
| `certificate_number` | VARCHAR(100) | NOT NULL, UNIQUE | Nomor sertifikat unik |
| `certificate_url` | TEXT | nullable | URL file PDF |
| `metadata` | JSONB | nullable | Data tambahan (nama, tanggal, skor) |
| `issued_at` | TIMESTAMPTZ | NOT NULL | Tanggal terbit |

---

## V9 — Communication (6 tabel)

### `announcements`
Pengumuman broadcast dari admin/teacher ke user dalam tenant.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `tenant_id` | UUID | FK → `tenants(id)` | Tenant |
| `title` | VARCHAR(255) | NOT NULL | Judul |
| `message` | TEXT | NOT NULL | Isi pengumuman |
| `created_by` | UUID | FK → `users(id)` | Pembuat |
| `email_sent` | BOOLEAN | NOT NULL, default `FALSE` | Sudah dikirim via email? |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

### `announcement_attachments`
File yang dilampirkan ke pengumuman.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `announcement_id` | UUID | FK → `announcements(id)` ON DELETE CASCADE | Pengumuman |
| `file_name` | VARCHAR(255) | NOT NULL | Nama file |
| `file_path` | TEXT | NOT NULL | Path file |
| `file_type` | VARCHAR(100) | nullable | MIME type |
| `file_size` | INT | nullable | Ukuran (bytes) |

### `notifications`
Notifikasi in-app per user.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `user_id` | UUID | FK → `users(id)` | Penerima |
| `type` | VARCHAR(100) | NOT NULL | Tipe notifikasi |
| `title` | VARCHAR(255) | NOT NULL | Judul |
| `message` | TEXT | NOT NULL | Isi |
| `is_read` | BOOLEAN | NOT NULL, default `FALSE` | Sudah dibaca? |
| `link` | TEXT | nullable | Link terkait |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

### `notification_channels`
Preferensi channel notifikasi per user.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `user_id` | UUID | FK → `users(id)` | User |
| `channel` | VARCHAR(50) | NOT NULL | `email`, `push`, `sms`, `in_app` |
| `is_enabled` | BOOLEAN | NOT NULL, default `TRUE` | Aktif? |
| `preferences` | JSONB | nullable | Config tambahan |

**Unique:** `(user_id, channel)`

### `messages`
Pesan langsung antar user.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `sender_id` | UUID | FK → `users(id)` | Pengirim |
| `receiver_id` | UUID | FK → `users(id)` | Penerima |
| `subject` | VARCHAR(255) | nullable | Subjek |
| `content` | TEXT | NOT NULL | Isi pesan |
| `is_read` | BOOLEAN | NOT NULL, default `FALSE` | Dibaca? |
| `sent_at` | TIMESTAMPTZ | NOT NULL | — |

### `message_attachments`
File dalam pesan.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `message_id` | UUID | FK → `messages(id)` ON DELETE CASCADE | Pesan |
| `file_name` | VARCHAR(255) | NOT NULL | — |
| `file_path` | TEXT | NOT NULL | — |
| `file_type` | VARCHAR(100) | nullable | — |
| `file_size` | INT | nullable | — |

---

## V10 — Calendar, Media & Tags (4 tabel)

### `calendar_events`
Event kalender yang bisa dikaitkan dengan ujian.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `tenant_id` | UUID | FK → `tenants(id)` | Tenant |
| `user_id` | UUID | FK → `users(id)` | Pembuat (opsional) |
| `exam_id` | UUID | FK → `exams(id)` | Ujian terkait (opsional) |
| `title` | VARCHAR(255) | NOT NULL | Judul |
| `description` | TEXT | nullable | Deskripsi |
| `color` | VARCHAR(20) | nullable | Warna di kalender |
| `start_date` | TIMESTAMPTZ | NOT NULL | Mulai |
| `end_date` | TIMESTAMPTZ | NOT NULL, CHECK `>= start_date` | Selesai |
| `all_day` | BOOLEAN | NOT NULL, default `FALSE` | Sepanjang hari? |
| `repeat_type` | VARCHAR(50) | default `'none'` | `none`, `daily`, `weekly`, `monthly`, `yearly` |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |

### `media_files`
Registry file/media sentral — polymorphic via `context` + `context_id`.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `owner_id` | UUID | FK → `users(id)` | Pemilik file |
| `file_name` | VARCHAR(255) | NOT NULL | Nama file |
| `file_path` | TEXT | NOT NULL | Path file |
| `file_type` | VARCHAR(100) | nullable | MIME type |
| `file_size` | INT | nullable | Ukuran |
| `context` | VARCHAR(100) | nullable | Konteks pemakaian (exam, question, profile) |
| `context_id` | UUID | nullable | ID entity konteks |
| `uploaded_at` | TIMESTAMPTZ | NOT NULL | — |

### `tags`
Tag yang bisa dipakai ulang. Dikelompokkan berdasarkan type.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `name` | VARCHAR(100) | NOT NULL | Nama tag |
| `slug` | VARCHAR(100) | NOT NULL | URL-friendly |
| `type` | VARCHAR(50) | nullable | Tipe tag (exam, question, dll) |

**Unique:** `(slug, type)` — NULLS NOT DISTINCT

### `taggables`
Join table polymorphic — pasang tag ke entity mana saja.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `tag_id` | UUID | FK → `tags(id)` ON DELETE CASCADE | Tag |
| `taggable_type` | VARCHAR(100) | NOT NULL | Tipe entity (exam, question, dll) |
| `taggable_id` | UUID | NOT NULL | ID entity |

**Unique:** `(tag_id, taggable_type, taggable_id)`

---

## V11 — Gamification & Billing (9 tabel)

### `badges`
Badge/pencapaian yang bisa diraih user.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | Nama badge |
| `description` | TEXT | nullable | Penjelasan |
| `icon` | TEXT | nullable | URL ikon |
| `criteria` | TEXT | nullable | Syarat mendapatkan |

### `user_badges`
Badge yang sudah diraih user. **Unique:** `(user_id, badge_id)`

### `points`
Ledger poin per user — setiap perolehan poin = 1 row.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `user_id` | UUID | FK → `users(id)` | User |
| `points` | INT | NOT NULL | Jumlah poin |
| `source` | VARCHAR(100) | NOT NULL | Sumber (exam_complete, perfect_score, dll) |
| `source_id` | UUID | nullable | ID entity sumber |
| `earned_at` | TIMESTAMPTZ | NOT NULL | — |

### `plans`
Paket langganan.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | Nama paket |
| `description` | TEXT | nullable | Deskripsi |
| `price` | NUMERIC(15,2) | NOT NULL | Harga |
| `duration_days` | INT | NOT NULL | Durasi (hari) |
| `is_active` | BOOLEAN | NOT NULL, default `TRUE` | Aktif? |

### `subscriptions`
Langganan user ke paket tertentu. Status: `active`, `expired`, `cancelled`, `pending`.

### `transactions`
Transaksi pembayaran. Status: `pending`, `paid`, `failed`, `refunded`, `expired`. Currency default `IDR`.

### `invoices`
Invoice formal per transaksi. `invoice_number` UNIQUE.

### `coupons`
Kupon diskon — tipe: `percentage` atau `fixed`. Tracking `used_count` vs `max_uses`.

### `coupon_usages`
Pencatatan penggunaan kupon per transaksi. **Unique:** `(coupon_id, transaction_id)`.

---

## V12 — Support, Logging & System (14 tabel)

### `ticket_categories`, `ticket_priorities`, `ticket_statuses`
Lookup table untuk tiket support — masing-masing punya `name`, `color` (opsional), `position`.

### `tickets`
Tiket bantuan dari user.

| Kolom | Tipe | Constraint | Deskripsi |
|-------|------|-----------|-----------|
| `id` | UUID | PK | |
| `user_id` | UUID | FK → `users(id)` | Pembuat |
| `exam_id` | UUID | FK → `exams(id)` | Ujian terkait (opsional) |
| `category_id` | UUID | FK → `ticket_categories(id)` | Kategori |
| `priority_id` | UUID | FK → `ticket_priorities(id)` | Prioritas |
| `status_id` | UUID | FK → `ticket_statuses(id)` | Status |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE | Kode tiket |
| `subject` | VARCHAR(255) | NOT NULL | Subjek |
| `message` | TEXT | NOT NULL | Isi laporan |
| `assigned_to` | UUID | FK → `users(id)` | Staff yang menangani |
| `created_at` | TIMESTAMPTZ | NOT NULL | — |
| `updated_at` | TIMESTAMPTZ | NOT NULL | — |
| `closed_at` | TIMESTAMPTZ | nullable | — |

### `ticket_messages`
Thread diskusi dalam tiket.

### `events`
Event log aplikasi (event sourcing). Kolom utama: `event_type`, `entity_type`, `entity_id`, `metadata` (JSONB).

### `activity_logs`
Activity trail user-facing ("Kamu mengerjakan Ujian X"). `action`, `entity_type`, `entity_id`, `metadata`.

### `audit_logs`
Catatan mutasi data yang immutable. `action` (`create`/`update`/`delete`/`restore`), `old_data`, `new_data` (JSONB).

### `login_logs`
Log setiap login dan logout. `ip_address`, `user_agent`, `device`, `login_at`, `logout_at`.

### `webhooks`
Webhook endpoints per tenant. `url`, `secret`, `events` (comma-separated event types).

### `webhook_logs`
Log pengiriman webhook. `event`, `payload`, `response_code`, `response_body`.

### `feature_flags`
Toggle fitur runtime tanpa deploy. `name` (UNIQUE), `is_enabled`.

### `settings`
Key-value config global. **Unique:** `(category, key)`. Contoh: `category=exam`, `key=default_time_limit`, `value=60`.

### `user_preferences`
Key-value preferensi per user. **Unique:** `(user_id, key)`. Contoh: `key=theme`, `value=dark`.
