# 🧬 Collaborative Filtering — Phase 2

> **Files:** `src/cron/cf-matrix-builder.ts` · `src/cron/scheduler.ts` · `src/recommendation/scoring.engine.ts`

---

## Vấn đề Phase 1 để lại

| Vấn đề | Hệ quả |
|--------|--------|
| Query toàn bộ Feedback mỗi lần user hỏi (O(N)) | Server sập khi nhiều user đồng thời |
| Ghép Peer Group chỉ theo tuổi + giới | Đưa thuốc sai bối cảnh bệnh |
| Thuốc mới không ai biết → không ai rate | Mãi không lên được top (Famine Cycle) |

---

## Giải pháp: Offline-Online Split

Tách biệt **tính toán nặng (ban đêm)** và **phục vụ nhẹ (ban ngày)**:

```
Ban đêm (2 AM) — OFFLINE:
  Gom toàn bộ Feedback → Tính Weighted Score → Cache vào DB

Ban ngày — ONLINE:
  User hỏi → Engine đọc điểm cache từ DB (O(1), ~0.001ms)
```

---

## Thuật toán tính điểm CF (cf-matrix-builder)

Với mỗi loại thuốc có ≥ 3 feedback:

```
score = outcomeWeight + ratingFactor
                         └─ (rating - 3) × 0.1
```

| Outcome             | outcomeWeight |
|---------------------|:---:|
| EFFECTIVE           | +1.0 |
| PARTIALLY_EFFECTIVE | +0.4 |
| NOT_EFFECTIVE       | -0.5 |
| SIDE_EFFECT         | -1.0 |
| NOT_TAKEN           |  0.0 |

```
rawScore    = average(score mỗi record)
finalScore  = clamp(50 + rawScore × 40, 0, 100)
                     ↑ mốc 50 là trung lập
```

Kết quả lưu vào `DrugCandidate.collaborativeScore`.  
Thuốc < 3 feedback → `null` (cold start, chưa kết luận được).

---

## Ba tầng tính historyScore (scoring.engine)

```
1. User đã dùng thuốc này?    → Dùng lịch sử cá nhân (tin nhất)
2. collaborativeScore != null? → Đọc cache O(1)
3. Không có gì               → 50 (trung lập)
```

**Công thức finalScore:**

```
finalScore = profileScore × profileW + safetyScore × safetyW + historyScore × historyW

Có lịch sử cá nhân: historyW = 30%
Không có lịch sử:   historyW = 20%
```

---

## Epsilon-Greedy — Phá vòng lặp Cold Start

```typescript
const EPSILON = 0.05; // 5% xác suất

if (historyScore === 50 && Math.random() < EPSILON) {
    finalScore += 6.5; // Đẩy thuốc mới lên Top để thu thập feedback
}
```

> **Safety First:** Epsilon chỉ chạy SAU khi Safety Filter đã duyệt thuốc. Thuốc bị loại (dị ứng, tương tác xấu) không bao giờ qua được vòng này.

---

## Bộ hẹn giờ (node-cron)

```
Cron: "0 2 * * *"  →  2:00 AM mỗi ngày (Asia/Ho_Chi_Minh)
```

- **Dev mode:** Chạy ngay khi server khởi động để test
- **Production:** Chạy đúng 2AM, tự động hoàn toàn
- **Lỗi → Log, không crash server**

---

## Thêm: Context Tracking

Khi user gửi Feedback, backend tự ghi thêm `symptomContext` (câu hỏi ban đầu) vào bản ghi. Dữ liệu này là nền tảng để sau này huấn luyện mô hình **Context-Aware CF** (Feedback gắn với bệnh cụ thể, không chỉ theo người).

---

## Kết quả

| | Phase 1 | Phase 2 |
|---|---|---|
| Tốc độ CF | O(N) realtime | O(1) cache |
| Scale | ~1,000 users | ~100,000+ users |
| Cold Start | Mãi là 50đ | Epsilon-Greedy giải cứu |
| Tự động | Không | Cron 2AM hàng ngày |
