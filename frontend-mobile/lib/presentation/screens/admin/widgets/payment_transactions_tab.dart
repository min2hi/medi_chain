import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';
import 'package:shimmer/shimmer.dart';

class PaymentTransactionsTab extends StatefulWidget {
  const PaymentTransactionsTab({super.key});

  @override
  State<PaymentTransactionsTab> createState() => _PaymentTransactionsTabState();
}

class _PaymentTransactionsTabState extends State<PaymentTransactionsTab> {
  String _filter = 'ALL';

  static const _filters = {
    'ALL': 'Tất cả',
    'PAID': 'Đã TT',
    'PENDING': 'Chờ',
    'FAILED': 'Đã hủy'
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips — minimal, pill style with ScaleOnTap feedback
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((e) {
                final selected = _filter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ScaleOnTap(
                    onTap: () => setState(() => _filter = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.kPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.kPrimary : AdminColors.border,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? Colors.white : AdminColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Transaction list
        Expanded(
          child: BlocBuilder<ClinicPaymentBloc, ClinicPaymentState>(
            builder: (context, state) {
              if (state is ClinicPaymentLoading || state is ClinicPaymentInitial) {
                return const _TransactionsSkeleton();
              }
              if (state is ClinicPaymentLoaded) {
                final items = state.transactions
                    .where((t) => _filter == 'ALL' || t['status'] == _filter)
                    .toList();
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AdminColors.elevated,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Icon(Icons.receipt_long_outlined, size: 28, color: AdminColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Chưa có giao dịch nào',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _filter == 'ALL'
                              ? 'Giao dịch sẽ xuất hiện khi bệnh nhân thanh toán'
                              : 'Không có giao dịch với bộ lọc này',
                          style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return RepaintBoundary(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (context2, i2) => const Divider(height: 1, color: AdminColors.border),
                    itemBuilder: (context, i) {
                      final tx = items[i];
                      final date = DateTime.tryParse(tx['date'] ?? '')?.toLocal();
                      final dateStr = date != null ? '${date.day}/${date.month}' : '';
                      return _TxRow(
                        name: tx['patientName'] ?? 'Ẩn danh',
                        type: tx['type'] ?? 'Dịch vụ',
                        date: dateStr,
                        amount: (tx['amount'] as num?)?.toInt() ?? 0,
                        status: tx['status'] ?? 'UNKNOWN',
                      );
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.name,
    required this.type,
    required this.date,
    required this.amount,
    required this.status,
  });
  final String name, type, date, status;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'PAID':
        statusColor = AdminColors.success;
        statusLabel = 'Đã TT';
        break;
      case 'PENDING':
        statusColor = AdminColors.warning;
        statusLabel = 'Chờ TT';
        break;
      case 'FAILED':
        statusColor = AdminColors.textMuted;
        statusLabel = 'Đã hủy';
        break;
      default:
        statusColor = AdminColors.danger;
        statusLabel = 'Thất bại';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text('$type · $date', style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(amount ~/ 1000)}k',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AdminColors.surface,
      highlightColor: AdminColors.elevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(height: 14, width: 40, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 10, width: 50, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
