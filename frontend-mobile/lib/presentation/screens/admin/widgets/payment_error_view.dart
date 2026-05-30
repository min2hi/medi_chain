import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

class PaymentErrorView extends StatefulWidget {
  const PaymentErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  State<PaymentErrorView> createState() => _PaymentErrorViewState();
}

class _PaymentErrorViewState extends State<PaymentErrorView> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    setState(() => _retrying = true);
    widget.onRetry();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isServerError = widget.message == 'server_cold_start' ||
        widget.message.toLowerCase().contains('server') ||
        widget.message.toLowerCase().contains('500') ||
        widget.message.toLowerCase().contains('connect');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdminColors.border),
              ),
              child: Icon(
                isServerError ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                size: 32,
                color: AdminColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isServerError ? 'Máy chủ không phản hồi' : 'Không thể tải dữ liệu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isServerError
                  ? 'Backend đang khởi động (Render free tier\nmất ~30s). Vui lòng thử lại sau.'
                  : widget.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AdminColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ScaleOnTap(
              onTap: _retrying ? null : _handleRetry,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _retrying ? AppTheme.kPrimary.withValues(alpha: 0.5) : AppTheme.kPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_retrying)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _retrying ? 'Đang kết nối lại...' : 'Thử lại',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
