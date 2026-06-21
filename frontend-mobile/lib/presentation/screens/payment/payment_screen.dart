import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/payment/payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/routes/payment_routes.dart';

/// Màn hình thanh toán — tham khảo ZocDoc payment confirmation screen.
/// Design principle: "Show exactly what they're paying for, make CTA unmissable."
class PaymentScreen extends StatefulWidget {
  final PaymentArgs args;

  const PaymentScreen({
    super.key,
    required this.args,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch sau frame đầu tiên để BLocProvider từ Router đã mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PaymentBloc>().add(PaymentFeeRequested(
          appointmentId: widget.args.appointmentId,
          appointmentTitle: widget.args.appointmentTitle,
          appointmentDate: widget.args.appointmentDate,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentOrderCreated) {
          // Kiểm tra: nếu giá PayOS khác giá hiển thị trước — thông báo user
          final prevState = context.read<PaymentBloc>().state;
          if (prevState is PaymentFeeLoaded && prevState.fee != state.amount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Phí khám đã được cập nhật: '
                  '${NumberFormat.currency(locale: "vi_VN", symbol: "đ", decimalDigits: 0).format(state.amount)}',
                ),
                backgroundColor: AppTheme.kPrimaryDark,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          PaymentRoutes.openCheckout(
            context,
            CheckoutArgs(
              checkoutUrl: state.checkoutUrl,
              orderCode: state.orderCode,
            ),
          );
        }
        if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context),
          body: switch (state) {
            PaymentLoading() => const Center(
                child: CircularProgressIndicator(color: AppTheme.kPrimaryDark),
              ),
            PaymentFeeLoaded() => _buildContent(context, state),
            PaymentError() => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => context.read<PaymentBloc>().add(
                              PaymentFeeRequested(
                                appointmentId: widget.args.appointmentId,
                                appointmentTitle: widget.args.appointmentTitle,
                                appointmentDate: widget.args.appointmentDate,
                              ),
                            ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            _ => const Center(
                child: CircularProgressIndicator(color: AppTheme.kPrimaryDark),
              ),
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF182030) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0D1520),
          ),
        ),
      ),
      title: const Text(
        'Thanh toán',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  Widget _buildContent(BuildContext context, PaymentFeeLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.tryParse(state.appointmentDate);
    final formattedDate = date != null
        ? DateFormat('EEEE, dd/MM/yyyy – HH:mm', 'vi').format(date)
        : state.appointmentDate;
    final formattedFee = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(state.fee);

    const depositAmount = 50000;
    final remainingAmount = (state.fee - depositAmount) < 0 ? 0 : (state.fee - depositAmount);
    final formattedDeposit = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(depositAmount);
    final formattedRemaining = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(remainingAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Appointment Summary Card (ZocDoc style) ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182030) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.kPrimaryDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.stethoscope,
                        size: 22,
                        color: AppTheme.kPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.appointmentTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0D1520),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Payment Breakdown ─────────────────────────────────────────────
          Text(
            'Chi tiết thanh toán đặt cọc',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182030) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildLineItem(context, 'Phí khám tư vấn (Tổng cộng)', formattedFee, isDark),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
                  indent: 20,
                  endIndent: 20,
                ),
                _buildLineItem(context, 'Thanh toán tại quầy sau khám', formattedRemaining, isDark,
                    valueColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
                  indent: 20,
                  endIndent: 20,
                ),
                _buildLineItem(context, 'Phí dịch vụ trực tuyến', 'Miễn phí', isDark,
                    valueColor: const Color(0xFF10B981)),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiền đặt cọc trực tuyến',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0D1520),
                        ),
                      ),
                      Text(
                        formattedDeposit,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Payment Method Info ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kPrimaryDark.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.kPrimaryDark.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shield, size: 18, color: AppTheme.kPrimaryDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đặt cọc giữ chỗ trực tuyến qua PayOS — hỗ trợ QR Banking, ATM, Visa/Mastercard',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── CTA Button ────────────────────────────────────────────────────
          BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              final isLoading = state is PaymentLoading;
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => context.read<PaymentBloc>().add(
                            PaymentOrderCreateRequested(widget.args.appointmentId),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kPrimaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: AppTheme.kPrimaryDark.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.creditCard, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Thanh toán đặt cọc $formattedDeposit',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Huỷ
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Huỷ bỏ',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0D1520)),
            ),
          ),
        ],
      ),
    );
  }
}



