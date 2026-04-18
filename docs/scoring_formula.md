# MediChain — Công Thức Tính Điểm Recommendation

## 1. Công Thức Tổng Hợp

```
finalScore = (profileScore × profileW) + (safetyScore × safetyW) + (historyScore × historyW)
```

Trọng số **thay đổi động** tùy theo user có lịch sử hay không:

| Trọng số | User MỚI (cold) | User CÓ lịch sử |
|---|---|---|
| `historyW` | **0.20** | **0.30** |
| `profileW` | 0.35/0.80 × 0.80 = **0.35** | 0.35/0.80 × 0.70 = **0.306** |
| `safetyW` | 0.45/0.80 × 0.80 = **0.45** | 0.45/0.80 × 0.70 = **0.394** |
| **Tổng** | **1.00** | **1.00** |

### Cách tính profileW và safetyW:

```
remainingWeight = 1 - historyW

profileW = PROFILE / (PROFILE + SAFETY) × remainingWeight
safetyW  = SAFETY  / (PROFILE + SAFETY) × remainingWeight
```

> Ý nghĩa: Profile luôn chiếm **43.75%** và Safety **56.25%** của phần không dành cho history — tỷ lệ không đổi dù historyW thay đổi.

---

## 2. Chi Tiết Từng Thành Phần

### 2.1 profileScore (0–100)

Đánh giá mức độ phù hợp thuốc với **triệu chứng + hồ sơ người dùng**

```
baseAI = max(0, similarityFactor - 0.50)   // cosine similarity từ pgvector
score  = min(100, baseAI × 600)

Ví dụ:
  similarity = 0.65 → baseAI = 0.15 → score = 90
  similarity = 0.60 → baseAI = 0.10 → score = 60
  (Khoảng cách 30 điểm giữa tốt và trung bình)

Bonus/Penalty tuổi:
  Phù hợp tuổi    → +10đ
  Dưới tuổi tối thiểu → -30đ
  Vượt tuổi tối đa    → -20đ
```

### 2.2 safetyScore (0–100)

Bắt đầu từ `baseSafetyScore` trong DB (thường 75–80), áp dụng hard filters:

| Điều kiện | Kết quả |
|---|---|
| Thai kỳ + thuốc cấm thai | **Loại ngay (0đ)** |
| Cho con bú + thuốc cấm | **Loại ngay (0đ)** |
| Dị ứng với thành phần | **Loại ngay (0đ)** |
| Bệnh nền trong chống chỉ định | **Loại ngay (0đ)** |
| Tương tác thuốc | **-20đ** (cảnh báo) |

### 2.3 historyScore (0–100) — 3 tầng ưu tiên

**Tầng 1 — Personal** (ưu tiên cao nhất):

```
User đã dùng thuốc này trước đây
  EFFECTIVE:            85 + (rating - 3) × 5
  PARTIALLY_EFFECTIVE:  60 + (rating - 3) × 3
  NOT_EFFECTIVE:        25
  SIDE_EFFECT:           5
  + frequencyBonus: min((count - 1) × 3, 15)
```

**Tầng 2 — Collaborative Filtering:**

```
Chưa dùng nhưng có CF score từ cộng đồng
→ Dùng collaborativeScore từ DB (tính lúc 2AM mỗi đêm)
```

**Tầng 3 — Neutral Fallback:**

```
Không có dữ liệu nào
→ 50 (trung lập, không ảnh hưởng lên hay xuống)
```

---

## 3. Ví Dụ Thực Tế

### Oresol — User mới (~64đ)

```
Vector similarity = 0.62
  baseAI       = 0.62 - 0.50 = 0.12
  profileScore = 0.12 × 600 + 10 (tuổi phù hợp) = 82

baseSafetyScore = 80, không có dị ứng/thai kỳ
  safetyScore = 80

historyScore = 50  (Tầng 3 — user mới, không có CF)

finalScore = (82 × 0.35) + (80 × 0.45) + (50 × 0.20)
           = 28.70 + 36.00 + 10.00
           = 74.7 → ~64–74 (tùy epsilon-greedy ±6.5)
```

### Paracetamol — User có lịch sử, đánh giá 4 sao EFFECTIVE (~86đ)

```
profileScore = 85  (triệu chứng khớp tốt)
safetyScore  = 80

historyScore:
  EFFECTIVE, rating = 4
  recordScore   = 85 + (4 - 3) × 5 = 90
  usageCount = 3 → frequencyBonus = min(2 × 3, 15) = 6
  historyScore  = min(100, 90 + 6) = 96

finalScore = (85 × 0.306) + (80 × 0.394) + (96 × 0.30)
           = 26.01 + 31.52 + 28.80
           = 86.33 → ~86đ
```

---

## 4. Epsilon-Greedy Exploration (5%)

```
Nếu historyScore === 50 (tầng 3 neutral)
  → 5% xác suất: finalScore += 6.5

Mục đích:
  - Đẩy thuốc chưa ai dùng lên Top để thu thập feedback
  - Tránh "Filter Bubble" — chỉ gợi ý mãi thuốc quen
  - Thu dữ liệu để cải thiện Collaborative Filtering
```

---

## 5. Tóm Tắt Nhanh

```
User mới:    finalScore = (profile × 0.35) + (safety × 0.45) + (50 × 0.20)
User thường: finalScore = (profile × 0.35) + (safety × 0.45) + (CF_score × 0.20)
User loyal:  finalScore = (profile × 0.306) + (safety × 0.394) + (personal × 0.30)
```

> **Safety luôn có trọng số cao nhất** — nguyên tắc thiết kế cốt lõi của MediChain: **an toàn trước, phù hợp sau**.
