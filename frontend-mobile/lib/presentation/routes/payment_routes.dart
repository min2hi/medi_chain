import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Typed Route Args ─────────────────────────────────────────────────────────
// Pattern: Flutter team navigation guide (2024) — typed extras thay vì Map<String,String>
// Lợi ích:
//   1. Compile-time safety — typo được catch ngay
//   2. Single source of truth — đổi field tên ở 1 chỗ
//   3. Không cần null fallback che giấu lỗi

/// Args để navigate đến màn hình thanh toán
class PaymentArgs {
  final String appointmentId;
  final String appointmentTitle;
  final String appointmentDate;

  const PaymentArgs({
    required this.appointmentId,
    required this.appointmentTitle,
    required this.appointmentDate,
  });
}

/// Args sau khi tạo đơn PayOS thành công — truyền vào WebView
class CheckoutArgs {
  final String checkoutUrl;
  final String orderCode;

  const CheckoutArgs({
    required this.checkoutUrl,
    required this.orderCode,
  });
}

/// Args cho màn hình xác nhận thành công
class PaymentSuccessArgs {
  final String orderCode;
  const PaymentSuccessArgs({required this.orderCode});
}

// ─── Route Registry ───────────────────────────────────────────────────────────
// Single source of truth cho tất cả payment route paths.
// Không hardcode '/payment' ở bất kỳ đâu ngoài class này.

class PaymentRoutes {
  PaymentRoutes._(); // Prevent instantiation

  // ── Paths ────────────────────────────────────────────────────────────────
  static const String payment = '/payment';
  static const String checkout = '/payment/checkout';
  static const String success = '/payment/success';

  // ── Type-safe navigation helpers ─────────────────────────────────────────
  // Gọi những hàm này thay vì context.push('/payment', extra: {...})
  // → Typo hoặc missing field sẽ bị compiler bắt ngay

  /// Patient taps "Thanh toán ngay" trên appointment card
  static void openPayment(BuildContext context, PaymentArgs args) {
    context.push(payment, extra: args);
  }

  /// PaymentScreen dispatch sau khi tạo order PayOS thành công
  static void openCheckout(BuildContext context, CheckoutArgs args) {
    context.push(checkout, extra: args);
  }

  /// WebViewScreen navigate sau khi verify webhook trả về PAID
  static void openSuccess(BuildContext context, String orderCode) {
    context.pushReplacement(success, extra: PaymentSuccessArgs(orderCode: orderCode));
  }

  /// Success screen quay về HomeScreen (có bottom nav) và tự switch sang tab Lịch hẹn (index 3).
  /// KHÔNG dùng '/appointments' vì route đó tạo standalone page không có bottom nav.
  static void backToAppointments(BuildContext context) {
    context.go('/', extra: {'initialTab': 3});
  }
}
