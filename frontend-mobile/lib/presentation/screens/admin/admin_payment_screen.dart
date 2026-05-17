import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';

/// AdminPaymentScreen — redesigned.
/// Stripe Dashboard / Linear style: number-first, no gradient cards.
class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ClinicPaymentBloc>()..add(ClinicPaymentFetchRequested()),
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [_OverviewTab(), _TransactionsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Text(
        'Tài Chính',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.kPrimary,
        unselectedLabelColor: AdminColors.textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppTheme.kPrimary, width: 2),
          insets: const EdgeInsets.symmetric(horizontal: 8),
        ),
        dividerColor: AdminColors.border,
        tabs: const [Tab(text: 'Tổng quan'), Tab(text: 'Giao dịch')],
      ),
    );
  }
}

// ─── Tab 1: Overview ──────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicPaymentBloc, ClinicPaymentState>(
      builder: (context, state) {
        if (state is ClinicPaymentFeeUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật phí khám', style: GoogleFonts.inter()),
              backgroundColor: AdminColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is ClinicPaymentLoading || state is ClinicPaymentInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ClinicPaymentError) {
          return Center(child: Text(state.message, style: GoogleFonts.inter(color: AdminColors.danger)));
        }

        if (state is ClinicPaymentLoaded) {
          final data = state.overview;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRevenueBlock(data),
                const SizedBox(height: 24),
                const Divider(color: AdminColors.border),
                const SizedBox(height: 20),
                _buildStatsRow(data),
                const SizedBox(height: 24),
                const Divider(color: AdminColors.border),
                const SizedBox(height: 20),
                _buildFeeSection(context, state),
              ],
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
            // Format number to currency
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
            Icon(diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: diff >= 0 ? AdminColors.success : AdminColors.danger),
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

  Widget _buildStatsRow(Map<String, dynamic> data) {
    // todayCount thật từ API
    final todayCount = (data['todayCount'] as num?)?.toInt() ?? 0;
    return Row(
      children: [
        _StatItem(label: 'Tổng GD', value: '${data['totalCount'] ?? 0}'),
        _Divider(),
        _StatItem(label: 'Đã TT', value: '${data['paidCount'] ?? 0}'),
        _Divider(),
        _StatItem(label: 'Đang chờ', value: '${data['pendingCount'] ?? 0}', valueColor: AdminColors.warning),
        _Divider(),
        _StatItem(label: 'Hôm nay', value: '$todayCount'),
      ],
    );
  }

  Widget _buildFeeSection(BuildContext context, ClinicPaymentLoaded loaded) {
    final fee = loaded.consultationFee;
    final updatedAt = loaded.feeUpdatedAt;
    final dateStr = updatedAt != null
        ? '${updatedAt.day.toString().padLeft(2,'0')}/${updatedAt.month.toString().padLeft(2,'0')}/${updatedAt.year}'
        : 'Chưa cập nhật';

    // Format fee: 200000 -> 200.000đ
    final rawParts = fee.toString().split('').reversed.toList();
    final feeStr = List.generate(
      rawParts.length,
      (i) => (i > 0 && i % 3 == 0) ? '${rawParts[i]}.' : rawParts[i],
    ).reversed.join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHÍ KHÁM',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AdminColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$feeStr\u0111',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showFeeDialog(context, fee),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Chỉnh sửa'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cập nhật lần cuối: $dateStr',
          style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textMuted),
        ),
      ],
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: AdminColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              final fee = int.tryParse(ctrl.text.replaceAll('.', ''));
              if (fee != null && fee > 0) {
                context.read<ClinicPaymentBloc>().add(ClinicPaymentFeeUpdateRequested(fee));
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Lưu', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AdminColors.textPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AdminColors.border,
    );
  }
}

// ─── Tab 2: Transactions ──────────────────────────────────────────────────────
class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab();

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  String _filter = 'ALL';

  static const _filters = {
    'ALL': 'Tất cả', 'PAID': 'Đã TT', 'PENDING': 'Chờ', 'FAILED': 'Thất bại'
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips — minimal, pill style
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((e) {
                final selected = _filter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ClinicPaymentLoaded) {
                final items = state.transactions.where((t) => _filter == 'ALL' || t['status'] == _filter).toList();
                if (items.isEmpty) {
                  return Center(child: Text('Không có giao dịch', style: GoogleFonts.inter(color: AdminColors.textMuted)));
                }
                return ListView.separated(
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
    required this.name, required this.type, required this.date,
    required this.amount, required this.status,
  });
  final String name, type, date, status;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'PAID': statusColor = AdminColors.success; statusLabel = 'Đã TT';
      case 'PENDING': statusColor = AdminColors.warning; statusLabel = 'Chờ';
      default: statusColor = AdminColors.danger; statusLabel = 'Thất bại';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AdminColors.textPrimary)),
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
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.textPrimary, fontFeatures: [const FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 2),
              Text(statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}
