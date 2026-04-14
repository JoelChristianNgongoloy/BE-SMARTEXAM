# 🚀 Deployment Guide — SmartExam Backend

> **Domain:** `besmartexam.jiilan.me`  
> **Stack:** Docker Compose + Nginx + Let's Encrypt SSL  
> **VPS minimum:** 1 vCPU, 2GB RAM, 20GB disk  

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

SSH ke VPS, lalu install:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin (kalau belum ada)
sudo apt install docker-compose-plugin -y

# Install Make & Git
sudo apt install make git -y

# Logout & login ulang supaya docker group aktif
exit
```

Verifikasi:
```bash
docker --version        # Docker 24+
docker compose version  # v2.x
git --version
make --version
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

### Step 1: Start dengan HTTP dulu (tanpa SSL)

Pakai Nginx config yang HTTP-only dulu untuk Certbot challenge:

```bash
# Pakai config init (HTTP only)
cp nginx/conf.d/default.conf.init nginx/conf.d/default.conf.bak
cp nginx/conf.d/default.conf nginx/conf.d/default.conf.ssl
cp nginx/conf.d/default.conf.init nginx/conf.d/default.conf
```

Start semua service **tanpa** nginx dulu:

```bash
docker compose -f docker-compose.prod.yml up -d postgres redis
```

Tunggu sampai healthy:
```bash
docker compose -f docker-compose.prod.yml ps
# Pastikan postgres dan redis status "healthy"
```

Build & start app:
```bash
docker compose -f docker-compose.prod.yml up -d app --build
```

Tunggu app healthy (~60 detik):
```bash
# Cek logs
docker compose -f docker-compose.prod.yml logs -f app

# Tunggu sampai muncul: "Started SmarteduteluApplication in X seconds"
# Ctrl+C untuk keluar logs
```

Start Nginx:
```bash
docker compose -f docker-compose.prod.yml up -d nginx
```

Test HTTP:
```bash
curl http://besmartexam.jiilan.me/api/actuator/health
# Harus return: {"status":"UP"}
```

---

## 5. Issue SSL Certificate

Sekarang Nginx sudah jalan di HTTP, kita bisa issue SSL certificate via Let's Encrypt:

```bash
docker compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@gmail.com \
    --agree-tos \
    --no-eff-email \
    -d besmartexam.jiilan.me
```

> Ganti `your-email@gmail.com` dengan email kamu (untuk notifikasi expiry).

Kalau berhasil, output:
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/besmartexam.jiilan.me/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/besmartexam.jiilan.me/privkey.pem
```

---

## 6. Enable HTTPS

Sekarang switch ke Nginx config yang full HTTPS:

```bash
# Restore config SSL
cp nginx/conf.d/default.conf.ssl nginx/conf.d/default.conf
```

Reload Nginx:
```bash
docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

Start Certbot auto-renewal:
```bash
docker compose -f docker-compose.prod.yml up -d certbot
```

Test HTTPS:
```bash
curl https://besmartexam.jiilan.me/api/actuator/health
# Harus return: {"status":"UP"}
```

---

## 7. Verifikasi

### Health Check
```bash
curl -s https://besmartexam.jiilan.me/api/actuator/health | python3 -m json.tool
```

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

# ── Status ──────────────────────────────────────────
docker compose -f docker-compose.prod.yml ps

# ── Logs ────────────────────────────────────────────
docker compose -f docker-compose.prod.yml logs -f           # Semua
docker compose -f docker-compose.prod.yml logs -f app       # App saja
docker compose -f docker-compose.prod.yml logs -f nginx     # Nginx saja
docker compose -f docker-compose.prod.yml logs -f postgres  # DB saja

# ── Restart ─────────────────────────────────────────
docker compose -f docker-compose.prod.yml restart app
docker compose -f docker-compose.prod.yml restart nginx

# ── Stop semua ──────────────────────────────────────
docker compose -f docker-compose.prod.yml down

# ── Start semua ─────────────────────────────────────
docker compose -f docker-compose.prod.yml up -d

# ── DB Shell ────────────────────────────────────────
docker exec -it smartedutelu-postgres psql -U postgres -d smartedutelu

# ── Renew SSL manual ───────────────────────────────
docker compose -f docker-compose.prod.yml run --rm certbot renew

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

### Cron: SSL Auto-Renew (backup)

Certbot container sudah handle auto-renew, tapi buat backup via cron:

```bash
sudo crontab -e
```

Tambahkan:
```cron
# Renew SSL setiap hari Senin jam 03:00
0 3 * * 1 cd /opt/smartexam/besmartedutelu && docker compose -f docker-compose.prod.yml run --rm certbot renew --quiet && docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
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

# Cek apakah app bisa diakses dari internal
docker compose -f docker-compose.prod.yml exec nginx wget -qO- http://app:8080/api/actuator/health
```

### SSL certificate gagal

```bash
# Pastikan DNS sudah resolve ke IP VPS
dig besmartexam.jiilan.me +short

# Pastikan port 80 terbuka
sudo ufw status

# Cek Nginx error log
docker compose -f docker-compose.prod.yml logs nginx

# Retry issue certificate
docker compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email your-email@gmail.com --agree-tos --no-eff-email \
    -d besmartexam.jiilan.me --force-renewal
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
┌──────────────────────────────────────────────┐
│  VPS                                         │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │  Docker Compose (prod)                 │  │
│  │                                        │  │
│  │  ┌──────────┐     ┌────────────────┐   │  │
│  │  │  Nginx   │────▶│  Spring Boot   │   │  │
│  │  │  :80/443 │     │  :8080 (内部)  │   │  │
│  │  │  SSL+RP  │     │  /api/*        │   │  │
│  │  └──────────┘     └───────┬────────┘   │  │
│  │       │                   │            │  │
│  │  ┌────┴────┐    ┌────────┴─────────┐   │  │
│  │  │Certbot  │    │    PostgreSQL    │   │  │
│  │  │(renew)  │    │    :5432 (内部)  │   │  │
│  │  └─────────┘    └─────────────────┘   │  │
│  │                 ┌─────────────────┐   │  │
│  │                 │     Redis       │   │  │
│  │                 │  :6379 (内部)   │   │  │
│  │                 └─────────────────┘   │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  Firewall: hanya port 22, 80, 443 terbuka    │
└──────────────────────────────────────────────┘
```

> **Catatan:**  
> - Postgres & Redis **TIDAK** expose port ke luar — hanya bisa diakses via Docker internal network  
> - Nginx handle SSL termination — traffic ke Spring Boot **HTTP biasa** (internal)  
> - Certbot auto-renew SSL setiap 6 jam (cek) + cron backup mingguan

---

## Quick Start (TL;DR)

```bash
# 1. SSH ke VPS
ssh user@<IP_VPS>

# 2. Install Docker + Make + Git
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && exit
# Login ulang
sudo apt install docker-compose-plugin make git -y

# 3. Firewall
sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw enable

# 4. Clone & configure
cd /opt && sudo mkdir -p smartexam && sudo chown $USER:$USER smartexam
cd smartexam && git clone <REPO> besmartedutelu && cd besmartedutelu
cp .env.example .env && nano .env  # Edit semua password + JWT_SECRET

# 5. Deploy (HTTP dulu)
cp nginx/conf.d/default.conf nginx/conf.d/default.conf.ssl
cp nginx/conf.d/default.conf.init nginx/conf.d/default.conf
docker compose -f docker-compose.prod.yml up -d --build

# 6. Issue SSL
docker compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email you@email.com --agree-tos --no-eff-email \
    -d besmartexam.jiilan.me

# 7. Enable HTTPS
cp nginx/conf.d/default.conf.ssl nginx/conf.d/default.conf
docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
docker compose -f docker-compose.prod.yml up -d certbot

# 8. Verify
curl https://besmartexam.jiilan.me/api/actuator/health

# 9. Disable seeder
# Edit .env → SEEDER_ENABLED=false
# docker compose -f docker-compose.prod.yml restart app
```
