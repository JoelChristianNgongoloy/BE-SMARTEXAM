# SmartEdu Telu — API Endpoints Blueprint

> **Versi:** 1.0
> **Tanggal:** 2026-04-09
> **Base URL:** `/api`
> **Auth:** `Authorization: Bearer <JWT>`
> **Format Response:** `ApiResponse<T>` (lihat 01-ARCHITECTURE.md §9)

---

## Convention

- Semua endpoint di bawah prefix `/api`
- Versioning di URL: `/api/v1/...`
- Pagination: `?page=0&size=20&sort=createdAt,desc`
- Search/Filter: `?search=keyword&status=active&type=standard`
- Response selalu wrapped dalam `ApiResponse<T>`
- Error code mengikuti format `SE-{DOMAIN}-{SEQ}` (lihat `ErrorCode.java`)

### HTTP Status Codes

| Code | Penggunaan |
|------|-----------|
| `200` | OK — GET, PUT berhasil |
| `201` | Created — POST berhasil membuat resource baru |
| `204` | No Content — DELETE berhasil |
| `400` | Bad Request — Validasi gagal, business rule violation |
| `401` | Unauthorized — Token tidak valid / tidak ada |
| `403` | Forbidden — Tidak punya akses |
| `404` | Not Found — Resource tidak ditemukan |
| `409` | Conflict — Duplikat resource |
| `500` | Internal Server Error |

### Role Singkatan

| Label | Artinya |
|-------|---------|
| **Public** | Tanpa auth |
| **All** | Semua role yang sudah login |
| **A** | Admin |
| **T** | Teacher |
| **S** | Student |
| **A,T** | Admin atau Teacher |
| **Owner** | Pemilik resource (created_by = current user) |

---

## Module 1: Auth

**Base path:** `/api/v1/auth`

Auth module menangani registrasi, login, token refresh, password management, dan profile user yang sedang login.

| # | Method | Endpoint | Role | Deskripsi | Request Body | Response |
|---|--------|----------|------|-----------|-------------|----------|
| 1 | POST | `/register` | Public | Registrasi user baru | `{ name, email, password, phone? }` | `UserResponse` |
| 2 | POST | `/login` | Public | Login → dapat JWT token | `{ email, password }` | `{ token, refreshToken, user }` |
| 3 | POST | `/logout` | All | Invalidasi session aktif | — | `{ message }` |
| 4 | POST | `/refresh-token` | All | Refresh JWT yang hampir expired | `{ refreshToken }` | `{ token, refreshToken }` |
| 5 | POST | `/forgot-password` | Public | Kirim email reset password | `{ email }` | `{ message }` |
| 6 | POST | `/reset-password` | Public | Reset password pakai token | `{ token, newPassword }` | `{ message }` |
| 7 | GET | `/me` | All | Get profil user yang login | — | `UserResponse` |
| 8 | PUT | `/me` | All | Update profil sendiri | `{ name, phone?, picture?, locale?, timezone? }` | `UserResponse` |
| 9 | PUT | `/me/password` | All | Ganti password sendiri | `{ currentPassword, newPassword }` | `{ message }` |
| 10 | GET | `/me/sessions` | All | List sesi aktif (multi-device) | — | `List<SessionResponse>` |
| 11 | DELETE | `/me/sessions/{id}` | All | Revoke sesi tertentu | — | 204 |

### Detail DTO

**LoginRequest:**
```json
{
  "email": "admin@smartexam.com",
  "password": "admin123"
}
```

**LoginResponse:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.xxx",
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9.yyy",
  "user": {
    "id": "uuid",
    "name": "Admin User",
    "email": "admin@smartexam.com",
    "role": "admin",
    "picture": null,
    "locale": "id",
    "timezone": "Asia/Jakarta"
  }
}
```

**RegisterRequest:**
```json
{
  "name": "John Doe",
  "email": "john@telkom.ac.id",
  "password": "Str0ngP@ss!",
  "phone": "+6281234567890"
}
```

---

## Module 2: User Management

**Base path:** `/api/v1/users`

Admin mengelola semua user di platform.

| # | Method | Endpoint | Role | Deskripsi | Query Params |
|---|--------|----------|------|-----------|-------------|
| 1 | GET | `/` | A | List semua user (paginated) | `?search=&status=&role=&page=&size=&sort=` |
| 2 | GET | `/{id}` | A | Detail user | — |
| 3 | POST | `/` | A | Buat user baru (by admin) | — |
| 4 | PUT | `/{id}` | A | Update user | — |
| 5 | DELETE | `/{id}` | A | Soft delete user | — |
| 6 | PUT | `/{id}/status` | A | Ubah status (activate/suspend) | — |
| 7 | GET | `/{id}/roles` | A | Lihat role user | — |
| 8 | PUT | `/{id}/roles` | A | Assign/ubah role | — |

### Detail DTO

**CreateUserRequest:**
```json
{
  "name": "Jane Teacher",
  "email": "jane@telkom.ac.id",
  "password": "TempP@ss123",
  "phone": "+6281234567891",
  "roles": ["teacher"]
}
```

**UpdateStatusRequest:**
```json
{
  "status": "suspended"
}
```

**AssignRolesRequest:**
```json
{
  "roleIds": ["uuid-role-teacher", "uuid-role-proctor"]
}
```

---

## Module 3: Roles & Permissions

**Base path:** `/api/v1/roles`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | A | List semua role |
| 2 | POST | `/` | A | Buat role baru |
| 3 | PUT | `/{id}` | A | Update role |
| 4 | DELETE | `/{id}` | A | Hapus role |
| 5 | GET | `/{id}/permissions` | A | Lihat permission role |
| 6 | PUT | `/{id}/permissions` | A | Assign permission ke role |
| 7 | GET | `/permissions` | A | List semua permission |

---

## Module 4: Tenants & Organizations

**Base path:** `/api/v1/tenants`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | A | List tenants |
| 2 | POST | `/` | A | Buat tenant |
| 3 | PUT | `/{id}` | A | Update tenant |
| 4 | GET | `/{id}/users` | A | List anggota tenant |
| 5 | POST | `/{id}/users` | A | Tambah user ke tenant |
| 6 | DELETE | `/{id}/users/{userId}` | A | Keluarkan user dari tenant |
| 7 | GET | `/{id}/organizations` | A | List organisasi di tenant |
| 8 | POST | `/{id}/organizations` | A | Buat organisasi |
| 9 | PUT | `/{id}/organizations/{orgId}` | A | Update organisasi |
| 10 | DELETE | `/{id}/organizations/{orgId}` | A | Hapus organisasi |
| 11 | GET | `/{id}/organizations/{orgId}/users` | A | List anggota organisasi |
| 12 | POST | `/{id}/organizations/{orgId}/users` | A | Tambah user ke organisasi |
| 13 | DELETE | `/{id}/organizations/{orgId}/users/{userId}` | A | Keluarkan dari organisasi |

---

## Module 5: Exam Categories

**Base path:** `/api/v1/exam-categories`

Kategori ujian berbentuk tree (hierarki parent-child). Contoh:
- Akademik → Teknik → UTS Semester 1
- Non-Akademik → Sertifikasi → AWS Cloud Practitioner

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | A,T | List semua (tree structure) |
| 2 | GET | `/{id}` | A,T | Detail kategori + children |
| 3 | POST | `/` | A | Buat kategori |
| 4 | PUT | `/{id}` | A | Update kategori |
| 5 | DELETE | `/{id}` | A | Hapus kategori |

**CreateExamCategoryRequest:**
```json
{
  "name": "UTS Semester 1",
  "slug": "uts-semester-1",
  "description": "Ujian Tengah Semester 1",
  "parentId": "uuid-parent-or-null"
}
```

---

## Module 6: Exam Management

**Base path:** `/api/v1/exams`

Ini adalah module inti — membuat, mengonfigurasi, dan mengelola ujian beserta section dan soal-soalnya.

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | A,T | List ujian (filter: status, category, type, search) |
| 2 | GET | `/{id}` | A,T | Detail ujian + sections |
| 3 | POST | `/` | T | Buat ujian baru (status: draft) |
| 4 | PUT | `/{id}` | T/Owner | Update ujian |
| 5 | DELETE | `/{id}` | T/Owner, A | Soft delete ujian |
| 6 | PUT | `/{id}/publish` | T/Owner | Publish ujian (draft → published) |
| 7 | PUT | `/{id}/archive` | T/Owner, A | Archive ujian |
| | | | | |
| 8 | GET | `/{id}/sections` | A,T | List sections dalam ujian |
| 9 | POST | `/{id}/sections` | T/Owner | Buat section |
| 10 | PUT | `/{id}/sections/{sectionId}` | T/Owner | Update section |
| 11 | DELETE | `/{id}/sections/{sectionId}` | T/Owner | Hapus section |
| 12 | PUT | `/{id}/sections/reorder` | T/Owner | Reorder sections |
| | | | | |
| 13 | GET | `/{id}/sections/{sectionId}/questions` | T/Owner | List soal di section |
| 14 | POST | `/{id}/sections/{sectionId}/questions` | T/Owner | Tambahkan soal ke section |
| 15 | PUT | `/{id}/sections/{sectionId}/questions/{eqId}` | T/Owner | Update weight/position |
| 16 | DELETE | `/{id}/sections/{sectionId}/questions/{eqId}` | T/Owner | Hapus soal dari section |
| 17 | PUT | `/{id}/sections/{sectionId}/questions/reorder` | T/Owner | Reorder soal |
| | | | | |
| 18 | GET | `/{id}/registrations` | T/Owner, A | List pendaftaran peserta |
| 19 | GET | `/{id}/analytics` | T/Owner, A | Lihat analitik ujian |

### Detail DTO

**CreateExamRequest:**
```json
{
  "categoryId": "uuid-or-null",
  "title": "UTS Basis Data 2026",
  "description": "Ujian tengah semester mata kuliah Basis Data",
  "examType": "midterm",
  "timeLimitMinutes": 90,
  "maxAttempts": 1,
  "passPercentage": 60,
  "totalScore": 100,
  "randomQuestions": false,
  "randomAnswers": true,
  "showResultMode": "after_submit",
  "allowReview": true,
  "shuffleSections": false,
  "requireProctoring": true,
  "feedbackType": "summary",
  "instructions": "Kerjakan semua soal. Dilarang membuka tab lain."
}
```

**AddQuestionsToSectionRequest:**
```json
{
  "questions": [
    { "questionId": "uuid-q1", "weight": 1.0 },
    { "questionId": "uuid-q2", "weight": 2.0 },
    { "questionId": "uuid-q3", "weight": 1.5 }
  ]
}
```

---

## Module 7: Question Bank

**Base path:** `/api/v1/questions`

Bank soal dengan folder hierarki, kategori, dan management soal lengkap.

### Soal

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | T | List soal (filter: type, difficulty, category, folder, search) |
| 2 | GET | `/{id}` | T | Detail soal + options + attachments |
| 3 | POST | `/` | T | Buat soal baru |
| 4 | PUT | `/{id}` | T/Owner | Update soal |
| 5 | DELETE | `/{id}` | T/Owner | Hapus soal |

### Opsi Jawaban

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 6 | POST | `/{id}/options` | T | Tambah opsi jawaban |
| 7 | PUT | `/{id}/options/{optId}` | T | Update opsi |
| 8 | DELETE | `/{id}/options/{optId}` | T | Hapus opsi |

### Attachment

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 9 | POST | `/{id}/attachments` | T | Upload attachment (multipart) |
| 10 | DELETE | `/{id}/attachments/{attId}` | T | Hapus attachment |

### Folder

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 11 | GET | `/folders` | T | List folders (tree) |
| 12 | POST | `/folders` | T | Buat folder |
| 13 | PUT | `/folders/{id}` | T | Update folder |
| 14 | DELETE | `/folders/{id}` | T | Hapus folder |

### Kategori Soal

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 15 | GET | `/categories` | T | List kategori soal |
| 16 | POST | `/categories` | T | Buat kategori soal |
| 17 | PUT | `/categories/{id}` | T | Update kategori |
| 18 | DELETE | `/categories/{id}` | T | Hapus kategori |

### Detail DTO

**CreateQuestionRequest:**
```json
{
  "categoryId": "uuid-or-null",
  "folderId": "uuid-or-null",
  "questionText": "<p>Apa kepanjangan dari SQL?</p>",
  "description": null,
  "explanation": "SQL = Structured Query Language",
  "type": "multiple_choice",
  "points": 5,
  "difficultyLevel": "easy",
  "timeEstimateSeconds": 60,
  "isShared": false,
  "options": [
    { "optionText": "Structured Query Language", "isCorrect": true, "feedback": "Benar!" },
    { "optionText": "Simple Question Language", "isCorrect": false, "feedback": "Salah." },
    { "optionText": "Standard Query Logic", "isCorrect": false },
    { "optionText": "System Query Language", "isCorrect": false }
  ]
}
```

---

## Module 8: Grading Rubrics

**Base path:** `/api/v1/rubrics`

Rubrik penilaian untuk soal essay/open-ended.

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/question/{questionId}` | T | List rubrik untuk soal |
| 2 | POST | `/` | T | Buat rubrik |
| 3 | PUT | `/{id}` | T | Update rubrik |
| 4 | DELETE | `/{id}` | T | Hapus rubrik |
| 5 | POST | `/{id}/criteria` | T | Tambah kriteria |
| 6 | PUT | `/{id}/criteria/{criteriaId}` | T | Update kriteria |
| 7 | DELETE | `/{id}/criteria/{criteriaId}` | T | Hapus kriteria |

**CreateRubricRequest:**
```json
{
  "questionId": "uuid",
  "title": "Rubrik Penilaian Essay",
  "description": "Menilai kedalaman analisis",
  "maxScore": 20.0,
  "criteria": [
    { "criterion": "Pemahaman Konsep", "description": "Ketepatan teori", "maxScore": 8.0 },
    { "criterion": "Analisis", "description": "Kedalaman analisis", "maxScore": 7.0 },
    { "criterion": "Penyajian", "description": "Tata bahasa dan struktur", "maxScore": 5.0 }
  ]
}
```

---

## Module 9: Scheduling

**Base path:** `/api/v1/schedules`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | A,T | List jadwal (filter: examId, dateRange) |
| 2 | GET | `/{id}` | A,T | Detail jadwal |
| 3 | POST | `/` | T | Buat jadwal ujian |
| 4 | PUT | `/{id}` | T | Update jadwal |
| 5 | DELETE | `/{id}` | T | Hapus jadwal |

**CreateScheduleRequest:**
```json
{
  "examId": "uuid",
  "startTime": "2026-04-15T08:00:00+07:00",
  "endTime": "2026-04-15T10:00:00+07:00",
  "maxParticipants": 50,
  "location": "Lab Komputer A"
}
```

---

## Module 10: Exam Rooms

**Base path:** `/api/v1/exam-rooms`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | A | List ruang ujian |
| 2 | POST | `/` | A | Buat ruang |
| 3 | PUT | `/{id}` | A | Update ruang |
| 4 | DELETE | `/{id}` | A | Hapus ruang |

---

## Module 11: Student Exam (My Exams)

**Base path:** `/api/v1/my-exams`

Semua endpoint ini dilihat dari sudut pandang **student** yang sedang login.

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/available` | S | Ujian yang tersedia untuk saya |
| 2 | GET | `/{examId}` | S | Info ujian (instruksi, rules) |
| 3 | POST | `/{examId}/register` | S | Daftar ujian + pilih jadwal |
| 4 | GET | `/registrations` | S | List pendaftaran saya |
| 5 | DELETE | `/registrations/{id}` | S | Batal pendaftaran |
| | | | | |
| 6 | POST | `/{examId}/start` | S | Mulai sesi ujian → dapat soal |
| 7 | GET | `/sessions/{sessionId}` | S | Get sesi aktif (resume) |
| 8 | POST | `/sessions/{sessionId}/answers` | S | Submit jawaban (per soal) |
| 9 | PUT | `/sessions/{sessionId}/answers/{answerId}` | S | Update jawaban |
| 10 | POST | `/sessions/{sessionId}/submit` | S | Submit ujian (final) |
| | | | | |
| 11 | GET | `/history` | S | Riwayat ujian + skor |
| 12 | GET | `/results/{resultId}` | S | Detail hasil ujian |
| 13 | POST | `/results/{resultId}/appeal` | S | Ajukan banding |
| | | | | |
| 14 | GET | `/certificates` | S | List sertifikat saya |
| 15 | GET | `/certificates/{id}/download` | S | Download PDF sertifikat |

### Detail Flow: Start → Answer → Submit

**1. Start Exam:**
```
POST /api/v1/my-exams/{examId}/start
Body: { "scheduleId": "uuid" }

Response:
{
  "sessionId": "uuid",
  "exam": { "title": "...", "timeLimitMinutes": 90 },
  "sections": [
    {
      "id": "uuid",
      "title": "Part A - Pilihan Ganda",
      "questions": [
        {
          "id": "uuid",
          "questionText": "...",
          "type": "multiple_choice",
          "options": [
            { "id": "uuid", "optionText": "..." },
            ...
          ]
        }
      ]
    }
  ],
  "startTime": "2026-04-15T08:05:00Z",
  "endTime": "2026-04-15T09:35:00Z"
}
```

**2. Submit Answer (per soal, real-time save):**
```
POST /api/v1/my-exams/sessions/{sessionId}/answers
Body: {
  "questionId": "uuid",
  "answer": "uuid-option-id"   // untuk MCQ
  // atau "answer": "Teks jawaban essay"  // untuk essay
}
```

**3. Final Submit:**
```
POST /api/v1/my-exams/sessions/{sessionId}/submit

Response:
{
  "attemptId": "uuid",
  "score": 85.0,
  "totalScore": 100.0,
  "percentage": 85.0,
  "passed": true,
  "questionsAnswered": 25,
  "timeSpentSeconds": 4200
}
```

---

## Module 12: Proctoring

**Base path:** `/api/v1/proctoring`

Monitoring sesi ujian secara live oleh proctor/teacher.

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/sessions` | A,T | List sesi aktif (monitoring) |
| 2 | GET | `/sessions/{id}` | T | Detail sesi + cheating logs |
| 3 | POST | `/sessions/{id}/cheating-logs` | T, System | Log aktivitas mencurigakan |
| 4 | POST | `/sessions/{id}/terminate` | T | Akhiri sesi paksa |
| 5 | GET | `/assignments` | T | List penugasan proctor saya |

**LogCheatingRequest:**
```json
{
  "event": "tab_switch",
  "detail": "Student berpindah ke tab lain selama 15 detik",
  "severity": "medium",
  "screenshotUrl": "https://storage.example.com/screenshots/abc.jpg"
}
```

---

## Module 13: Grading & Results

**Base path:** `/api/v1/grading`

Teacher menilai jawaban essay dan mempublikasikan hasil.

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/pending` | T | List attempt yang belum dinilai |
| 2 | GET | `/attempts/{attemptId}` | T | Detail attempt + semua jawaban |
| 3 | PUT | `/attempts/{attemptId}/answers/{answerId}` | T | Beri nilai per jawaban (essay) |
| 4 | POST | `/attempts/{attemptId}/finalize` | T | Finalisasi penilaian → generate result |
| 5 | GET | `/results` | A,T | List semua hasil (filter: exam, student, passed) |
| 6 | PUT | `/results/{id}/publish` | T | Publikasikan hasil ke student |
| 7 | GET | `/appeals` | A,T | List banding |
| 8 | PUT | `/appeals/{id}` | A,T | Resolve banding |

**GradeAnswerRequest:**
```json
{
  "score": 15.0,
  "feedback": "Analisis cukup baik, namun kurang contoh."
}
```

**ResolveAppealRequest:**
```json
{
  "status": "approved",
  "resolution": "Setelah ditinjau ulang, skor dinaikkan menjadi 78."
}
```

---

## Module 14: Certificates

**Base path:** `/api/v1/certificates`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/templates` | A | List template sertifikat |
| 2 | POST | `/templates` | A | Buat template |
| 3 | PUT | `/templates/{id}` | A | Update template |
| 4 | DELETE | `/templates/{id}` | A | Hapus template |
| 5 | POST | `/issue` | A,T | Terbitkan sertifikat |
| 6 | GET | `/{id}` | All/Owner | Detail sertifikat |
| 7 | GET | `/{id}/download` | All/Owner | Download PDF |

---

## Module 15: Notifications

**Base path:** `/api/v1/notifications`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | All | List notifikasi saya |
| 2 | GET | `/unread-count` | All | Jumlah unread |
| 3 | PUT | `/{id}/read` | All | Tandai dibaca |
| 4 | PUT | `/read-all` | All | Tandai semua dibaca |
| 5 | GET | `/channels` | All | Get preferensi channel |
| 6 | PUT | `/channels` | All | Update preferensi |

---

## Module 16: Announcements

**Base path:** `/api/v1/announcements`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | All | List pengumuman |
| 2 | GET | `/{id}` | All | Detail pengumuman |
| 3 | POST | `/` | A,T | Buat pengumuman |
| 4 | PUT | `/{id}` | A,T/Owner | Update pengumuman |
| 5 | DELETE | `/{id}` | A | Hapus pengumuman |

---

## Module 17: Messages

**Base path:** `/api/v1/messages`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | All | List percakapan saya |
| 2 | GET | `/thread/{userId}` | All | Thread dengan user tertentu |
| 3 | POST | `/` | All | Kirim pesan |
| 4 | PUT | `/{id}/read` | All | Tandai dibaca |

---

## Module 18: Gamification

**Base path:** `/api/v1/gamification`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/badges` | All | List semua badge |
| 2 | POST | `/badges` | A | Buat badge baru |
| 3 | PUT | `/badges/{id}` | A | Update badge |
| 4 | DELETE | `/badges/{id}` | A | Hapus badge |
| 5 | GET | `/my-badges` | S | Badge yang saya raih |
| 6 | GET | `/my-points` | S | Total poin saya |
| 7 | GET | `/points/history` | S | Riwayat perolehan poin |
| 8 | GET | `/leaderboard` | All | Leaderboard (top users) |

---

## Module 19: Billing

**Base path:** `/api/v1/billing`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/plans` | All | List paket tersedia |
| 2 | POST | `/plans` | A | Buat paket |
| 3 | PUT | `/plans/{id}` | A | Update paket |
| 4 | DELETE | `/plans/{id}` | A | Hapus paket |
| 5 | POST | `/subscribe` | S,T | Subscribe ke paket |
| 6 | GET | `/my-subscription` | All | Lihat langganan aktif |
| 7 | POST | `/transactions` | All | Inisiasi pembayaran |
| 8 | GET | `/transactions` | All | List transaksi saya |
| 9 | GET | `/invoices` | All | List invoice saya |
| 10 | GET | `/invoices/{id}/download` | All | Download PDF invoice |
| 11 | POST | `/coupons/validate` | All | Validasi kode kupon |
| 12 | GET | `/coupons` | A | List semua kupon |
| 13 | POST | `/coupons` | A | Buat kupon |
| 14 | PUT | `/coupons/{id}` | A | Update kupon |

---

## Module 20: Support Tickets

**Base path:** `/api/v1/tickets`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | All | List tiket (mine / all for admin) |
| 2 | GET | `/{id}` | All | Detail tiket + messages |
| 3 | POST | `/` | S,T | Buat tiket baru |
| 4 | PUT | `/{id}` | A | Update tiket (assign, status) |
| 5 | PUT | `/{id}/close` | A | Tutup tiket |
| 6 | POST | `/{id}/messages` | All | Reply ke tiket |
| 7 | GET | `/categories` | All | List kategori tiket |
| 8 | GET | `/priorities` | All | List prioritas |
| 9 | GET | `/statuses` | All | List status |

---

## Module 21: Calendar

**Base path:** `/api/v1/calendar`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/events` | All | List events (filter: dateRange, examId) |
| 2 | POST | `/events` | A,T | Buat event |
| 3 | PUT | `/events/{id}` | A,T | Update event |
| 4 | DELETE | `/events/{id}` | A,T | Hapus event |

---

## Module 22: Media

**Base path:** `/api/v1/media`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | POST | `/upload` | All | Upload file (multipart/form-data) |
| 2 | GET | `/{id}` | All | Get/download file |
| 3 | DELETE | `/{id}` | Owner, A | Hapus file |

---

## Module 23: Tags

**Base path:** `/api/v1/tags`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/` | All | List tags (filter: type) |
| 2 | POST | `/` | A,T | Buat tag |
| 3 | DELETE | `/{id}` | A | Hapus tag |
| 4 | POST | `/attach` | A,T | Pasang tag ke entity |
| 5 | POST | `/detach` | A,T | Lepas tag dari entity |

---

## Module 24: Admin / System

**Base path:** `/api/v1/admin`

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/feature-flags` | A | List feature flags |
| 2 | PUT | `/feature-flags/{id}` | A | Toggle feature flag |
| 3 | GET | `/settings` | A | List settings |
| 4 | PUT | `/settings` | A | Update setting |
| 5 | GET | `/audit-logs` | A | List audit logs (filter: entity, action, dateRange) |
| 6 | GET | `/activity-logs` | A | List activity logs |
| 7 | GET | `/login-logs` | A | List login logs |
| 8 | GET | `/webhooks` | A | List webhooks |
| 9 | POST | `/webhooks` | A | Buat webhook |
| 10 | PUT | `/webhooks/{id}` | A | Update webhook |
| 11 | DELETE | `/webhooks/{id}` | A | Hapus webhook |
| 12 | GET | `/webhooks/{id}/logs` | A | List webhook delivery logs |

---

## Module 25: Dashboard

**Base path:** `/api/v1/dashboard`

Dashboard menampilkan metrik berbeda tergantung role.

| # | Method | Endpoint | Role | Deskripsi |
|---|--------|----------|------|-----------|
| 1 | GET | `/admin` | A | Stats: total users, exams, active sessions, revenue |
| 2 | GET | `/teacher` | T | Stats: my exams, pending grading, upcoming schedules |
| 3 | GET | `/student` | S | Stats: upcoming exams, recent scores, badges, leaderboard rank |

### Example Response — Admin Dashboard:
```json
{
  "totalUsers": 1250,
  "totalExams": 87,
  "activeExamSessions": 12,
  "totalRevenue": 45000000,
  "recentActivity": [ ... ],
  "examsByStatus": { "draft": 15, "published": 60, "archived": 12 },
  "userGrowthChart": [ ... ],
  "topExams": [ ... ]
}
```

---

## Ringkasan

| Module | Endpoints | Base Path |
|--------|:---------:|-----------|
| Auth | 11 | `/api/v1/auth` |
| Users | 8 | `/api/v1/users` |
| Roles & Permissions | 7 | `/api/v1/roles` |
| Tenants & Orgs | 13 | `/api/v1/tenants` |
| Exam Categories | 5 | `/api/v1/exam-categories` |
| Exams | 19 | `/api/v1/exams` |
| Questions | 18 | `/api/v1/questions` |
| Rubrics | 7 | `/api/v1/rubrics` |
| Schedules | 5 | `/api/v1/schedules` |
| Exam Rooms | 4 | `/api/v1/exam-rooms` |
| My Exams (Student) | 15 | `/api/v1/my-exams` |
| Proctoring | 5 | `/api/v1/proctoring` |
| Grading & Results | 8 | `/api/v1/grading` |
| Certificates | 7 | `/api/v1/certificates` |
| Notifications | 6 | `/api/v1/notifications` |
| Announcements | 5 | `/api/v1/announcements` |
| Messages | 4 | `/api/v1/messages` |
| Gamification | 8 | `/api/v1/gamification` |
| Billing | 14 | `/api/v1/billing` |
| Tickets | 9 | `/api/v1/tickets` |
| Calendar | 4 | `/api/v1/calendar` |
| Media | 3 | `/api/v1/media` |
| Tags | 5 | `/api/v1/tags` |
| Admin/System | 12 | `/api/v1/admin` |
| Dashboard | 3 | `/api/v1/dashboard` |
| **Total** | **~200** | |
