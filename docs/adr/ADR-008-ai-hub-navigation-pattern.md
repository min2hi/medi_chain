# ADR-008: AI Hub Screen — Navigation Pattern cho mediAI Tab

## Status
Accepted — 2026-04-22

## Context

MediChain Mobile có **2 AI services hoàn toàn khác nhau** về mặt kỹ thuật và UX:

| Service | Screen | Bloc | API Endpoint | Mục đích |
|---|---|---|---|---|
| AI Chatbot | `ChatScreen` | `ChatBloc` | `POST /api/ai/chat` | Hỏi đáp nhanh, lưu lịch sử |
| AI Tư vấn | `ConsultationScreen` | `AIBloc` | `POST /api/ai/consult` | Phân tích triệu chứng, gợi ý thuốc từ hồ sơ |

Trước khi có ADR này:
- Tab `mediAI` trong `HomeScreen` chỉ navigate thẳng vào `ChatScreen`.
- `ConsultationScreen` chỉ accessible qua deep link `context.push('/consultation')` — không có route này trong `AppRouter`.
- Thực tế: `ConsultationScreen` là **dead feature** — không user nào tìm được.

## Options Considered

### Option A — Giữ tab trực tiếp vào ChatScreen, thêm nút trong ChatScreen
- Đặt button "Tư vấn chuyên sâu" trong welcome state của ChatScreen.
- **Pro:** Fewer taps cho user hay dùng Chat.
- **Con:** Tư vấn bị ẩn trong Chat — discovery thấp, mixed responsibility trong màn hình.

### Option B — Thêm tab thứ 7 riêng cho Tư vấn
- **Pro:** 2 entry points rõ ràng.
- **Con:** BottomNav 7 tabs là anti-pattern trên mobile (Google Material Guidelines: ≤5). UX nghèo nàn.

### Option C — AI Hub Screen (đã chọn)
- Tab `mediAI` dẫn vào `AiHubScreen` — màn hình trung gian 2 options.
- **Pro:** Rõ ràng, discoverable, giữ được BottomNav ≤5 tabs.
- **Pro:** Phân biệt rõ 2 service khác nhau cho user.
- **Con:** Thêm 1 tap để vào Chat (minor friction).

## Decision

Chọn **Option C — AI Hub Screen**.

```
HomeScreen (BottomNav tab 4: mediAI)
     └── AiHubScreen
          ├── "Bác sĩ Medi Chat"   → MaterialPageRoute → ChatScreen (ChatBloc)
          └── "Tư vấn Chuyên sâu"  → MaterialPageRoute → ConsultationScreen (AIBloc)
```

**Kỹ thuật quan trọng:**
- Dùng `MaterialPageRoute` (không phải GoRouter `context.push`) để push các AI screens.
- Cả `ChatScreen` và `ConsultationScreen` đều tự wrap `BlocProvider` bên trong — không cần truyền Bloc từ Hub.
- `AiHubScreen` không có state — là `StatelessWidget` thuần (ngoại trừ press animation widget con).

## Consequences

- **Positive:** `ConsultationScreen` không còn là dead feature.
- **Positive:** User hiểu rõ sự khác biệt giữa Chat nhanh và Tư vấn chuyên sâu.
- **Positive:** Đúng pattern của healthcare apps lớn (Ada Health, Babylon Health).
- **Negative:** +1 tap để vào ChatScreen từ BottomNav.
- **Acceptable:** Chat vẫn accessible từ Dashboard Quick Actions nếu cần shortcut.

## References
- `frontend-mobile/lib/presentation/screens/ai/ai_hub_screen.dart` — implementation
- `frontend-mobile/lib/presentation/screens/home/home_screen.dart` — tab swap
- `frontend-mobile/lib/presentation/screens/ai/chat_screen.dart` — BlocProvider(ChatBloc)
- `frontend-mobile/lib/presentation/screens/ai/consultation_screen.dart` — BlocProvider(AIBloc)
- Tham khảo: [Ada Health app architecture](https://ada.com), [Babylon Health](https://babylonhealth.com)
