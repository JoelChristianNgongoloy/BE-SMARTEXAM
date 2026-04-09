# SmartEdu Telu — Arsitektur Sistem

> **Versi:** 1.0
> **Tanggal:** 2026-04-09
> **Author:** JiilanTj

---

## 1. Gambaran Umum

**SmartEdu Telu** adalah platform manajemen ujian (exam management) berbasis web yang dirancang
untuk institusi pendidikan. Sistem ini bukan LMS (Learning Management System) biasa —
fokusnya **exam-centric**, bukan course-centric.

Fitur utama:
- Pembuatan & pengelolaan bank soal (Question Bank)
- Konfigurasi ujian fleksibel (MCQ, essay, matching, dll)
- Penjadwalan & pendaftaran ujian
- Proctoring & monitoring real-time
- Auto-grading (MCQ/T-F) + manual grading (essay dengan rubrik)
- Sertifikat otomatis
- Gamifikasi (badge, poin, leaderboard)
- Billing & subscription
- Multi-tenant (banyak institusi dalam 1 platform)

---

## 2. Tech Stack

### Backend
| Komponen | Teknologi | Versi |
|----------|-----------|-------|
| Framework | Spring Boot | 4.0.5 |
| Bahasa | Java | 21 (Eclipse Temurin) |
| Database | PostgreSQL | 17-alpine |
| Cache/Session | Redis | 7-alpine |
| ORM | Spring Data JPA (Hibernate) | — |
| Migration | Flyway | — |
| Auth | Spring Security + JWT (jjwt) | 0.11.5 |
| API Docs | springdoc-openapi (Swagger UI) | 2.5.0 |
| Object Mapper | ModelMapper | 3.2.0 |
| Boilerplate | Lombok | — |
| Mail | Spring Mail (SMTP) | — |
| Build Tool | Maven | — |
| Container | Docker + Docker Compose | — |

### Frontend (referensi)
| Komponen | Teknologi | Versi |
|----------|-----------|-------|
| Framework | React | 19 |
| Bahasa | TypeScript | 5.9 |
| Build Tool | Vite | 8.0 |
| Routing | TanStack Router | 1.168 |
| State | Zustand | 5.0 |
| Styling | Tailwind CSS | 4.2 |
| Forms | React Hook Form + Zod | — |
| HTTP Client | Ky | 1.14 |

---

## 3. Arsitektur Overview

```
┌──────────────────────────────────────────────────────────────┐
│                        CLIENT (Browser)                      │
│                     React SPA (smartedu-fe)                  │
└──────────────────────┬───────────────────────────────────────┘
                       │ HTTPS / REST API
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                   SPRING BOOT APPLICATION                    │
│                      (besmartedutelu)                        │
│                                                              │
│  ┌────────────┐  ┌─────────────┐  ┌───────────────────────┐ │
│  │ Controller │→ │   Service   │→ │     Repository        │ │
│  │  (REST)    │  │  (Business  │  │  (Spring Data JPA)    │ │
│  │            │  │   Logic)    │  │                       │ │
│  └────────────┘  └─────────────┘  └───────────┬───────────┘ │
│                                                │             │
│  ┌────────────────────────────────┐            │             │
│  │   Security Filter Chain        │            │             │
│  │   JWT → Auth → Authorization   │            │             │
│  └────────────────────────────────┘            │             │
└────────────────────────────────────────────────┼─────────────┘
                       │                         │
              ┌────────┘                         │
              ▼                                  ▼
   ┌──────────────────┐              ┌──────────────────────┐
   │      Redis       │              │    PostgreSQL 17     │
   │  (Cache/Session) │              │   (68 tabel, UUID)   │
   └──────────────────┘              └──────────────────────┘
```

---

## 4. Domain-Driven Design (DDD)

Sistem dibagi menjadi **15 Bounded Context** yang dikelompokkan dalam 2 tier:

### 4.1 Core Domains (9 context)

Domain yang **esensial** untuk fungsi utama platform ujian.

| # | Bounded Context | Package | Tabel | Deskripsi |
|---|----------------|---------|-------|-----------|
| 1 | **Identity** | `domain.identity` | 7 | Akun user, RBAC (roles & permissions), session login, reset password |
| 2 | **Tenant** | `domain.tenant` | 4 | Multi-tenancy: institusi, fakultas/jurusan, keanggotaan |
| 3 | **Exam** | `domain.exam` | 4 | Ujian, kategori ujian (tree), section, mapping soal-ke-section |
| 4 | **Question Bank** | `domain.questionbank` | 7 | Bank soal: folder (tree), kategori, soal, opsi jawaban, attachment, rubrik |
| 5 | **Scheduling** | `domain.scheduling` | 4 | Jadwal ujian, ruang ujian, pendaftaran peserta, kalender |
| 6 | **Session** | `domain.session` | 3 | Sesi ujian aktif, penugasan proctor, log kecurangan |
| 7 | **Evaluation** | `domain.evaluation` | 2 | Attempt & jawaban peserta |
| 8 | **Result** | `domain.result` | 3 | Hasil resmi, banding/appeal, analitik agregat |
| 9 | **Certificate** | `domain.certificate` | 2 | Template sertifikat, sertifikat terbit |

### 4.2 Supporting Domains (6 context)

Domain **pendukung** yang memperkaya platform tapi bukan inti ujian.

| # | Bounded Context | Package | Tabel | Deskripsi |
|---|----------------|---------|-------|-----------|
| 10 | **Communication** | `domain.communication` | 6 | Pengumuman, notifikasi, pesan langsung antar user |
| 11 | **Gamification** | `domain.gamification` | 3 | Badge, poin, leaderboard |
| 12 | **Billing** | `domain.billing` | 6 | Paket langganan, transaksi, invoice, kupon |
| 13 | **Support** | `domain.support` | 5 | Tiket bantuan, kategori/prioritas/status tiket |
| 14 | **Media** | `domain.media` | 3 | Upload file, tag polymorphic |
| 15 | **Platform** | `domain.platform` | 9 | Audit log, activity log, login log, event sourcing, webhook, feature flag, settings |

### 4.3 Shared Kernel

| Package | Isi | Deskripsi |
|---------|-----|-----------|
| `common.config` | AuditingConfig, MapperConfiguration, OpenApiConfig | Konfigurasi lintas-domain |
| `common.dto` | ApiResponse, BaseDTO, PageResponse | DTO standar untuk semua response |
| `common.entity` | BaseEntity | Superclass JPA dengan audit fields (created_at/by, updated_at/by) |
| `common.enums` | ErrorCode | Kode error terpusat (SE-CMN-xxx, SE-AUT-xxx, SE-EXM-xxx) |
| `common.exception` | BusinessException, ResourceNotFoundException, dll | Exception hierarchy + GlobalExceptionHandler |
| `common.security` | JwtUtil, JwtAuthenticationFilter, dll | JWT auth, security utilities |
| `config` | SecurityConfig | Spring Security filter chain |

---

## 5. Package Structure (Target)

```
src/main/java/com/tujuhsembilan/smartedutelu/
│
├── SmarteduteluApplication.java
│
├── common/                                  ← SHARED KERNEL
│   ├── config/
│   │   ├── AuditingConfig.java
│   │   ├── MapperConfiguration.java
│   │   └── OpenApiConfig.java
│   ├── dto/
│   │   ├── ApiResponse.java
│   │   ├── BaseDTO.java
│   │   └── PageResponse.java
│   ├── entity/
│   │   └── BaseEntity.java
│   ├── enums/
│   │   └── ErrorCode.java
│   ├── exception/
│   │   ├── BusinessException.java
│   │   ├── CircularReferenceException.java
│   │   ├── DuplicateResourceException.java
│   │   ├── GlobalExceptionHandler.java
│   │   └── ResourceNotFoundException.java
│   └── security/
│       ├── CustomAccessDeniedHandler.java
│       ├── CustomAuthenticationEntryPoint.java
│       ├── CustomUserDetailsService.java
│       ├── JwtAuthenticationFilter.java
│       ├── JwtUtil.java
│       └── SecurityUtils.java
│
├── config/                                  ← APP-LEVEL CONFIG
│   └── SecurityConfig.java
│
└── domain/                                  ← BOUNDED CONTEXTS
    │
    ├── identity/                            ← BC 1: Identity & Auth
    │   ├── entity/
    │   │   ├── User.java
    │   │   ├── Role.java
    │   │   ├── Permission.java
    │   │   ├── UserRole.java
    │   │   ├── RolePermission.java
    │   │   ├── UserSession.java
    │   │   └── PasswordReset.java
    │   ├── repository/
    │   │   ├── UserRepository.java
    │   │   ├── RoleRepository.java
    │   │   ├── PermissionRepository.java
    │   │   └── UserSessionRepository.java
    │   ├── service/
    │   │   ├── AuthService.java
    │   │   ├── UserService.java
    │   │   └── RoleService.java
    │   ├── dto/
    │   │   ├── request/
    │   │   │   ├── LoginRequest.java
    │   │   │   ├── RegisterRequest.java
    │   │   │   ├── ForgotPasswordRequest.java
    │   │   │   ├── ResetPasswordRequest.java
    │   │   │   ├── ChangePasswordRequest.java
    │   │   │   ├── CreateUserRequest.java
    │   │   │   └── UpdateUserRequest.java
    │   │   └── response/
    │   │       ├── LoginResponse.java
    │   │       ├── UserResponse.java
    │   │       └── RoleResponse.java
    │   └── controller/
    │       ├── AuthController.java          POST /api/v1/auth/**
    │       ├── UserController.java          GET|POST|PUT|DELETE /api/v1/users/**
    │       └── RoleController.java          GET|POST|PUT|DELETE /api/v1/roles/**
    │
    ├── tenant/                              ← BC 2: Multi-Tenancy
    │   ├── entity/
    │   │   ├── Tenant.java
    │   │   ├── TenantUser.java
    │   │   ├── Organization.java
    │   │   └── OrganizationUser.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── TenantController.java        /api/v1/tenants/**
    │       └── OrganizationController.java  /api/v1/tenants/{id}/organizations/**
    │
    ├── exam/                                ← BC 3: Exam Management
    │   ├── entity/
    │   │   ├── ExamCategory.java
    │   │   ├── Exam.java
    │   │   ├── ExamSection.java
    │   │   └── ExamQuestion.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── ExamCategoryController.java  /api/v1/exam-categories/**
    │       └── ExamController.java          /api/v1/exams/**
    │
    ├── questionbank/                        ← BC 4: Question Bank
    │   ├── entity/
    │   │   ├── QuestionBankFolder.java
    │   │   ├── QuestionCategory.java
    │   │   ├── Question.java
    │   │   ├── Option.java
    │   │   ├── QuestionAttachment.java
    │   │   ├── GradingRubric.java
    │   │   └── RubricCriteria.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── QuestionController.java      /api/v1/questions/**
    │       ├── QuestionFolderController.java /api/v1/questions/folders/**
    │       └── RubricController.java        /api/v1/rubrics/**
    │
    ├── scheduling/                          ← BC 5: Scheduling & Registration
    │   ├── entity/
    │   │   ├── ExamSchedule.java
    │   │   ├── ExamRoom.java
    │   │   ├── ExamRegistration.java
    │   │   └── CalendarEvent.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── ScheduleController.java      /api/v1/schedules/**
    │       ├── ExamRoomController.java      /api/v1/exam-rooms/**
    │       └── CalendarController.java      /api/v1/calendar/**
    │
    ├── session/                             ← BC 6: Exam Session & Proctoring
    │   ├── entity/
    │   │   ├── ExamSession.java
    │   │   ├── ProctorAssignment.java
    │   │   └── CheatingLog.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── StudentExamController.java   /api/v1/my-exams/**
    │       └── ProctoringController.java    /api/v1/proctoring/**
    │
    ├── evaluation/                          ← BC 7: Evaluation & Grading
    │   ├── entity/
    │   │   ├── ExamAttempt.java
    │   │   └── ExamAttemptAnswer.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       └── GradingController.java       /api/v1/grading/**
    │
    ├── result/                              ← BC 8: Results & Analytics
    │   ├── entity/
    │   │   ├── ExamResult.java
    │   │   ├── ExamAppeal.java
    │   │   └── ExamAnalytics.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       └── ResultController.java        /api/v1/results/**
    │
    ├── certificate/                         ← BC 9: Certificates
    │   ├── entity/
    │   │   ├── CertificateTemplate.java
    │   │   └── Certificate.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       └── CertificateController.java   /api/v1/certificates/**
    │
    ├── communication/                       ← BC 10: Communication
    │   ├── entity/
    │   │   ├── Announcement.java
    │   │   ├── AnnouncementAttachment.java
    │   │   ├── Notification.java
    │   │   ├── NotificationChannel.java
    │   │   ├── Message.java
    │   │   └── MessageAttachment.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── AnnouncementController.java  /api/v1/announcements/**
    │       ├── NotificationController.java  /api/v1/notifications/**
    │       └── MessageController.java       /api/v1/messages/**
    │
    ├── gamification/                        ← BC 11: Gamification
    │   ├── entity/
    │   │   ├── Badge.java
    │   │   ├── UserBadge.java
    │   │   └── Point.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       └── GamificationController.java  /api/v1/gamification/**
    │
    ├── billing/                             ← BC 12: Billing & Subscription
    │   ├── entity/
    │   │   ├── Plan.java
    │   │   ├── Subscription.java
    │   │   ├── Transaction.java
    │   │   ├── Invoice.java
    │   │   ├── Coupon.java
    │   │   └── CouponUsage.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       └── BillingController.java       /api/v1/billing/**
    │
    ├── support/                             ← BC 13: Support Tickets
    │   ├── entity/
    │   │   ├── TicketCategory.java
    │   │   ├── TicketPriority.java
    │   │   ├── TicketStatus.java
    │   │   ├── Ticket.java
    │   │   └── TicketMessage.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       └── TicketController.java        /api/v1/tickets/**
    │
    ├── media/                               ← BC 14: Media & Tags
    │   ├── entity/
    │   │   ├── MediaFile.java
    │   │   ├── Tag.java
    │   │   └── Taggable.java
    │   ├── repository/
    │   ├── service/
    │   ├── dto/
    │   └── controller/
    │       ├── MediaController.java         /api/v1/media/**
    │       └── TagController.java           /api/v1/tags/**
    │
    └── platform/                            ← BC 15: System & Audit
        ├── entity/
        │   ├── Event.java
        │   ├── ActivityLog.java
        │   ├── AuditLog.java
        │   ├── LoginLog.java
        │   ├── Webhook.java
        │   ├── WebhookLog.java
        │   ├── FeatureFlag.java
        │   ├── Setting.java
        │   └── UserPreference.java
        ├── repository/
        ├── service/
        ├── dto/
        └── controller/
            ├── AdminController.java         /api/v1/admin/**
            └── DashboardController.java     /api/v1/dashboard/**
```

---

## 6. Alur Request (Request Lifecycle)

```
1. Client mengirim HTTP request
        │
        ▼
2. JwtAuthenticationFilter
   ├── Cek header "Authorization: Bearer xxx"
   ├── Extract username dari JWT
   ├── Load UserDetails dari DB via CustomUserDetailsService
   ├── Validasi token (expiry, signature)
   └── Set SecurityContext (authenticated)
        │
        ▼
3. SecurityConfig (SecurityFilterChain)
   ├── Public endpoints → langsung lolos
   │   • /api/v1/auth/login, /api/v1/auth/register
   │   • /swagger-ui/**, /v3/api-docs/**
   ├── Protected endpoints → cek authenticated
   └── Jika tidak valid → CustomAuthenticationEntryPoint (401)
        │
        ▼
4. Controller
   ├── @PreAuthorize("hasRole('ADMIN')") → method-level auth
   ├── Validasi request body via @Valid + Jakarta Validation
   └── Panggil Service layer
        │
        ▼
5. Service
   ├── Business logic
   ├── Panggil Repository
   ├── Lempar BusinessException jika ada error
   └── Return DTO
        │
        ▼
6. Repository (Spring Data JPA)
   ├── Query ke PostgreSQL via Hibernate
   └── Return Entity
        │
        ▼
7. Response
   ├── Sukses → ApiResponse.success(data)
   ├── Error → GlobalExceptionHandler → ApiResponse.error(...)
   └── Format:
       {
         "success": true/false,
         "message": "...",
         "data": { ... },
         "error": { "code": "SE-XXX-001", "message": "...", "detail": "..." },
         "timestamp": "2026-04-09T10:30:00"
       }
```

---

## 7. Security Model

### 7.1 Authentication
- **Metode:** JWT (JSON Web Token) via `Authorization: Bearer <token>`
- **Library:** jjwt 0.11.5
- **Algoritma:** HMAC-SHA256
- **Expiry:** 24 jam (86400000 ms, configurable)
- **Stateless:** Tidak ada server-side session (session management via Redis opsional)

### 7.2 Authorization (RBAC)
- **3 Role utama:** `admin`, `teacher`, `student`
- **Granular permissions:** `exam:create`, `exam:read`, `result:view`, dll
- **Level enforcement:**
  - **Route level:** SecurityConfig (authenticated vs public)
  - **Method level:** `@PreAuthorize("hasRole('ADMIN')")` di controller
  - **Data level:** Filter by tenant_id / created_by di query

### 7.3 Multi-Tenancy
- Setiap data penting ter-scope ke `tenant_id`
- User bisa tergabung di >1 tenant via `tenant_users`
- Dalam 1 tenant, user bisa masuk >1 organisasi via `organization_users`

---

## 8. Infrastruktur & Deployment

### Docker Compose Services

| Service | Image | Port | Profile | Fungsi |
|---------|-------|------|---------|--------|
| `app` | Custom (Dockerfile) | 8080 | default | Spring Boot application |
| `postgres` | postgres:17-alpine | 5432 | default | Database utama |
| `redis` | redis:7-alpine | 6379 | default | Cache & session store |
| `pgadmin` | dpage/pgadmin4 | 5050 | dev | Database GUI admin |
| `redisinsight` | redis/redisinsight | 5540 | dev | Redis GUI |
| `mailpit` | axllent/mailpit | 8025/1025 | dev | Local SMTP testing |

### Dockerfile
- **Multi-stage build:** Build stage (JDK 21) → Runtime stage (JRE 21)
- **Non-root user:** App berjalan sebagai `appuser` (bukan root)
- **JVM tuning:** Container-aware memory settings (`-XX:MaxRAMPercentage=75.0`)

### Makefile (PowerShell-compatible)
- `make env` — Setup .env file
- `make infra-up` — Start PostgreSQL + Redis
- `make dev-up` — Start semua termasuk dev tools
- `make migrate` — Jalankan semua Flyway migration via psql
- `make up` — Full stack (build + run)
- `make down` — Stop semua container
- `make logs` — Tail semua logs

---

## 9. Standar Response API

### Sukses
```json
{
  "success": true,
  "message": "Exam berhasil dibuat",
  "data": { "id": "uuid-here", "title": "UTS Matematika" },
  "timestamp": "2026-04-09T10:30:00"
}
```

### Sukses (paginated)
```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": {
    "content": [ ... ],
    "pagination": {
      "page": 0,
      "size": 20,
      "totalElements": 150,
      "totalPages": 8,
      "first": true,
      "last": false,
      "hasNext": true,
      "hasPrevious": false
    }
  },
  "timestamp": "2026-04-09T10:30:00"
}
```

### Error
```json
{
  "success": false,
  "message": "Operation failed",
  "error": {
    "code": "SE-EXM-001",
    "message": "Exam not found",
    "detail": "Exam with identifier '550e8400-...' not found"
  },
  "timestamp": "2026-04-09T10:30:00"
}
```

### Validation Error
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "title": "must not be blank",
    "pass_percentage": "must be between 0 and 100"
  },
  "error": {
    "code": "SE-CMN-006",
    "message": "Validation error",
    "detail": "Found 2 validation error(s)"
  },
  "timestamp": "2026-04-09T10:30:00"
}
```
