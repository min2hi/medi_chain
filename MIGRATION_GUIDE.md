# 🔄 Migration Instructions - Hướng dẫn Chạy Migration

## ⚠️ Quan trọng

Bạn **PHẢI** chạy migration để tạo các bảng mới trong database trước khi sử dụng tính năng Recommendation và AI Chat.

---

## 📋 Checklist

- [ ] Docker Desktop đang chạy
- [ ] PostgreSQL container đang chạy
- [ ] Backend dependencies đã được cài đặt

---

## 🚀 Các bước thực hiện

### Bước 1: Kiểm tra Docker Desktop

Đảm bảo Docker Desktop đang chạy. Nếu chưa, hãy mở Docker Desktop.

### Bước 2: Start PostgreSQL Database

```powershell
# Từ thư mục root của project
cd "d:\StudioProjects\medi_chain web"

# Start database container
docker-compose up -d db

# Kiểm tra container đang chạy
docker ps
```

Bạn sẽ thấy output tương tự:
```
CONTAINER ID   IMAGE                  STATUS         PORTS
abc123def456   postgres:15-alpine     Up 10 seconds  0.0.0.0:5435->5432/tcp
```

### Bước 3: Chạy Prisma Migration

```powershell
# Di chuyển vào thư mục backend
cd backend

# Chạy migration (tạo các bảng mới)
npx prisma migrate dev --name add_recommendation_and_ai_features
```

**Output mong đợi:**
```
Prisma schema loaded from prisma\schema.prisma
Datasource "db": PostgreSQL database "medichain_db"

Applying migration `20260203_add_recommendation_and_ai_features`

The following migration(s) have been created and applied from new schema changes:

migrations/
  └─ 20260203_add_recommendation_and_ai_features/
      └─ migration.sql

Your database is now in sync with your schema.

✔ Generated Prisma Client
```

### Bước 4: Generate Prisma Client

```powershell
# Generate Prisma Client với types mới
npx prisma generate
```

**Output mong đợi:**
```
✔ Generated Prisma Client to .\src\generated\client
```

### Bước 5: Seed Health Rules (Tùy chọn nhưng khuyến nghị)

**Option A: Qua API (Đơn giản hơn)**

```powershell
# Start backend server trước
npm run dev

# Trong terminal khác, gọi API seed
curl -X POST http://localhost:5000/api/recommendations/seed-rules
```

**Option B: Chạy script trực tiếp**

```powershell
npx tsx src/scripts/seed-recommendations.ts
```

**Output mong đợi:**
```
🌱 Bắt đầu seed health rules...

✅ Đã tạo 6 health rules

👥 Tìm thấy X users

  ✓ User Nguyen Van A: 3 recommendations
  ✓ User Tran Thi B: 2 recommendations

✅ Tổng cộng đã tạo Y recommendations cho X users

🎉 Hoàn thành!
```

### Bước 6: Verify Migration

```powershell
# Mở Prisma Studio để xem database
npx prisma studio
```

Truy cập `http://localhost:5555` và kiểm tra:
- ✅ Bảng `HealthRule` có 6 records
- ✅ Bảng `Recommendation` có data (nếu đã seed)
- ✅ Bảng `AIConversation` tồn tại
- ✅ Bảng `AIMessage` tồn tại

---

## 🔍 Troubleshooting

### Lỗi: "Can't reach database server at `127.0.0.1:5435`"

**Nguyên nhân**: PostgreSQL chưa chạy

**Giải pháp**:
```powershell
# Kiểm tra Docker
docker ps

# Nếu không thấy postgres container, start lại
docker-compose up -d db

# Đợi 5-10 giây cho database khởi động
# Sau đó chạy lại migration
npx prisma migrate dev
```

### Lỗi: "Docker daemon is not running"

**Nguyên nhân**: Docker Desktop chưa mở

**Giải pháp**:
1. Mở Docker Desktop
2. Đợi Docker khởi động hoàn toàn (icon Docker Desktop không còn loading)
3. Chạy lại `docker-compose up -d db`

### Lỗi: "Migration engine error"

**Nguyên nhân**: Database đang bị lock hoặc connection issue

**Giải pháp**:
```powershell
# Stop tất cả containers
docker-compose down

# Start lại
docker-compose up -d db

# Đợi 10 giây
Start-Sleep -Seconds 10

# Chạy lại migration
cd backend
npx prisma migrate dev
```

### Lỗi: "Property 'aIConversation' does not exist"

**Nguyên nhân**: Prisma Client chưa được generate

**Giải pháp**:
```powershell
cd backend
npx prisma generate
```

### Migration đã chạy nhưng không có data

**Nguyên nhân**: Chưa seed health rules

**Giải pháp**:
```powershell
# Start backend
npm run dev

# Terminal khác
curl -X POST http://localhost:5000/api/recommendations/seed-rules
```

---

## ✅ Verification Checklist

Sau khi hoàn thành migration, kiểm tra:

- [ ] Backend start không có lỗi TypeScript
- [ ] Prisma Studio hiển thị 4 bảng mới
- [ ] `HealthRule` có 6 records
- [ ] Frontend build không có lỗi
- [ ] Dashboard hiển thị RecommendationWidget
- [ ] AI Chat button xuất hiện ở góc dưới phải
- [ ] "Phân tích bởi AI" button xuất hiện trong "Tóm tắt y tế"

---

## 🎯 Next Steps

Sau khi migration thành công:

1. **Start Backend**
   ```powershell
   cd backend
   npm run dev
   ```

2. **Start Frontend** (terminal mới)
   ```powershell
   cd frontend
   npm run dev
   ```

3. **Test Features**
   - Vào Dashboard → Xem RecommendationWidget
   - Click AI Chat button → Test chat
   - Click "Phân tích bởi AI" → Xem analysis

---

## 📞 Support

Nếu gặp vấn đề:
1. Đọc lại `FEATURES_README.md`
2. Kiểm tra logs trong terminal
3. Xem Prisma Studio để verify database state
4. Restart Docker và chạy lại từ đầu

---

**Good luck! 🚀**
