import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/payment_error_view.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';
import 'package:shimmer/shimmer.dart';

class PaymentOverviewTab extends StatelessWidget {
  const PaymentOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicPaymentBloc, ClinicPaymentState>(
      builder: (context, state) {
        if (state is ClinicPaymentLoading || state is ClinicPaymentInitial) {
          return const _OverviewSkeleton();
        }
        if (state is ClinicPaymentError) {
          return PaymentErrorView(
            message: state.message,
            onRetry: () => context.read<ClinicPaymentBloc>().add(ClinicPaymentFetchRequested()),
          );
        }

        if (state is ClinicPaymentLoaded) {
          final data = state.overview;
          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: AdminColors.surface,
            onRefresh: () async {
              context.read<ClinicPaymentBloc>().add(ClinicPaymentFetchRequested());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRevenueBlock(data),
                  const SizedBox(height: 24),
                  _buildPaymentAnalyticsCard(data),
                  const SizedBox(height: 24),
                  _buildFeeCard(context, state),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildRevenueBlock(Map<String, dynamic> data) {
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
    final diff = data['lastMonthDiff'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doanh thu tháng này',
          style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: revenue),
          duration: const Duration(seconds: 2),
          curve: Curves.easeOutQuart,
          builder: (context, val, child) {
            final parts = val.toInt().toString().split('').reversed.toList();
            final str = List.generate(parts.length, (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i]).reversed.join();
            return Text(
              '$strđ',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AdminColors.textPrimary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 14,
              color: diff >= 0 ? AdminColors.success : AdminColors.danger,
            ),
            const SizedBox(width: 4),
            Text(
              '${diff >= 0 ? '+' : ''}$diff giao dịch so với tháng trước',
              style: GoogleFonts.inter(fontSize: 12, color: diff >= 0 ? AdminColors.success : AdminColors.danger),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentAnalyticsCard(Map<String, dynamic> data) {
    final totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
    final paidCount = (data['paidCount'] as num?)?.toInt() ?? 0;
    final pendingCount = (data['pendingCount'] as num?)?.toInt() ?? 0;
    final todayCount = (data['todayCount'] as num?)?.toInt() ?? 0;
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;

    final pendingRevenue = (data['pendingRevenue'] as num?)?.toDouble() ?? 0.0;
    final potentialRevenue = revenue + pendingRevenue;
    final paidPercent = totalCount > 0 ? (paidCount / totalCount) : 0.0;
    final pendingPercent = totalCount > 0 ? (pendingCount / totalCount) : 0.0;
    
    String formatCurrency(double val) {
      final parts = val.toInt().toString().split('').reversed.toList();
      return '${List.generate(
        parts.length,
        (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i],
      ).reversed.join()}đ';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: AppTheme.kPrimary),
              const SizedBox(width: 8),
              Text(
                'THỐNG KÊ LỊCH HẸN & THANH TOÁN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Đã TT ${(paidPercent * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (totalCount > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (paidPercent > 0)
                      Expanded(
                        flex: (paidPercent * 1000).toInt(),
                        child: Container(color: AdminColors.success),
                      ),
                    if (pendingPercent > 0)
                      Expanded(
                        flex: (pendingPercent * 1000).toInt(),
                        child: Container(color: AdminColors.warning),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: _buildDetailStatTile(
                  title: 'Tổng lịch hẹn',
                  value: '$totalCount',
                  subtitle: 'Đặt trong tháng',
                  icon: Icons.calendar_month_outlined,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailStatTile(
                  title: 'Hôm nay',
                  value: '$todayCount',
                  subtitle: 'Yêu cầu mới',
                  icon: Icons.today_outlined,
                  color: AdminColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailStatTile(
                  title: 'Đã thanh toán',
                  value: '$paidCount',
                  subtitle: totalCount > 0 ? '${(paidPercent * 100).toStringAsFixed(1)}%' : '0.0%',
                  icon: Icons.check_circle_outline_rounded,
                  color: AdminColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailStatTile(
                  title: 'Chưa thanh toán',
                  value: '$pendingCount',
                  subtitle: totalCount > 0 ? '${(pendingPercent * 100).toStringAsFixed(1)}%' : '0.0%',
                  icon: Icons.pending_actions_rounded,
                  color: AdminColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AdminColors.border, height: 1),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng doanh thu dự kiến',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tính cả lịch hẹn chưa thanh toán',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                formatCurrency(potentialRevenue),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AdminColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(BuildContext context, ClinicPaymentLoaded loaded) {
    final fee = loaded.consultationFee;
    final updatedAt = loaded.feeUpdatedAt;
    final dateStr = updatedAt != null
        ? '${updatedAt.day.toString().padLeft(2, '0')}/${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}'
        : 'Chưa cập nhật';

    final rawParts = fee.toString().split('').reversed.toList();
    final feeStr = List.generate(
      rawParts.length,
      (i) => (i > 0 && i % 3 == 0) ? '${rawParts[i]}.' : rawParts[i],
    ).reversed.join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 16, color: AppTheme.kPrimary),
              const SizedBox(width: 8),
              Text(
                'CẤU HÌNH PHÍ KHÁM',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$feeStrđ',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.textPrimary,
                ),
              ),
              const Spacer(),
              ScaleOnTap(
                onTap: () => _showFeeDialog(context, fee),
                scaleDownFactor: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Chỉnh sửa',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Cập nhật lần cuối: $dateStr',
            style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFeeDialog(BuildContext context, int currentFee) {
    final ctrl = TextEditingController(text: currentFee.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cập nhật phí khám',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AdminColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            suffixText: 'VND',
            suffixStyle: GoogleFonts.inter(color: AdminColors.textSecondary),
            filled: true,
            fillColor: AdminColors.elevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.kPrimary),
            ),
          ),
        ),
        actions: [
          ScaleOnTap(
            onTap: () => Navigator.pop(ctx),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('Hủy', style: GoogleFonts.inter(color: AdminColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          ScaleOnTap(
            onTap: () {
              final fee = int.tryParse(ctrl.text.replaceAll('.', ''));
              if (fee != null && fee > 0) {
                context.read<ClinicPaymentBloc>().add(ClinicPaymentFeeUpdateRequested(fee));
              }
              Navigator.pop(ctx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Lưu', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AdminColors.surface,
      highlightColor: AdminColors.elevated,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 140, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 36, width: 220, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 14, width: 180, color: Colors.white),
            const SizedBox(height: 32),
            Container(height: 150, width: double.infinity, color: Colors.white),
            const SizedBox(height: 32),
            Container(height: 120, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
