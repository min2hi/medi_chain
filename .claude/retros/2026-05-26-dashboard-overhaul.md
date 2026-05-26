## [2026-05-26] Dashboard UI Overhaul + Appointment Flow Fix

### Đã làm

- Redesign toàn bộ patient dashboard (DashboardScreen + 5 widgets)
- Tập trung hóa design tokens vào AppTheme (dark/light palette)
- Migration 30 screens từ hardcoded Color() sang AppTheme tokens
- Upgrade AppointmentListScreen: form 3 fields (lý do + ngày giờ + ghi chú)
- Fix bug Quick Action "Đặt lịch" không mở dialog (IndexedStack caching)
- Tạo shared widget library: AppCard, SectionHeader, StaggeredListItem, StatusBadge
- Xóa dead route /appointment-new
- Commit 11 atomic commits theo dependency order
- Build APK debug thành công, flutter analyze 0 issues

### Vấn đề gặp phải & cách giải quyết

**Vấn đề 1: File bị corrupt do patch tool apply sai vị trí**
- Nguyên nhân: multi_replace_file_content có "inaccuracies" khi file đã bị hỏng
- Hậu quả: cascade failure — code cũ bị lẫn ở cuối file, syntax error lan rộng
- Fix: git checkout HEAD -- file.dart → view_file kiểm tra → write_to_file rewrite sạch
- Lesson: KHÔNG patch tiếp lên file đã bị lỗi. Reset → hiểu → rewrite.

**Vấn đề 2: openAddDialog: bool không hoạt động với IndexedStack**
- Nguyên nhân: _screens được khởi tạo trong initState → bool chỉ đọc 1 lần
- Fix: ValueNotifier<int> counter pattern — listener trong initState, dispose bắt buộc
- Lesson: Khi screen đã mount trong IndexedStack, props mới không trigger initState lại

**Vấn đề 3: 65 files uncommitted, không kiểm soát được**
- Nguyên nhân: Nhiều sessions fix nhỏ lẻ, không commit theo nhóm
- Fix: Lập plan commit → nhóm theo concern → 11 atomic commits
- Lesson: Không để > 15 files uncommitted. Commit ngay sau feature hoàn chỉnh.

**Vấn đề 4: Cách tiếp cận không professional (patch → patch → patch)**
- Nguyên nhân: Không dùng git để kiểm tra trạng thái, không có plan trước khi edit
- Fix: git status + git diff trước → plan rõ → verify sau mỗi edit
- Lesson: Senior nhìn toàn cảnh trước, code sau.

### Còn dang dở

- Backend Prisma generated client có thay đổi chưa commit (cần commit riêng)
- 52 packages cần update (không urgent, không break hiện tại)
- Medicine form chưa được upgrade lên form đầy đủ như appointment
- Chưa có unit tests cho ValueNotifier trigger logic

### Phải nhớ buổi sau

1. **ValueNotifier pattern** khi cần trigger action cho screen trong IndexedStack
2. **Quy trình khi file corrupt**: checkout → view → rewrite → analyze
3. **Kiểm tra git status** đầu mỗi buổi để biết trạng thái thực
4. **AppTheme tokens** — không hardcode Color() trong widget mới
5. **Shared widgets** đã có tại `lib/presentation/widgets/shared/` — dùng lại, không tạo mới
6. **Commit ngay** sau feature, không để tích lũy
