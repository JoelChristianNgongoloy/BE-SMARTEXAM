# SmartEdu Telu — Implementation Roadmap

> **Versi:** 1.0
> **Tanggal:** 2026-04-09
> **Estimasi Total Fase:** 15 fase
> **Pendekatan:** Iteratif, setiap fase menghasilkan deliverable yang bisa di-test

---

## Prinsip Pengembangan

1. **Vertical Slice** — Setiap fase mendeliver feature end-to-end (entity → repo → service → controller → FE page)
2. **Incremental Migration** — Flyway migration sudah lengkap (V1-V12, 68 tabel). Tidak perlu schema baru kecuali ada perubahan bisnis
3. **DDD Bounded Contexts** — Kode diorganisasi per domain, bukan per layer
4. **Contract First** — API endpoint didefinisikan dulu (lihat 03-API-ENDPOINTS.md), baru implementasi
5. **Test as You Go** — Setiap service dan controller punya unit + integration test

---

## Dependency Graph

```
Phase 1 (Auth & Core)
    │
    ├── Phase 2 (User Management)
    │     │
    │     ├── Phase 3 (Roles & Permissions)
    │     │     │
    │     │     └── Phase 4 (Tenants & Orgs)
    │     │
    │     └── Phase 5 (Exam Categories)
    │           │
    │           ├── Phase 6 (Question Bank) ──┐
    │           │                              │
    │           └── Phase 7 (Exam CRUD) ───────┤
    │                 │                        │
    │                 ├── Phase 8 (Scheduling)  │
    │                 │     │                   │
    │                 │     └── Phase 9 (Student Exam Flow)
    │                 │           │
    │                 │           ├── Phase 10 (Proctoring)
    │                 │           │
    │                 │           └── Phase 11 (Grading & Results)
    │                 │                 │
    │                 │                 └── Phase 12 (Certificates)
    │                 │
    │                 └── Phase 8 (Scheduling)
    │
    Phase 13 (Notifications & Calendar) ← Bisa paralel dari Phase 2
    Phase 14 (Gamification & Billing) ← Setelah Phase 11
    Phase 15 (Support & Admin) ← Setelah Phase 2
```

---

## Phase 1: Auth & Core Infrastructure

**Prioritas:** 🔴 CRITICAL
**Dependensi:** Tidak ada (fondasi)
**Tables:** `users`, `user_sessions` + common infra

### Backend Tasks

| # | Task | Detail | Status |
|---|------|--------|--------|
| 1.1 | Fix `CustomUserDetailsService` | Ganti stub `UnsupportedOperationException` → query `users` table by email. Load role sebagai GrantedAuthority | 🔲 |
| 1.2 | Fix JWT property path | `application.yaml` pakai `spring.application.jwt.*` tapi `JwtUtil` baca `application.security.jwt.*`. Seragamkan | 🔲 |
| 1.3 | Entity: `User`, `UserSession` | JPA entities mapping ke tabel `users` dan `user_sessions` | 🔲 |
| 1.4 | Repository: `UserRepository` | `findByEmail()`, `existsByEmail()` | 🔲 |
| 1.5 | DTO: `LoginRequest`, `RegisterRequest`, `LoginResponse`, `UserResponse` | | 🔲 |
| 1.6 | Service: `AuthService` | `register()`, `login()`, `refreshToken()`, `forgotPassword()`, `resetPassword()` | 🔲 |
| 1.7 | Controller: `AuthController` | 11 endpoints di `/api/v1/auth/**` | 🔲 |
| 1.8 | Password encoder integration | BCrypt (sudah di SecurityConfig) | 🔲 |
| 1.9 | Email service (forgot password) | `EmailService` pakai Spring Mail + Mailpit (dev) | 🔲 |
| 1.10 | Tests | Unit test AuthService, Integration test AuthController | 🔲 |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 1.11 | Login page integration | Connect `LoginPage.tsx` ke `POST /api/v1/auth/login`, store JWT di Zustand |
| 1.12 | Register page integration | Connect `RegisterPage.tsx` ke `POST /api/v1/auth/register` |
| 1.13 | Auth store | Extend `auth.store.ts`: token management, auto-refresh, logout |
| 1.14 | API interceptor | Axios/fetch interceptor: attach Bearer token, handle 401 → refresh |
| 1.15 | Protected routes | TanStack Router guard: redirect to login if no token |

### Deliverable
- ✅ User bisa register, login, logout
- ✅ JWT auth bekerja end-to-end
- ✅ Password reset via email
- ✅ Protected routes di FE

---

## Phase 2: User Management

**Prioritas:** 🔴 CRITICAL
**Dependensi:** Phase 1

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 2.1 | Entity: `User` extensions | Tambah field lengkap: phone, locale, timezone, status, picture |
| 2.2 | Service: `UserService` | CRUD, search/filter, status management, pagination |
| 2.3 | Controller: `UserController` | 8 endpoints di `/api/v1/users` |
| 2.4 | Specification/Criteria query | Dynamic filter: search, status, role |
| 2.5 | Tests | Unit + Integration |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 2.6 | User list page | Connect `UserListPage.tsx`, gunakan `Table.tsx` + pagination |
| 2.7 | User create/edit modal | Form modal, validasi FE |
| 2.8 | Teachers page | Connect `TeachersPage.tsx` (filter user by role=teacher) |
| 2.9 | Profile page | Edit profile sendiri (`/api/v1/auth/me`) |

### Deliverable
- ✅ Admin bisa CRUD user
- ✅ Search, filter, pagination bekerja
- ✅ Activate/suspend user

---

## Phase 3: Roles & Permissions (RBAC)

**Prioritas:** 🟠 HIGH
**Dependensi:** Phase 2

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 3.1 | Entity: `Role`, `Permission`, `RolePermission`, `UserRole` | |
| 3.2 | Repository: `RoleRepository`, `PermissionRepository` | |
| 3.3 | Service: `RoleService` | CRUD role, assign permissions |
| 3.4 | Controller: `RoleController` | 7 endpoints |
| 3.5 | Integrate `@PreAuthorize` | Dynamic permission check dari DB (bukan hardcode) |
| 3.6 | Seed data | Insert default roles: admin, teacher, student, proctor |
| 3.7 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 3.8 | Role management page | CRUD role + assign permission (checkbox matrix) |
| 3.9 | Update `rbac.ts` | Load permissions dari API, permission-based UI rendering |

### Deliverable
- ✅ Dynamic RBAC dari database
- ✅ `@PreAuthorize("hasPermission('exam:create')")` bekerja
- ✅ UI conditional rendering berdasar permission

---

## Phase 4: Tenants & Organizations

**Prioritas:** 🟠 HIGH
**Dependensi:** Phase 3

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 4.1 | Entity: `Tenant`, `TenantUser`, `Organization`, `OrganizationUser` | |
| 4.2 | Service: `TenantService`, `OrganizationService` | |
| 4.3 | Controller: `TenantController` | 13 endpoints |
| 4.4 | Multi-tenant filter | `@TenantScope` annotation / Hibernate filter |
| 4.5 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 4.6 | Tenant management page | Tree view organisasi |
| 4.7 | User assignment | Drag-drop atau modal assign user ke org |

### Deliverable
- ✅ Multi-tenant data isolation
- ✅ Organisasi hierarchy
- ✅ User affiliasi ke tenant/org

---

## Phase 5: Exam Categories

**Prioritas:** 🟡 MEDIUM
**Dependensi:** Phase 2

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 5.1 | Entity: `ExamCategory` (self-referencing tree) | |
| 5.2 | Service: `ExamCategoryService` | CRUD + tree traversal |
| 5.3 | Controller: `ExamCategoryController` | 5 endpoints |
| 5.4 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 5.5 | Category tree component | Recursive tree view + CRUD inline |

### Deliverable
- ✅ Kategori ujian hierarki berfungsi

---

## Phase 6: Question Bank

**Prioritas:** 🔴 CRITICAL
**Dependensi:** Phase 5

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 6.1 | Entity: `Question`, `QuestionOption`, `QuestionAttachment`, `QuestionCategory`, `QuestionFolder` | |
| 6.2 | Service: `QuestionService`, `QuestionFolderService`, `QuestionCategoryService` | |
| 6.3 | Controller: `QuestionController` | 18 endpoints |
| 6.4 | File upload | Multipart upload untuk question attachments |
| 6.5 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 6.6 | Question bank page | Connect `QuestionBankPage.tsx`, folder sidebar + grid/list view |
| 6.7 | Question editor | Form per question type (MCQ, essay, true/false, fill-blank) |
| 6.8 | Rich text integration | Gunakan `Rich_text_editor.tsx` untuk question text |

### Deliverable
- ✅ Teacher bisa CRUD soal dengan berbagai tipe
- ✅ Folder & kategori organisasi
- ✅ Attachment support (gambar, audio, video)

---

## Phase 7: Exam Management (CRUD)

**Prioritas:** 🔴 CRITICAL
**Dependensi:** Phase 5, Phase 6

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 7.1 | Entity: `Exam`, `ExamSection`, `ExamQuestion`, `ExamRegistration` | |
| 7.2 | Service: `ExamService` | CRUD, publish/archive lifecycle, section/question management |
| 7.3 | Controller: `ExamController` | 19 endpoints |
| 7.4 | State machine | Draft → Published → Archived (validasi transisi) |
| 7.5 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 7.6 | Exam list page | Connect `ExamListPage.tsx`, status tabs, filter |
| 7.7 | Exam wizard (multi-step) | Step 1: Info → Step 2: Config → Step 3: Section → Step 4: Soal → Step 5: Review |
| 7.8 | Section builder | Drag-drop soal ke section |

### Deliverable
- ✅ Teacher bisa buat ujian lengkap (multi-step wizard)
- ✅ Section & question management
- ✅ Publish/archive lifecycle

---

## Phase 8: Scheduling

**Prioritas:** 🟠 HIGH
**Dependensi:** Phase 7

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 8.1 | Entity: `ExamSchedule`, `ExamRoom` | |
| 8.2 | Service: `ScheduleService`, `ExamRoomService` | |
| 8.3 | Controller: `ScheduleController`, `ExamRoomController` | 9 endpoints |
| 8.4 | Conflict detection | Cek overlap jadwal per room/student |
| 8.5 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 8.6 | Schedule manager | Calendar view + form buat jadwal |
| 8.7 | Room management (Admin) | CRUD ruang ujian |

### Deliverable
- ✅ Penjadwalan ujian dengan conflict detection
- ✅ Room assignment

---

## Phase 9: Student Exam Flow ⭐

**Prioritas:** 🔴 CRITICAL
**Dependensi:** Phase 7, Phase 8

Ini adalah fase terpenting — experience student mengerjakan ujian.

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 9.1 | Entity: `ExamSession`, `ExamAttempt`, `StudentAnswer` | |
| 9.2 | Service: `StudentExamService` | Register, start, answer, submit, history |
| 9.3 | Controller: `StudentExamController` | 15 endpoints di `/api/v1/my-exams` |
| 9.4 | Timer management | Server-side timer, auto-submit saat habis |
| 9.5 | Answer auto-save | Save per jawaban, resume jika koneksi putus |
| 9.6 | Randomization | Shuffle questions & options berdasar exam config |
| 9.7 | Auto-grading (MCQ) | Hitung skor otomatis untuk pilihan ganda |
| 9.8 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 9.9 | Available exams page | Connect `AvailableExamsPage.tsx`, card grid |
| 9.10 | Exam detail + register | Info ujian + tombol daftar |
| 9.11 | Exam taking interface | Full-screen exam UI: timer, navigation, answer input |
| 9.12 | Auto-save mechanism | Debounced save saat student jawab |
| 9.13 | Result page | Skor, breakdown per section |
| 9.14 | Exam history | Connect `ExamHistoryPage.tsx` |

### Deliverable
- ✅ Student bisa daftar, mulai, dan mengerjakan ujian
- ✅ Auto-save, timer, randomization bekerja
- ✅ MCQ auto-graded, essay menunggu manual grading
- ✅ History dan result review

---

## Phase 10: Proctoring

**Prioritas:** 🟡 MEDIUM
**Dependensi:** Phase 9

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 10.1 | Entity: `ProctoringSession`, `CheatingLog`, `ProctorAssignment` | |
| 10.2 | Service: `ProctoringService` | Monitor, log, terminate |
| 10.3 | Controller: `ProctoringController` | 5 endpoints |
| 10.4 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 10.5 | Proctor dashboard | Live session monitoring |
| 10.6 | Anti-cheat detection | Tab switch, copy-paste, fullscreen exit detection |
| 10.7 | Terminate action | Confirm + terminate sesi |

### Deliverable
- ✅ Teacher/proctor bisa monitor sesi live
- ✅ Cheating event logging
- ✅ Force terminate capability

---

## Phase 11: Grading & Results

**Prioritas:** 🔴 CRITICAL
**Dependensi:** Phase 9

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 11.1 | Entity: `ExamResult`, `GradingRubric`, `RubricCriteria`, `Appeal` | |
| 11.2 | Service: `GradingService` | Manual grade, finalize, publish, appeal |
| 11.3 | Controller: `GradingController` | 8 endpoints |
| 11.4 | Score calculation | Weighted score across sections |
| 11.5 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 11.6 | Grading interface | Side-by-side: soal + jawaban + rubrik + input skor |
| 11.7 | Result publication | Batch publish results |
| 11.8 | Appeal management | List banding + resolve |

### Deliverable
- ✅ Teacher bisa grade essay per rubrik
- ✅ Score calculation & result publication
- ✅ Student bisa ajukan banding

---

## Phase 12: Certificates

**Prioritas:** 🟡 MEDIUM
**Dependensi:** Phase 11

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 12.1 | Entity: `Certificate`, `CertificateTemplate` | |
| 12.2 | Service: `CertificateService` | Template, issue, generate PDF |
| 12.3 | Controller: `CertificateController` | 7 endpoints |
| 12.4 | PDF generation | Library: iText atau Apache PDFBox |
| 12.5 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 12.6 | Certificate viewer | Preview + download |
| 12.7 | Template editor (Admin) | WYSIWYG template builder |

### Deliverable
- ✅ Generate sertifikat PDF
- ✅ Customizable template
- ✅ Student bisa download

---

## Phase 13: Notifications, Messages & Calendar

**Prioritas:** 🟠 HIGH
**Dependensi:** Phase 2 (bisa paralel dengan Phase 5+)

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 13.1 | Entity: `Notification`, `NotificationChannel`, `Message`, `CalendarEvent`, `Announcement` | |
| 13.2 | Service: `NotificationService`, `MessageService`, `CalendarService`, `AnnouncementService` | |
| 13.3 | Controllers | 4 controllers, ~19 endpoints total |
| 13.4 | Event-driven notifications | Spring Events / ApplicationEventPublisher |
| 13.5 | Email notification | Async email via Spring Mail |
| 13.6 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 13.7 | Notification bell | Badge count, dropdown list, mark read |
| 13.8 | Message inbox | Thread view per user |
| 13.9 | Calendar view | Month/week/day view, event integration |
| 13.10 | Announcements | List + detail view |

### Deliverable
- ✅ In-app + email notifications
- ✅ Direct messaging antar user
- ✅ Calendar terintegrasi dengan jadwal ujian
- ✅ Pengumuman (admin/teacher)

---

## Phase 14: Gamification & Billing

**Prioritas:** 🟢 LOW (Enhancement)
**Dependensi:** Phase 11 (Gamification), Phase 2 (Billing)

### Gamification

| # | Task | Detail |
|---|------|--------|
| 14.1 | Entity: `Badge`, `UserBadge`, `PointTransaction`, `PointBalance` | |
| 14.2 | Service: `GamificationService` | Award badges, calculate points, leaderboard |
| 14.3 | Controller: `GamificationController` | 8 endpoints |
| 14.4 | Trigger rules | Exam completed → +10pts, Perfect score → badge, Streak → badge |

### Billing

| # | Task | Detail |
|---|------|--------|
| 14.5 | Entity: `BillingPlan`, `Subscription`, `Transaction`, `Invoice`, `Coupon` | |
| 14.6 | Service: `BillingService`, `SubscriptionService` | |
| 14.7 | Controller: `BillingController` | 14 endpoints |
| 14.8 | Payment gateway integration | Midtrans / Xendit (placeholder) |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 14.9 | Achievement page | Badge grid, point history, leaderboard |
| 14.10 | Billing page | Plan selection, payment, invoice download |

### Deliverable
- ✅ Badge & point system
- ✅ Leaderboard
- ✅ Subscription plans & payment (placeholder)

---

## Phase 15: Support & Admin System

**Prioritas:** 🟡 MEDIUM
**Dependensi:** Phase 2

### Backend Tasks

| # | Task | Detail |
|---|------|--------|
| 15.1 | Entity: `SupportTicket`, `TicketMessage`, `TicketCategory` | |
| 15.2 | Entity: `AuditLog`, `ActivityLog`, `LoginLog` | |
| 15.3 | Entity: `FeatureFlag`, `SystemSetting`, `Webhook`, `WebhookLog` | |
| 15.4 | Service: `TicketService`, `AuditService`, `AdminService` | |
| 15.5 | Controllers | `TicketController`, `AdminController` — 21 endpoints |
| 15.6 | AOP audit logging | `@Auditable` annotation + aspect |
| 15.7 | Tests | |

### Frontend Tasks

| # | Task | Detail |
|---|------|--------|
| 15.8 | Support ticket page | Create, list, thread view |
| 15.9 | Admin settings page | Connect `SettingsPage.tsx`, feature flags, system settings |
| 15.10 | Audit log viewer | Searchable log table |
| 15.11 | Reports page | Connect `ReportsPage.tsx`, analytics dashboard |

### Deliverable
- ✅ Support ticket system
- ✅ Feature flags toggle
- ✅ Comprehensive audit logging
- ✅ Webhook system untuk integrasi eksternal

---

## Quick Reference: Phase Priorities

| Phase | Module | Priority | Depends On |
|:-----:|--------|:--------:|:----------:|
| 1 | Auth & Core | 🔴 CRITICAL | — |
| 2 | User Management | 🔴 CRITICAL | 1 |
| 3 | Roles & Permissions | 🟠 HIGH | 2 |
| 4 | Tenants & Orgs | 🟠 HIGH | 3 |
| 5 | Exam Categories | 🟡 MEDIUM | 2 |
| 6 | Question Bank | 🔴 CRITICAL | 5 |
| 7 | Exam Management | 🔴 CRITICAL | 5, 6 |
| 8 | Scheduling | 🟠 HIGH | 7 |
| 9 | Student Exam Flow | 🔴 CRITICAL | 7, 8 |
| 10 | Proctoring | 🟡 MEDIUM | 9 |
| 11 | Grading & Results | 🔴 CRITICAL | 9 |
| 12 | Certificates | 🟡 MEDIUM | 11 |
| 13 | Notifications & Calendar | 🟠 HIGH | 2 |
| 14 | Gamification & Billing | 🟢 LOW | 11, 2 |
| 15 | Support & Admin | 🟡 MEDIUM | 2 |

### Critical Path (MVP)

```
Phase 1 → Phase 2 → Phase 5 → Phase 6 → Phase 7 → Phase 8 → Phase 9 → Phase 11
```

Ini 8 fase yang harus selesai untuk **MVP (Minimum Viable Product)** — ujian bisa dibuat, dijadwalkan, dikerjakan, dan dinilai.

---

## Suggested Team Split (If Available)

| Stream | Phases | Focus |
|--------|--------|-------|
| **Stream A** (Core) | 1 → 2 → 3 → 4 | Auth, Users, RBAC, Multi-tenant |
| **Stream B** (Exam) | 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 | Full exam lifecycle |
| **Stream C** (Platform) | 13 → 14 → 15 | Notifications, Gamification, Admin |

Stream A dan B start paralel setelah Phase 1 selesai bersama. Stream C bisa dimulai setelah Phase 2.

---

## Technology Checklist per Phase

| Concern | Library/Tool | First Used In |
|---------|-------------|:-------------:|
| JPA Entities | Spring Data JPA + Hibernate | Phase 1 |
| DTO Mapping | ModelMapper (sudah dikonfigurasi) | Phase 1 |
| Validation | Jakarta Validation (`@Valid`, `@NotBlank`) | Phase 1 |
| Pagination | `Pageable` + `PageResponse<T>` | Phase 2 |
| Dynamic Filter | JPA Specification / Criteria API | Phase 2 |
| File Upload | Spring `MultipartFile` | Phase 6 |
| PDF Generation | iText 7 atau Apache PDFBox | Phase 12 |
| Event System | `ApplicationEventPublisher` | Phase 13 |
| Async Email | `@Async` + Spring Mail | Phase 1 |
| Redis Cache | `@Cacheable`, `RedisTemplate` | Phase 2+ |
| Audit Logging | Spring AOP + `@Auditable` | Phase 15 |
| WebSocket | Spring WebSocket (opsional proctoring live) | Phase 10 |
