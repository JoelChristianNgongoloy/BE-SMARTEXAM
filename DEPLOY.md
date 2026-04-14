# 🚀 Deployment Guide — SmartExam Backend

> **Domain:** `besmartexam.jiilan.me`  
> **Stack:** Docker Compose + Nginx (global/host) + Let's Encrypt SSL  
> **VPS minimum:** 1 vCPU, 2GB RAM, 20GB disk  
> **Catatan:** Nginx sudah ter-install global di VPS — kita pakai itu sebagai reverse proxy, bukan Nginx di Docker.

---

## Daftar Isi

1. [Prerequisites VPS](#1-prerequisites-vps)
2. [DNS Setup](#2-dns-setup)
3. [Clone & Configure](#3-clone--configure)
4. [Deploy (Step-by-step)](#4-deploy-step-by-step)
5. [Issue SSL Certificate](#5-issue-ssl-certificate)
6. [Enable HTTPS](#6-enable-https)
7. [Verifikasi](#7-verifikasi)
8. [Maintenance Commands](#8-maintenance-commands)
9. [Update / Redeploy](#9-update--redeploy)
10. [Monitoring & Logs](#10-monitoring--logs)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Prerequisites VPS

SSH ke VPS, pastikan sudah ter-install:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker (kalau belum)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin (kalau belum ada)
sudo apt install docker-compose-plugin -y

# Install Make & Git
sudo apt install make git -y

# Install Certbot untuk Nginx (SSL Let's Encrypt)
sudo apt install certbot python3-certbot-nginx -y

# Logout & login ulang supaya docker group aktif
exit
```

Verifikasi:
```bash
docker --version        # Docker 24+
docker compose version  # v2.x
nginx -v                # nginx/1.x
certbot --version       # certbot 2.x
git --version
```

### Firewall

```bash
# Buka port yang dibutuhkan
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirect ke HTTPS + Certbot)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
sudo ufw status
```

> ⚠️ **JANGAN** buka port 5432 (Postgres) dan 6379 (Redis) ke public — hanya bisa diakses via Docker internal network.

---

## 2. DNS Setup

Di DNS provider (Cloudflare / Niagahoster / dll), tambahkan **A record**:

| Type | Name | Value | TTL |
|---|---|---|---|
| A | `besmartexam` | `<IP_VPS_KAMU>` | Auto / 300 |

Kalau pakai **Cloudflare**, set proxy status ke **DNS only** (grey cloud) dulu sampai SSL Let's Encrypt berhasil.

Verifikasi DNS sudah propagate:
```bash
# Dari VPS atau lokal
ping besmartexam.jiilan.me
# Harus resolve ke IP VPS kamu

# Atau
dig besmartexam.jiilan.me +short
```

---

## 3. Clone & Configure

```bash
# Clone repository
cd /opt
sudo mkdir -p smartexam && sudo chown $USER:$USER smartexam
cd smartexam
git clone <REPO_URL> besmartedutelu
cd besmartedutelu
```

### Setup Environment File

```bash
cp .env.example .env
nano .env
```

Edit `.env` untuk **production**:

```env
# ── App ─────────────────────────────────────────────
SERVER_PORT=8080

# ── PostgreSQL (GANTI PASSWORD!) ────────────────────
DB_NAME=smartedutelu
DB_USERNAME=postgres
DB_PASSWORD=GantiDenganPasswordKuat123!

# ── Redis (GANTI PASSWORD!) ────────────────────────
REDIS_PASSWORD=GantiDenganRedisPassKuat456!

# ── JWT (WAJIB GENERATE!) ──────────────────────────
# Generate: openssl rand -base64 64
JWT_SECRET=<PASTE_HASIL_GENERATE_DI_SINI>

# ── CORS ────────────────────────────────────────────
CORS_ALLOWED_ORIGINS=https://smartexam.jiilan.me

# ── Mail (Gmail App Password) ──────────────────────
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=xxxx-xxxx-xxxx-xxxx
MAIL_FROM=noreply@smartexam.com

# ── Password Reset URL ─────────────────────────────
PASSWORD_RESET_URL=https://smartexam.jiilan.me/reset-password

# ── Seeder (aktifkan HANYA pertama kali) ───────────
SEEDER_ENABLED=true
```

Generate JWT secret:
```bash
openssl rand -base64 64
```

> ⚠️ **PENTING:**  
> - Ganti SEMUA password default  
> - JWT_SECRET harus unique dan panjang  
> - Setelah deploy pertama, set `SEEDER_ENABLED=false`

---

## 4. Deploy (Step-by-step)

### Step 1: Start Docker containers (app + postgres + redis)

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

Tunggu sampai semua healthy:
```bash
docker compose -f docker-compose.prod.yml ps
# Pastikan postgres, redis, app semua "healthy" / "running"
```

Cek logs app:
```bash
docker compose -f docker-compose.prod.yml logs -f app
# Tunggu sampai: "Started SmarteduteluApplication in X seconds"
# Ctrl+C untuk keluar
```

Test app langsung (dari VPS):
```bash
curl http://127.0.0.1:8080/api/actuator/health
# Harus return: {"status":"UP"}
```

> App bind ke `127.0.0.1:8080` — hanya bisa diakses dari VPS sendiri (localhost), tidak terbuka ke internet.

### Step 2: Setup Nginx reverse proxy

Copy site config dari repo ke Nginx global:

```bash
sudo cp nginx/conf.d/default.conf /etc/nginx/sites-available/besmartexam.jiilan.me
sudo ln -sf /etc/nginx/sites-available/besmartexam.jiilan.me /etc/nginx/sites-enabled/
```

Test config:
```bash
sudo nginx -t
```

> ⚠️ Kalau error SSL certificate not found — itu normal! Kita issue SSL di step berikutnya.  
> Untuk sementara, comment dulu block `server { listen 443 ... }` atau langsung lanjut ke step SSL.

---

## 5. Issue SSL Certificate

Pakai Certbot bawaan VPS — otomatis konfigurasi Nginx:

```bash
sudo certbot --nginx -d besmartexam.jiilan.me
```

Certbot akan:
1. Verifikasi domain (HTTP challenge via Nginx)
2. Issue SSL certificate dari Let's Encrypt
3. **Otomatis modify** config Nginx untuk SSL
4. Setup auto-renewal

> Ikuti prompt — masukkan email dan accept Terms of Service.

Kalau berhasil:
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/besmartexam.jiilan.me/fullchain.pem
```

Verifikasi auto-renewal:
```bash
sudo certbot renew --dry-run
```

---

## 6. Verifikasi Deployment

### Reload Nginx (kalau belum)
```bash
sudo nginx -t && sudo systemctl reload nginx
```

### Test HTTPS
```bash
curl https://besmartexam.jiilan.me/api/actuator/health
# Harus return: {"status":"UP"}
```

---

## 7. Test API Endpoints

### Test Register
```bash
curl -s -X POST https://besmartexam.jiilan.me/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Deploy",
    "email": "test@example.com",
    "password": "TestDeploy@123"
  }' | python3 -m json.tool
```

### Test Login
```bash
curl -s -X POST https://besmartexam.jiilan.me/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@smartexam.com",
    "password": "admin123"
  }' | python3 -m json.tool
```

### Swagger UI
Buka browser: `https://besmartexam.jiilan.me/api/swagger-ui.html`

### SSL Check
```bash
curl -vI https://besmartexam.jiilan.me 2>&1 | grep -E "SSL|subject|expire|issuer"
```

Atau cek di: https://www.ssllabs.com/ssltest/analyze.html?d=besmartexam.jiilan.me

---

## 8. Maintenance Commands

```bash
cd /opt/smartexam/besmartedutelu

# ── Docker Status ───────────────────────────────────
docker compose -f docker-compose.prod.yml ps

# ── Logs ────────────────────────────────────────────
docker compose -f docker-compose.prod.yml logs -f           # Semua
docker compose -f docker-compose.prod.yml logs -f app       # App saja
docker compose -f docker-compose.prod.yml logs -f postgres  # DB saja

# ── Restart App ─────────────────────────────────────
docker compose -f docker-compose.prod.yml restart app

# ── Stop semua containers ───────────────────────────
docker compose -f docker-compose.prod.yml down

# ── Start semua containers ──────────────────────────
docker compose -f docker-compose.prod.yml up -d

# ── DB Shell ────────────────────────────────────────
docker exec -it smartedutelu-postgres psql -U postgres -d smartedutelu

# ── Nginx (global) ─────────────────────────────────
sudo nginx -t                      # Test config
sudo systemctl reload nginx        # Reload config
sudo systemctl restart nginx       # Restart Nginx
sudo tail -f /var/log/nginx/besmartexam.access.log   # Access log
sudo tail -f /var/log/nginx/besmartexam.error.log    # Error log

# ── SSL ─────────────────────────────────────────────
sudo certbot renew --dry-run       # Test renewal
sudo certbot renew                 # Manual renew
sudo certbot certificates          # List certificates

# ── Disk usage ──────────────────────────────────────
docker system df
```

---

## 9. Update / Redeploy

Kalau ada update code:

```bash
cd /opt/smartexam/besmartedutelu

# Pull latest code
git pull origin main

# Rebuild & restart app only (zero-downtime-ish)
docker compose -f docker-compose.prod.yml up -d app --build --force-recreate

# Cek logs
docker compose -f docker-compose.prod.yml logs -f app
```

Kalau DB migration berubah, Flyway otomatis running saat app start — tidak perlu manual.

---

## 10. Monitoring & Logs

### Log Rotation (recommended)

Buat file `/etc/docker/daemon.json`:
```bash
sudo nano /etc/docker/daemon.json
```

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
```

### Cron: SSL Auto-Renew

Certbot sudah otomatis setup systemd timer saat install. Verifikasi:

```bash
sudo systemctl status certbot.timer
```

Kalau tidak aktif, aktifkan:
```bash
sudo systemctl enable --now certbot.timer
```

### Cron: Docker Cleanup

```bash
# Cleanup images lama setiap minggu
0 4 * * 0 docker image prune -af --filter "until=168h"
```

---

## 11. Troubleshooting

### App tidak start

```bash
# Cek logs
docker compose -f docker-compose.prod.yml logs app --tail 100

# Cek apakah Postgres ready
docker compose -f docker-compose.prod.yml exec postgres pg_isready

# Cek env vars
docker compose -f docker-compose.prod.yml exec app env | grep -E "DB_|JWT|REDIS"
```

### 502 Bad Gateway (Nginx)

```bash
# App belum healthy — cek status
docker compose -f docker-compose.prod.yml ps

# Cek apakah app bisa diakses dari localhost
curl http://127.0.0.1:8080/api/actuator/health

# Cek Nginx error log
sudo tail -20 /var/log/nginx/besmartexam.error.log
```

### SSL certificate gagal

```bash
# Pastikan DNS sudah resolve ke IP VPS
dig besmartexam.jiilan.me +short

# Pastikan port 80 terbuka
sudo ufw status

# Pastikan Nginx jalan
sudo systemctl status nginx

# Retry issue certificate
sudo certbot --nginx -d besmartexam.jiilan.me --force-renewal
```

### Database connection refused

```bash
# Cek Postgres container
docker compose -f docker-compose.prod.yml ps postgres
docker compose -f docker-compose.prod.yml logs postgres --tail 50

# Restart Postgres
docker compose -f docker-compose.prod.yml restart postgres
```

### Out of memory

```bash
# Cek memory usage
docker stats --no-stream

# Kalau JVM pakai terlalu banyak, set limit di docker-compose.prod.yml:
# deploy:
#   resources:
#     limits:
#       memory: 768M
```

### Redis connection failed (rate limit disabled)

```bash
docker compose -f docker-compose.prod.yml ps redis
docker compose -f docker-compose.prod.yml exec redis redis-cli -a $REDIS_PASSWORD ping
```

---

## Architecture Diagram

```
  Internet
     │
     ▼
┌──────────┐
│   DNS    │  besmartexam.jiilan.me → IP VPS
└────┬─────┘
     │
     ▼
┌───────────────────────────────────────────────────────┐
│  VPS                                                  │
│                                                       │
│  ┌─────────────────────────────────────────────────┐  │
│  │  Nginx (global, host-level)                     │  │
│  │  :80 (redirect) / :443 (SSL termination)        │  │
│  │  Certbot auto-renew via systemd timer           │  │
│  └────────────┬────────────────────────────────────┘  │
│               │ proxy_pass http://127.0.0.1:8080      │
│               ▼                                       │
│  ┌─────────────────────────────────────────────────┐  │
│  │  Docker Compose (prod)                          │  │
│  │                                                 │  │
│  │  ┌────────────────┐                             │  │
│  │  │  Spring Boot   │ 127.0.0.1:8080 (loopback)  │  │
│  │  │  /api/*        │                             │  │
│  │  └───────┬────────┘                             │  │
│  │          │                                      │  │
│  │  ┌───────┴─────────┐  ┌─────────────────┐      │  │
│  │  │   PostgreSQL    │  │     Redis       │      │  │
│  │  │   :5432 (内部)  │  │  :6379 (内部)   │      │  │
│  │  └─────────────────┘  └─────────────────┘      │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│  Firewall: hanya port 22, 80, 443 terbuka             │
└───────────────────────────────────────────────────────┘
```

> **Catatan:**  
> - Nginx **global** di host — bukan di Docker (tidak konflik dengan site lain)  
> - App bind ke `127.0.0.1:8080` — hanya bisa diakses dari localhost  
> - Postgres & Redis **TIDAK** expose port ke luar — Docker internal network  
> - Nginx handle SSL termination — traffic ke Spring Boot HTTP biasa  
> - Certbot auto-renew via systemd timer (otomatis saat install `python3-certbot-nginx`)

---

## Quick Start (TL;DR)

```bash
# 1. SSH ke VPS
ssh user@<IP_VPS>

# 2. Install Docker + Certbot (kalau belum)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && exit
# Login ulang
sudo apt install docker-compose-plugin make git certbot python3-certbot-nginx -y

# 3. Firewall
sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw enable

# 4. Clone & configure
cd /opt && sudo mkdir -p smartexam && sudo chown $USER:$USER smartexam
cd smartexam && git clone <REPO> besmartedutelu && cd besmartedutelu
cp .env.example .env && nano .env  # Edit semua password + JWT_SECRET

# 5. Deploy Docker containers
docker compose -f docker-compose.prod.yml up -d --build

# 6. Setup Nginx site
sudo cp nginx/conf.d/default.conf /etc/nginx/sites-available/besmartexam.jiilan.me
sudo ln -sf /etc/nginx/sites-available/besmartexam.jiilan.me /etc/nginx/sites-enabled/

# 7. Issue SSL (otomatis configure Nginx)
sudo certbot --nginx -d besmartexam.jiilan.me

# 8. Verify
curl https://besmartexam.jiilan.me/api/actuator/health

# 9. Disable seeder
# Edit .env → SEEDER_ENABLED=false
# docker compose -f docker-compose.prod.yml restart app
```
