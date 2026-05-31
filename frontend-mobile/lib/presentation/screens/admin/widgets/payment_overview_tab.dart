import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/payment_error_view.dart';
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
                  _buildRevenueGlassCard(data),
                  const SizedBox(height: 20),
                  _RevenueChart(transactions: state.transactions),
                  const SizedBox(height: 20),
                  _buildPaymentAnalyticsCard(data),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildRevenueGlassCard(Map<String, dynamic> data) {
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
    final pendingRevenue = (data['pendingRevenue'] as num?)?.toDouble() ?? 0.0;
    final potentialRevenue = revenue + pendingRevenue;
    final diff = data['lastMonthDiff'] ?? 0;

    String formatCurrency(double val) {
      final parts = val.toInt().toString().split('').reversed.toList();
      return '${List.generate(
        parts.length,
        (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i],
      ).reversed.join()}đ';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminColors.surface,
            AdminColors.elevated,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOANH THU THỰC NHẬN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency(revenue),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AdminColors.border,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOANH THU DỰ KIẾN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.info,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency(potentialRevenue),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AdminColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: diff >= 0 ? AdminColors.success : AdminColors.danger,
              ),
              const SizedBox(width: 5),
              Text(
                '${diff >= 0 ? '+' : ''}$diff giao dịch so với tháng trước',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: diff >= 0 ? AdminColors.success : AdminColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAnalyticsCard(Map<String, dynamic> data) {
    final totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
    final paidCount = (data['paidCount'] as num?)?.toInt() ?? 0;
    final pendingCount = (data['pendingCount'] as num?)?.toInt() ?? 0;
    final todayCount = (data['todayCount'] as num?)?.toInt() ?? 0;

    final paidPercent = totalCount > 0 ? (paidCount / totalCount) : 0.0;
    final pendingPercent = totalCount > 0 ? (pendingCount / totalCount) : 0.0;

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
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (paidPercent > 0)
                      Expanded(
                        flex: (paidPercent * 1000).toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AdminColors.success, Color(0xFF34D399)],
                            ),
                          ),
                        ),
                      ),
                    if (pendingPercent > 0)
                      Expanded(
                        flex: (pendingPercent * 1000).toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AdminColors.warning, Color(0xFFFBBF24)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
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
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.15)),
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
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AdminColors.textSecondary,
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
}

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _RevenueChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Lấy danh sách 7 ngày gần nhất bao gồm hôm nay
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    // 2. Tính tổng doanh thu PAID cho từng ngày
    final dailyRevenue = <String, double>{};
    for (final day in last7Days) {
      final key = '${day.year}-${day.month}-${day.day}';
      dailyRevenue[key] = 0.0;
    }

    for (final tx in transactions) {
      final status = tx['status'] as String? ?? 'UNKNOWN';
      if (status != 'PAID') continue; // chỉ vẽ doanh thu thực nhận

      final dateStr = tx['date'] as String? ?? '';
      final dt = DateTime.tryParse(dateStr)?.toLocal();
      if (dt != null) {
        final key = '${dt.year}-${dt.month}-${dt.day}';
        if (dailyRevenue.containsKey(key)) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          dailyRevenue[key] = dailyRevenue[key]! + amt;
        }
      }
    }

    final dataPoints = last7Days.map((day) {
      final key = '${day.year}-${day.month}-${day.day}';
      return dailyRevenue[key] ?? 0.0;
    }).toList();

    // Tìm giá trị max để scale đồ thị
    double maxVal = 0.0;
    for (final v in dataPoints) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0.0) maxVal = 10000.0; // fallback tránh chia cho 0

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
              Icon(Icons.show_chart_rounded, size: 16, color: AppTheme.kPrimary),
              const SizedBox(width: 8),
              Text(
                'XU HƯỚNG DOANH THU 7 NGÀY QUA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(
                dataPoints: dataPoints,
                maxVal: maxVal,
                days: last7Days,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final double maxVal;
  final List<DateTime> days;
  _ChartPainter({
    required this.dataPoints,
    required this.maxVal,
    required this.days,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Vẽ các đường lưới ngang và nhãn trục Y
    final gridPaint = Paint()
      ..color = AdminColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final double chartHeight = size.height - 24; // chừa khoảng trống cho nhãn X ở đáy
    final double stepY = chartHeight / 3;

    for (int i = 0; i <= 3; i++) {
      final y = chartHeight - (i * stepY);
      // Vẽ nét đứt bằng cách vẽ từng đoạn nhỏ
      const double dashWidth = 5.0;
      const double dashSpace = 4.0;
      double startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Nhãn trục Y (bên phải hoặc nhỏ phía trên đường)
      final yVal = (maxVal / 3) * i;
      final yValStr = yVal >= 1000000
          ? '${(yVal / 1000000).toStringAsFixed(1)}M'
          : yVal >= 1000
              ? '${(yVal / 1000).toStringAsFixed(0)}k'
              : '${yVal.toInt()}';

      textPainter.text = TextSpan(
        text: yValStr,
        style: GoogleFonts.robotoMono(
          fontSize: 8,
          color: AdminColors.textSecondary.withValues(alpha: 0.6),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 12));
    }

    // 2. Tính tọa độ các điểm trên đồ thị
    final double stepX = size.width / (dataPoints.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (dataPoints[i] / maxVal) * chartHeight;
      points.add(Offset(x, y));
    }

    // 3. Vẽ vùng Gradient tô dưới đường đồ thị
    if (points.isNotEmpty) {
      final fillPath = Path()
        ..moveTo(points.first.dx, chartHeight)
        ..lineTo(points.first.dx, points.first.dy);

      // Nối các điểm bằng đường cong Bezier
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX1 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY1 = p1.dy;
        final controlX2 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY2 = p2.dy;
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p2.dx, p2.dy);
      }

      fillPath.lineTo(points.last.dx, chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.kPrimary.withValues(alpha: 0.18),
            AppTheme.kPrimary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // 4. Vẽ đường cong Bezier chính (chỉ số doanh thu)
    if (points.isNotEmpty) {
      final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX1 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY1 = p1.dy;
        final controlX2 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY2 = p2.dy;
        strokePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p2.dx, p2.dy);
      }

      final strokePaint = Paint()
        ..color = AppTheme.kPrimary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(strokePath, strokePaint);
    }

    // 5. Vẽ nhãn trục X (Ngày trong tuần) ở đáy đồ thị
    for (int i = 0; i < days.length; i++) {
      final x = i * stepX;
      final dayStr = '${days[i].day}/${days[i].month}';
      textPainter.text = TextSpan(
        text: dayStr,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: AdminColors.textSecondary,
        ),
      );
      textPainter.layout();
      // Canh lề giữa nhãn
      final labelOffset = Offset(x - (textPainter.width / 2), size.height - 14);
      // Đảm bảo nhãn không bị tràn viền trái/phải của đồ thị
      final double clampedX = labelOffset.dx.clamp(0.0, size.width - textPainter.width);
      textPainter.paint(canvas, Offset(clampedX, labelOffset.dy));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints || oldDelegate.maxVal != maxVal;
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
