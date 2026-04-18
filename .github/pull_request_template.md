## 📝 Mô tả thay đổi
<!-- Thay đổi gì? Giải quyết vấn đề gì? Link issue nếu có (Closes #123) -->


## 🏷️ Loại thay đổi
- [ ] ✨ Tính năng mới (`feat`)
- [ ] 🐛 Sửa lỗi (`fix`)
- [ ] ♻️ Refactor — không thêm feature, không fix bug
- [ ] 📝 Tài liệu (`docs`)
- [ ] 🔧 CI/CD / Cấu hình
- [ ] ⚡ Cải thiện hiệu năng (`perf`)

## ✅ Checklist Kỹ Thuật
- [ ] Code đã chạy được ở local
- [ ] Không có `console.log` debug trong production code
- [ ] Không có hardcoded secrets/API keys
- [ ] CI pipeline pass ✅ (security scan + build + lint)
- [ ] Đã chạy Impact Analysis trước khi sửa hàm cũ (`gitnexus_impact`)
- [ ] Tất cả callers d=1 đã được cập nhật đồng bộ

## 🔐 Security & Data
- [ ] Không có thay đổi nào ảnh hưởng đến authentication/authorization
- [ ] Dữ liệu user không bị leak qua API response mới
- [ ] Không có SQL injection/XSS vector mới nào được giới thiệu
- [ ] Thay đổi có cần database migration không? `[ ] Có` `[ ] Không`

## 🗄️ Database (nếu có migration)
- [ ] Migration đã được test ở local
- [ ] Migration có thể rollback được (`prisma migrate reset` OK)
- [ ] Không có breaking change cho data cũ đang có sẵn trong DB

## 🔄 Kế hoạch Rollback
<!-- Nếu deploy xong bị lỗi, làm sao revert? -->
- [ ] Chỉ cần `git revert` + redeploy
- [ ] Cần rollback migration: `npx prisma migrate resolve --rolled-back`
- [ ] Cần thao tác manual khác (mô tả bên dưới):
