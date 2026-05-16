import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
                child: CircularProgressIndicator(color: Color(0xFF0D9488)),
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
                child: CircularProgressIndicator(color: Color(0xFF0D9488)),
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
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                        color: const Color(0xFF0D9488).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.stethoscope,
                        size: 22,
                        color: Color(0xFF0D9488),
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
            'Chi tiết thanh toán',
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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildLineItem(context, 'Phí khám tư vấn', formattedFee, isDark),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  indent: 20,
                  endIndent: 20,
                ),
                _buildLineItem(context, 'Phí dịch vụ', 'Miễn phí', isDark,
                    valueColor: const Color(0xFF10B981)),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        formattedFee,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D9488),
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
              color: const Color(0xFF0D9488).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0D9488).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shield, size: 18, color: Color(0xFF0D9488)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thanh toán an toàn qua PayOS — hỗ trợ QR Banking, ATM, Visa/Mastercard',
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
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF0D9488).withOpacity(0.5),
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
                              'Thanh toán $formattedFee',
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
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
