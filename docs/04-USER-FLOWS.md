# SmartEdu Telu — User Flows

> **Versi:** 1.0
> **Tanggal:** 2026-04-09
> **Role:** Admin (A) · Teacher (T) · Student (S)

---

## 1. Registration & Onboarding

### 1.1 Student Registration

```
[Landing Page]
      │
      ▼
[Klik "Daftar"]
      │
      ▼
[Form Registrasi]
│  - Nama lengkap
│  - Email (validasi @telkom.ac.id atau umum)
│  - Password + konfirmasi
│  - No. telepon (opsional)
      │
      ▼
[POST /api/v1/auth/register]
      │
      ▼
[Email Verifikasi dikirim]
      │
      ▼
[Student klik link verifikasi]
      │
      ▼
[Account aktif → Redirect Login]
      │
      ▼
[Login → Dashboard Student]
```

**Business Rules:**
- Email harus unik
- Password minimal 8 karakter (uppercase, lowercase, digit, special char)
- Default role: `student`
- Default status: `pending_verification`
- Setelah verifikasi: status → `active`

### 1.2 Teacher Onboarding (by Admin)

```
[Admin Dashboard → Users → Tambah User]
      │
      ▼
[Form Create User]
│  - Nama, email, password temporary
│  - Role: teacher
│  - Organization (opsional)
      │
      ▼
[POST /api/v1/users] (role admin)
      │
      ▼
[System kirim email undangan + temp password]
      │
      ▼
[Teacher login dengan temp password]
      │
      ▼
[Force Change Password]
      │
      ▼
[Complete Profile → Dashboard Teacher]
```

---

## 2. Login Flow

```
[Login Page]
│  - Email
│  - Password
│  - "Lupa Password?" link
      │
      ▼
[POST /api/v1/auth/login]
      │
      ├─── 200 OK ───┐
      │               ▼
      │     [Store JWT + refreshToken]
      │               │
      │               ▼
      │     [Decode token → get role]
      │               │
      │     ┌─────────┼─────────┐
      │     ▼         ▼         ▼
      │  [/dashboard  [/dashboard  [/dashboard
      │   /admin]      /teacher]    /student]
      │
      ├─── 401 ───┐
      │            ▼
      │     [Show error: "Email atau password salah"]
      │
      └─── 403 ───┐
                   ▼
            [Show error: "Akun dinonaktifkan"]
```

### 2.1 Forgot Password Flow

```
[Klik "Lupa Password?"]
      │
      ▼
[Input email]
      │
      ▼
[POST /api/v1/auth/forgot-password]
      │
      ▼
[Email reset dikirim (valid 1 jam)]
      │
      ▼
[Klik link → Form Reset Password]
│  - New password
│  - Confirm password
      │
      ▼
[POST /api/v1/auth/reset-password]
      │
      ▼
[Success → Redirect Login]
```

### 2.2 Token Refresh Flow (Automatic)

```
[API call gagal → 401]
      │
      ▼
[Check: punya refreshToken?]
      │
      ├─── Ya ───┐
      │           ▼
      │  [POST /api/v1/auth/refresh-token]
      │           │
      │     ┌─────┴─────┐
      │     ▼            ▼
      │  [200: new      [401: refreshToken
      │   token]         expired]
      │     │               │
      │     ▼               ▼
      │  [Retry            [Redirect ke
      │   original          Login Page +
      │   request]          clear tokens]
      │
      └─── Tidak ───┐
                     ▼
              [Redirect ke Login Page]
```

---

## 3. Admin Flows

### 3.1 Dashboard Admin

```
[Login sebagai Admin]
      │
      ▼
[GET /api/v1/dashboard/admin]
      │
      ▼
[Dashboard menampilkan:]
├── Total users (growth chart)
├── Total ujian (by status)
├── Sesi ujian aktif (real-time)
├── Revenue (jika billing aktif)
├── Aktivitas terbaru
└── Top ujian (most participants)
```

### 3.2 User Management

```
[Admin → Menu "Users"]
      │
      ▼
[GET /api/v1/users?page=0&size=20]
      │
      ▼
[Tabel User: nama, email, role, status, aksi]
      │
      ├── [🔍 Search/Filter]
      │       └── ?search=keyword&role=teacher&status=active
      │
      ├── [➕ Tambah User] ──→ Modal/Page Form ──→ POST /api/v1/users
      │
      ├── [✏️ Edit] ──→ Modal/Page Form ──→ PUT /api/v1/users/{id}
      │
      ├── [🔄 Ubah Status]
      │       └── PUT /api/v1/users/{id}/status { "status": "suspended" }
      │
      ├── [🔑 Ubah Role]
      │       └── PUT /api/v1/users/{id}/roles { "roleIds": [...] }
      │
      └── [🗑️ Hapus] ──→ Confirm Dialog ──→ DELETE /api/v1/users/{id}
```

### 3.3 Tenant & Organization Setup

```
[Admin → Menu "Organizations"]
      │
      ▼
[GET /api/v1/tenants]
      │
      ▼
[List Tenant: Telkom University]
      │
      ├── [Kelola Organisasi]
      │       │
      │       ▼
      │   [GET /api/v1/tenants/{id}/organizations]
      │       │
      │       ├── Fakultas Informatika
      │       │     ├── Program Studi S1 Informatika
      │       │     └── Program Studi S1 Sistem Informasi
      │       │
      │       └── [➕ Tambah Organisasi]
      │             └── POST /api/v1/tenants/{id}/organizations
      │
      └── [Kelola User di Tenant]
              │
              ▼
          [POST /api/v1/tenants/{id}/users]
```

### 3.4 Admin Manages Exam Categories

```
[Admin → Menu "Exam Categories"]
      │
      ▼
[GET /api/v1/exam-categories] → Tree View
      │
      ├── 📁 Akademik
      │     ├── 📁 Reguler
      │     │     ├── UTS
      │     │     └── UAS
      │     └── 📁 Remidial
      │
      ├── 📁 Sertifikasi
      │     ├── AWS
      │     ├── Google Cloud
      │     └── Microsoft
      │
      └── [➕ Tambah Kategori]
              └── POST /api/v1/exam-categories
                  { "name": "...", "parentId": "uuid-or-null" }
```

### 3.5 Admin System Settings

```
[Admin → Menu "Settings"]
      │
      ├── [Feature Flags]
      │     GET /api/v1/admin/feature-flags
      │     PUT /api/v1/admin/feature-flags/{id} { "enabled": true }
      │
      ├── [System Settings]
      │     GET /api/v1/admin/settings
      │     PUT /api/v1/admin/settings { "key": "value", ... }
      │
      ├── [Audit Logs]
      │     GET /api/v1/admin/audit-logs?dateRange=...&entity=...
      │
      └── [Webhooks]
            GET /api/v1/admin/webhooks
            POST /api/v1/admin/webhooks { url, events[], secret }
```

---

## 4. Teacher Flows

### 4.1 Dashboard Teacher

```
[Login sebagai Teacher]
      │
      ▼
[GET /api/v1/dashboard/teacher]
      │
      ▼
[Dashboard menampilkan:]
├── Ujian saya (by status: draft, published, archived)
├── Pending grading (jawaban yang belum dinilai)
├── Jadwal ujian mendatang
├── Statistik: avg score, pass rate
└── Aktivitas terbaru
```

### 4.2 Create Exam (Full Flow)

Ini adalah flow utama teacher. Proses membuat ujian dari nol sampai publish.

```
[Teacher → Menu "Exams" → "Buat Ujian"]
      │
      ▼
══════════════════════════════════════
  STEP 1: INFORMASI DASAR
══════════════════════════════════════
[Form:]
│  - Judul ujian
│  - Deskripsi
│  - Kategori (dropdown tree)
│  - Tipe: midterm / final / quiz / practice / certification
│  - Batas waktu (menit)
│  - Maks attempt
│  - Passing percentage
│  - Instruksi untuk peserta
      │
      ▼
[POST /api/v1/exams]
→ Dapat exam ID, status: DRAFT
      │
      ▼
══════════════════════════════════════
  STEP 2: KONFIGURASI
══════════════════════════════════════
[Setting lanjutan:]
│  - Acak soal? ✅/❌
│  - Acak jawaban? ✅/❌
│  - Show result: after_submit / after_grading / scheduled
│  - Allow review? ✅/❌
│  - Require proctoring? ✅/❌
│  - Feedback type: none / summary / detailed
      │
      ▼
[PUT /api/v1/exams/{id}]
      │
      ▼
══════════════════════════════════════
  STEP 3: BUAT SECTIONS
══════════════════════════════════════
[Tambah Section, misal:]
│  - Part A: Pilihan Ganda (weight 60%)
│  - Part B: Essay (weight 40%)
      │
      ▼
[POST /api/v1/exams/{id}/sections] (untuk setiap section)
      │
      ▼
══════════════════════════════════════
  STEP 4: TAMBAHKAN SOAL
══════════════════════════════════════

Opsi A: Pilih dari Question Bank
┌──────────────────────────────────┐
│  GET /api/v1/questions            │
│  ?type=multiple_choice            │
│  &difficulty=medium               │
│  &search=database                 │
│  → Pilih soal dari list           │
│  → POST /{examId}/sections/       │
│    {sectionId}/questions          │
│    { questionId, weight }         │
└──────────────────────────────────┘

Opsi B: Buat Soal Baru
┌──────────────────────────────────┐
│  POST /api/v1/questions           │
│  { questionText, type, options }  │
│  → Soal masuk ke bank             │
│  → Otomatis ditambahkan ke section│
└──────────────────────────────────┘
      │
      ▼
[Reorder soal jika perlu]
PUT /api/v1/exams/{id}/sections/{sectionId}/questions/reorder
      │
      ▼
══════════════════════════════════════
  STEP 5: BUAT JADWAL
══════════════════════════════════════
[POST /api/v1/schedules]
{
  "examId": "uuid",
  "startTime": "2026-04-15T08:00:00+07:00",
  "endTime": "2026-04-15T10:00:00+07:00",
  "maxParticipants": 50
}
      │
      ▼
══════════════════════════════════════
  STEP 6: PUBLISH
══════════════════════════════════════
[Review semua konfigurasi]
      │
      ▼
[PUT /api/v1/exams/{id}/publish]
→ Status: DRAFT → PUBLISHED
→ Ujian muncul di "Available Exams" student
→ Notifikasi dikirim ke enrolled students
```

### 4.3 Question Bank Management

```
[Teacher → Menu "Question Bank"]
      │
      ├── [📁 Folders] (sidebar tree)
      │     GET /api/v1/questions/folders
      │     ├── 📁 Basis Data
      │     │     ├── 📁 SQL
      │     │     └── 📁 ERD
      │     └── 📁 Algoritma
      │
      ├── [🏷️ Categories]
      │     GET /api/v1/questions/categories
      │
      └── [Konten Utama: List Soal]
            GET /api/v1/questions?folderId=uuid&search=...
            │
            ├── [➕ Buat Soal]
            │     POST /api/v1/questions
            │     │
            │     └── [Form berdasarkan type:]
            │           ├── multiple_choice → + opsi A/B/C/D + tandai correct
            │           ├── multiple_answer → + opsi A/B/C/D + tandai beberapa correct
            │           ├── true_false → otomatis 2 opsi
            │           ├── essay → textarea + rubrik
            │           ├── short_answer → expected answer
            │           └── fill_blank → template + answer slots
            │
            ├── [✏️ Edit Soal]
            │     GET /api/v1/questions/{id}
            │     PUT /api/v1/questions/{id}
            │
            └── [📎 Upload Attachment] (gambar, audio, video)
                  POST /api/v1/questions/{id}/attachments
```

### 4.4 Grading Flow (Essay)

```
[Teacher → Menu "Grading"]
      │
      ▼
[GET /api/v1/grading/pending]
→ List attempt yang butuh penilaian manual
      │
      ▼
[Klik attempt → Detail]
[GET /api/v1/grading/attempts/{attemptId}]
      │
      ▼
[Tampilan: Soal + Jawaban Student + Rubrik]
      │
      ├── Soal 1 (Essay): "Jelaskan normalisasi database..."
      │   Jawaban: "Normalisasi adalah..."
      │   Rubrik: Pemahaman (8), Analisis (7), Penyajian (5)
      │   │
      │   └── [Beri Nilai]
      │         PUT /api/v1/grading/attempts/{id}/answers/{answerId}
      │         { "score": 15.0, "feedback": "Baik, tapi kurang contoh" }
      │
      ├── Soal 2 (Essay): ...
      │   └── [Beri Nilai] ...
      │
      └── [Semua dinilai → Finalisasi]
            POST /api/v1/grading/attempts/{attemptId}/finalize
            → System hitung total score
            → Generate exam_result
            │
            └── [Publish Hasil]
                  PUT /api/v1/grading/results/{id}/publish
                  → Student bisa lihat hasilnya
                  → Notifikasi dikirim
```

### 4.5 Proctoring / Monitoring

```
[Teacher → Menu "Proctoring"]
      │
      ▼
[GET /api/v1/proctoring/sessions]
→ List sesi ujian yang sedang berlangsung
      │
      ▼
[Klik sesi → Live Monitoring]
[GET /api/v1/proctoring/sessions/{id}]
      │
      ▼
┌────────────────────────────────────────┐
│  MONITORING VIEW                        │
│                                         │
│  Student: John Doe                      │
│  Progress: 15/25 soal                   │
│  Time remaining: 45 menit               │
│                                         │
│  Cheating Logs:                         │
│  ├── 08:15 - Tab switch (medium)        │
│  ├── 08:22 - Window resize (low)        │
│  └── 08:30 - Copy detected (high)       │
│                                         │
│  Actions:                               │
│  ├── [⚠️ Log Peringatan]               │
│  └── [🛑 Terminate Session]            │
└────────────────────────────────────────┘
      │
      ├── [Log Peringatan]
      │     POST /api/v1/proctoring/sessions/{id}/cheating-logs
      │     { "event": "warning_issued", "detail": "..." }
      │
      └── [Terminate]
            POST /api/v1/proctoring/sessions/{id}/terminate
            → Sesi berakhir paksa
            → Student diberitahu
```

---

## 5. Student Flows

### 5.1 Dashboard Student

```
[Login sebagai Student]
      │
      ▼
[GET /api/v1/dashboard/student]
      │
      ▼
[Dashboard menampilkan:]
├── Ujian mendatang (jadwal terdekat)
├── Ujian tersedia (belum terdaftar)
├── Hasil terbaru (skor & status lulus/tidak)
├── Badge & poin
├── Posisi leaderboard
└── Sertifikat terbaru
```

### 5.2 Browse & Register Exam

```
[Student → Menu "Available Exams"]
      │
      ▼
[GET /api/v1/my-exams/available?search=&category=]
      │
      ▼
[List Card Ujian:]
┌────────────────────────────────┐
│  UTS Basis Data 2026           │
│  Category: Akademik > Reguler  │
│  Durasi: 90 menit              │
│  Tipe: Midterm                 │
│  Status: Published             │
│  Jadwal: 15 Apr 2026 08:00     │
│  Peserta: 35/50                │
│  [📋 Detail] [✅ Daftar]       │
└────────────────────────────────┘
      │
      ├── [Detail] → GET /api/v1/my-exams/{examId}
      │     │
      │     ▼
      │   ┌──────────────────────┐
      │   │  Detail Ujian         │
      │   │  - Deskripsi          │
      │   │  - Instruksi          │
      │   │  - Rules              │
      │   │  - Jadwal tersedia    │
      │   │  - Proctoring: Ya     │
      │   │  - Max attempt: 1     │
      │   │  [✅ Daftar Sekarang] │
      │   └──────────────────────┘
      │
      └── [Daftar]
            POST /api/v1/my-exams/{examId}/register
            { "scheduleId": "uuid" }
            → Registration created
            → Notifikasi konfirmasi
            → Event ditambahkan ke calendar
```

### 5.3 Take Exam (Complete Flow)

Ini adalah flow terpenting dari sudut pandang student.

```
[Student → Menu "My Exams" → "Registrations"]
      │
      ▼
[GET /api/v1/my-exams/registrations]
      │
      ▼
[Jadwal: 15 Apr 2026 08:00-10:00]
[Sekarang: 08:02 → Tombol "Mulai" aktif]
      │
      ▼
[Klik "Mulai Ujian"]
      │
      ▼
══════════════════════════════════════
  PRE-EXAM CHECK
══════════════════════════════════════
[Jika proctoring aktif:]
├── ✅ Kamera aktif
├── ✅ Koneksi internet stabil
├── ✅ Browser fullscreen
└── ✅ Privacy agreement
      │
      ▼
[POST /api/v1/my-exams/{examId}/start]
{ "scheduleId": "uuid" }
→ Response: sessionId, sections, questions, timer
      │
      ▼
══════════════════════════════════════
  EXAM SESSION (LIVE)
══════════════════════════════════════

┌──────────────────────────────────────────────┐
│  ⏱️ Time: 01:28:45                           │
│                                               │
│  Part A: Pilihan Ganda (15/20 dijawab)       │
│  ┌─────────────┐                              │
│  │ Soal 16/20  │                              │
│  │             │                              │
│  │ Apa output  │                              │
│  │ dari query  │                              │
│  │ SELECT...?  │                              │
│  │             │                              │
│  │ ○ A. 10     │                              │
│  │ ● B. 15     │  ←── Student pilih           │
│  │ ○ C. 20     │                              │
│  │ ○ D. Error  │                              │
│  └─────────────┘                              │
│                                               │
│  [← Prev] [1][2][3]...[20] [Next →]          │
│                                               │
│  Part B: Essay (0/5 dijawab)                  │
│  [Submit Ujian]                               │
└──────────────────────────────────────────────┘

[Setiap jawab soal → auto-save]
POST /api/v1/my-exams/sessions/{sessionId}/answers
{ "questionId": "uuid", "answer": "uuid-option-B" }

[Ubah jawaban]
PUT /api/v1/my-exams/sessions/{sessionId}/answers/{answerId}

[Navigasi antar soal → indicator answered/unanswered]

[Jika tab switch / minimize → cheating log otomatis]
POST /api/v1/proctoring/sessions/{id}/cheating-logs
{ "event": "tab_switch", "severity": "medium" }
      │
      ▼
══════════════════════════════════════
  SUBMIT / TIMEOUT
══════════════════════════════════════

Opsi A: Student klik "Submit Ujian"
┌──────────────────────────┐
│  Konfirmasi Submit         │
│                            │
│  Dijawab: 23/25 soal      │
│  ⚠️ 2 soal belum dijawab  │
│                            │
│  [Kembali] [Submit Final]  │
└──────────────────────────┘

Opsi B: Waktu habis → auto-submit

      │
      ▼
[POST /api/v1/my-exams/sessions/{sessionId}/submit]
      │
      ▼
══════════════════════════════════════
  RESULT (jika showResultMode = after_submit)
══════════════════════════════════════
┌──────────────────────────────┐
│  Hasil Ujian                  │
│                               │
│  Skor: 85/100                 │
│  Persentase: 85%              │
│  Status: ✅ LULUS             │
│  Waktu: 1 jam 10 menit       │
│                               │
│  [🏠 Dashboard]              │
│  [📋 Detail Review]          │
└──────────────────────────────┘

ATAU (jika showResultMode = after_grading)
┌──────────────────────────────┐
│  Ujian Tersubmit              │
│                               │
│  Terima kasih telah           │
│  mengerjakan ujian.           │
│  Hasil akan diumumkan         │
│  setelah penilaian selesai.   │
│                               │
│  [🏠 Dashboard]              │
└──────────────────────────────┘
```

### 5.4 View Results & History

```
[Student → Menu "Exam History"]
      │
      ▼
[GET /api/v1/my-exams/history]
      │
      ▼
┌──────────────────────────────────────────┐
│  Riwayat Ujian                            │
│                                           │
│  UTS Basis Data 2026        85%  ✅ Lulus │
│  Quiz Algoritma Week 3      60%  ❌ Gagal │
│  UTS Jaringan Komputer      92%  ✅ Lulus │
│  Practice Test AWS           78%  ✅ Lulus │
└──────────────────────────────────────────┘
      │
      ▼
[Klik salah satu → Detail]
[GET /api/v1/my-exams/results/{resultId}]
      │
      ▼
┌──────────────────────────────────────────┐
│  Detail Hasil                             │
│                                           │
│  Skor: 85/100                             │
│  Per section:                             │
│  ├── Part A (PG): 55/60                  │
│  └── Part B (Essay): 30/40              │
│                                           │
│  [Jika allow_review = true]              │
│  Review Jawaban:                          │
│  Q1: ✅ (benar)                          │
│  Q2: ❌ (salah - jawaban benar: C)       │
│  Q3: ✅                                  │
│  ...                                      │
│                                           │
│  [📝 Ajukan Banding]                    │
│  [📜 Download Sertifikat]               │
└──────────────────────────────────────────┘
```

### 5.5 Appeal / Banding

```
[Student di Detail Result → Klik "Ajukan Banding"]
      │
      ▼
[Form Banding]
│  - Pilih soal yang ingin dibanding
│  - Alasan banding (text)
      │
      ▼
[POST /api/v1/my-exams/results/{resultId}/appeal]
{
  "reason": "Jawaban saya pada soal no. 15 seharusnya benar...",
  "questionIds": ["uuid-q15"]
}
      │
      ▼
[Status: Pending Review]
→ Teacher/Admin dapat notifikasi
      │
      ▼
[Teacher review banding]
PUT /api/v1/grading/appeals/{id}
{ "status": "approved", "resolution": "..." }
      │
      ▼
[Student dapat notifikasi hasil banding]
```

### 5.6 Certificates

```
[Student → Menu "Certificates"]
      │
      ▼
[GET /api/v1/my-exams/certificates]
      │
      ▼
┌──────────────────────────────────────┐
│  Sertifikat Saya                      │
│                                       │
│  📜 UTS Basis Data 2026              │
│     No: CERT-2026-0001               │
│     Skor: 85%                         │
│     Issued: 20 Apr 2026              │
│     [⬇️ Download PDF]               │
│                                       │
│  📜 Sertifikasi AWS Cloud            │
│     No: CERT-2026-0015               │
│     Skor: 92%                         │
│     [⬇️ Download PDF]               │
└──────────────────────────────────────┘
```

### 5.7 Gamification

```
[Student → Dashboard atau Menu "Achievements"]
      │
      ▼
[GET /api/v1/gamification/my-badges]
[GET /api/v1/gamification/my-points]
[GET /api/v1/gamification/leaderboard]
      │
      ▼
┌──────────────────────────────────────┐
│  Pencapaian Saya                      │
│                                       │
│  🏅 Poin: 1,250                      │
│  🏆 Rank: #15 dari 500 student       │
│                                       │
│  Badge:                               │
│  ├── 🎯 Perfect Score (1x 100%)     │
│  ├── 🔥 3 Win Streak                │
│  ├── 📚 Bookworm (50+ ujian)        │
│  └── ⭐ Dean's List                  │
│                                       │
│  [📊 Leaderboard]                    │
│  ┌────┬────────────┬───────┐         │
│  │ #1 │ Alice      │ 2,100 │         │
│  │ #2 │ Bob        │ 1,950 │         │
│  │ #3 │ Charlie    │ 1,800 │         │
│  │...  │            │       │         │
│  │ #15│ You (John) │ 1,250 │         │
│  └────┴────────────┴───────┘         │
└──────────────────────────────────────┘
```

---

## 6. Cross-Role Flows

### 6.1 Notification Flow

```
[Event terjadi di system]
      │
      ├── Ujian baru dipublish → notify enrolled students
      ├── Hasil keluar → notify student
      ├── Banding masuk → notify teacher/admin
      ├── Jadwal mendekati → notify registered students
      ├── Soal baru dari question bank shared → notify teachers
      └── Tiket support dibalas → notify user
      │
      ▼
[Notification masuk via:]
├── 🔔 In-app (bell icon, badge count)
│     GET /api/v1/notifications?page=0
│     GET /api/v1/notifications/unread-count → { "count": 5 }
│     PUT /api/v1/notifications/{id}/read
│     PUT /api/v1/notifications/read-all
│
├── 📧 Email (async, sesuai preference)
│
└── 📱 Push (future - mobile app)

[User bisa atur preference:]
GET /api/v1/notifications/channels
PUT /api/v1/notifications/channels
{ "email": true, "inApp": true, "push": false }
```

### 6.2 Support Ticket Flow

```
[User (Student/Teacher) punya masalah]
      │
      ▼
[Menu "Support" → "Buat Tiket"]
POST /api/v1/tickets
{
  "subject": "Tidak bisa submit ujian",
  "description": "Saat klik submit, muncul error 500...",
  "category": "technical",
  "priority": "high",
  "attachments": ["uuid-screenshot"]
}
      │
      ▼
[Admin dapat notifikasi → assign ke agent]
PUT /api/v1/tickets/{id}
{ "assigneeId": "uuid-admin", "status": "in_progress" }
      │
      ▼
[Back-and-forth messages]
POST /api/v1/tickets/{id}/messages
{ "body": "Bisa share screenshot error-nya?" }
      │
      ▼
[Resolved]
PUT /api/v1/tickets/{id}/close
{ "resolution": "Bug fixed, silakan coba lagi" }
      │
      ▼
[User dapat notifikasi tiket ditutup]
```

### 6.3 Calendar Integration

```
[Automatic events generated:]
├── Exam scheduled → Calendar event untuk teacher & registered students
├── Grading deadline → Calendar event untuk teacher
├── Result publication → Calendar event
└── Custom events by admin/teacher

[User → Menu "Calendar"]
GET /api/v1/calendar/events?from=2026-04-01&to=2026-04-30
      │
      ▼
[Calendar View: month/week/day]
┌────────────────────────────────────┐
│  April 2026                         │
│                                     │
│  15 │ 🔵 UTS Basis Data 08:00-10:00│
│  17 │ 🟢 Quiz Algoritma 14:00      │
│  20 │ 🟡 Deadline Grading UTS      │
│  25 │ 🔵 UAS Jaringan 08:00-11:00  │
└────────────────────────────────────┘
```

---

## 7. Error Handling Flow (Global)

Semua error ditangani konsisten di seluruh platform.

```
[API Call]
      │
      ├── 200/201/204 → ✅ Success
      │
      ├── 400 → [Show field-level errors]
      │     {
      │       "success": false,
      │       "error": { "code": "SE-CMN-001", "message": "Validasi gagal" },
      │       "data": {
      │         "email": "Email sudah terdaftar",
      │         "password": "Minimal 8 karakter"
      │       }
      │     }
      │
      ├── 401 → [Auto refresh token atau redirect login]
      │
      ├── 403 → [Show "Akses ditolak" page]
      │
      ├── 404 → [Show "Tidak ditemukan" page]
      │
      ├── 409 → [Show conflict message]
      │     "Duplikat: email sudah terdaftar"
      │
      └── 500 → [Show generic error + offer to create support ticket]
            ┌──────────────────────────┐
            │  Terjadi Kesalahan        │
            │                           │
            │  Maaf, terjadi masalah    │
            │  pada server.             │
            │                           │
            │  [🔄 Coba Lagi]          │
            │  [🎫 Buat Tiket Support] │
            └──────────────────────────┘
```
