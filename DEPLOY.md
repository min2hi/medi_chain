# 🚀 MediChain — Hướng Dẫn Deploy Production

## Tóm tắt kiến trúc

```
Internet
    │
    ▼
[Nginx :80]          ← Entry point duy nhất
    │
    ├── /api/* ──────► [Backend Express :5000]
    │                         │
    │                         ▼
    │                   [PostgreSQL :5432]  (internal only)
    │
    └── /* ──────────► [Frontend Next.js :3000]
```

---

## Bước 1: Chuẩn bị server

### Option A: VPS (DigitalOcean / Vultr / Linode)

Yêu cầu tối thiểu:
- Ubuntu 22.04 LTS
- RAM: 2GB (4GB khuyến nghị cho AI)
- CPU: 2 vCPU
- Disk: 20GB SSD

```bash
# SSH vào server
ssh root@YOUR_SERVER_IP

# Cài Docker
curl -fsSL https://get.docker.com | sh
sudo systemctl enable docker
sudo systemctl start docker

# Cài Docker Compose plugin
sudo apt install docker-compose-plugin -y

# Kiểm tra
docker --version
docker compose version
```

### Option B: Test local trên máy Windows (đang có Docker Desktop)

Bước 1-3 bên dưới chạy trực tiếp trên máy của bạn luôn — không cần VPS.

---

## Bước 2: Clone project lên server

```bash
git clone https://github.com/YOUR_USERNAME/medi_chain.git
cd medi_chain
```

**Hoặc upload bằng SCP/SFTP từ máy Windows:**
```powershell
# Chạy trên Windows PowerShell
scp -r d:\StudioProjects\medi_chain root@YOUR_SERVER_IP:/root/medi_chain
```

---

## Bước 3: Tạo file environment variables

```bash
# Copy template
cp .env.production.example .env.production

# Mở và điền giá trị thật
nano .env.production
```

**Cần điền:**
| Biến | Cách lấy |
|---|---|
| `POSTGRES_PASSWORD` | Tự tạo password mạnh (min 20 ký tự) |
| `JWT_SECRET` | Chạy: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` |
| `GEMINI_API_KEY` | [https://ai.google.dev/](https://ai.google.dev/) → Get API Key |
| `GROQ_API_KEY` | [https://console.groq.com/](https://console.groq.com/) → API Keys |
| `EMAIL_USER` + `EMAIL_PASS` | Gmail → Settings → Security → App Passwords |
| `FRONTEND_URL` | `http://YOUR_SERVER_IP` hoặc `https://yourdomain.com` |

---

## Bước 4: Deploy!

```bash
# Build tất cả Docker images (lần đầu mất 5-10 phút)
docker compose -f docker-compose.prod.yml --env-file .env.production build

# Chạy stack ở background
docker compose -f docker-compose.prod.yml --env-file .env.production up -d

# Xem logs realtime
docker compose -f docker-compose.prod.yml logs -f

# Xem status
docker compose -f docker-compose.prod.yml ps
```

**Expected output:**
```
NAME                  STATUS          PORTS
medichain-db          healthy         (internal)
medichain-backend     running         (internal)
medichain-frontend    running         (internal)
medichain-nginx       running         0.0.0.0:80->80/tcp
```

---

## Bước 5: Kiểm tra

```bash
# Test API
curl http://localhost/api
# → "MediChain API is running..."

# Test frontend
curl -I http://localhost
# → HTTP/1.1 200 OK
```

Mở browser: `http://YOUR_SERVER_IP`

---

## Lệnh hữu ích hàng ngày

```bash
# Xem logs backend
docker compose -f docker-compose.prod.yml logs backend -f

# Restart 1 service cụ thể (không down service khác)
docker compose -f docker-compose.prod.yml restart backend

# Stop tất cả (data vẫn giữ)
docker compose -f docker-compose.prod.yml down

# Stop và XÓA data (cẩn thận!)
docker compose -f docker-compose.prod.yml down -v

# Update code và redeploy
git pull
docker compose -f docker-compose.prod.yml --env-file .env.production build backend
docker compose -f docker-compose.prod.yml --env-file .env.production up -d backend

# Xem resource usage
docker stats
```

---

## Thêm HTTPS / SSL (Khuyến nghị sau khi có domain)

### Option 1: Cloudflare (miễn phí, dễ nhất)
1. Trỏ domain về server IP
2. Enable Cloudflare proxy (cam màu vàng)
3. Cloudflare tự handle HTTPS — không cần làm gì thêm

### Option 2: Let's Encrypt + Certbot
```bash
# Cài certbot
sudo apt install certbot -y

# Dừng nginx
docker compose -f docker-compose.prod.yml stop nginx

# Lấy cert
sudo certbot certonly --standalone -d yourdomain.com

# Update nginx/nginx.conf để dùng SSL
# Restart nginx
docker compose -f docker-compose.prod.yml up -d nginx
```

---

## Troubleshooting

### Backend không start?
```bash
docker compose -f docker-compose.prod.yml logs backend
# Thường do: sai DATABASE_URL hoặc JWT_SECRET chưa set
```

### DB chưa ready?
```bash
docker compose -f docker-compose.prod.yml ps db
# Nếu status "starting" — đợi thêm 30s cho DB init
```

### Port 80 bị occupied?
```bash
# Kiểm tra
netstat -tulpn | grep :80
# Kill process đang dùng port 80
sudo fuser -k 80/tcp
```
