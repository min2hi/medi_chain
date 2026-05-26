## [2026-05-26] Hoàn thiện báo cáo đồ án MediChain bằng Python Automation

### Đã làm
- Soạn thảo đầy đủ nội dung Chương 3 (Thiết kế), Chương 4 (Cài đặt), Chương 5 (Kiểm thử), và Tài liệu tham khảo.
- Bổ sung mục 3.5 chi tiết về hai luồng nghiệp vụ cốt lõi (Thanh toán PayOS và Safety check của AI) để vá lỗ hổng lý thuyết học thuật.
- Nâng cấp script `build_clean_report.py` tự động hóa việc xóa nội dung cũ sau paragraph 80 và chèn tuần tự toàn bộ 6 chương cùng danh mục Tài liệu tham khảo vào file Word.
- Chạy công cụ kiểm thử `audit_report.py` xác minh 100% Times New Roman, đúng kích cỡ 13pt/14pt, giãn dòng 1.5, và các bảng biểu được format cell margins + màu nền header sạch đẹp.

### Vấn đề gặp phải & cách giải quyết
- **Lỗi bể font tiếng Việt trong Word**: Khi chèn văn bản thông thường bằng `python-docx`, các ký tự tiếng Việt có dấu phức tạp thường bị Word tự động chuyển sang font phụ (Calibri). Giải quyết bằng cách can thiệp sâu vào XML của run, cấu hình thuộc tính `ascii`, `hAnsi`, `cs` và đặc biệt là `eastAsia` về "Times New Roman".
- **Khóa file do Word mở**: Khi chạy script ghi đè, nếu file đang mở bởi MS Word sẽ bị lỗi permission. Giải quyết bằng cách viết lệnh PowerShell tự động tắt tiến trình `WINWORD` trước khi chạy script compile.

### Phải nhớ buổi sau
- Nhắc người dùng bấm **F9** hoặc chọn **Update Table** ở mục lục tự động của file Word sau khi compile để cập nhật đúng số trang mới.
- Hướng dẫn người dùng chụp các screenshot giao diện và sơ đồ (đã ghi sẵn vị trí `[Hình X.Y]`) để chèn đè lên dòng chỉ dẫn.
