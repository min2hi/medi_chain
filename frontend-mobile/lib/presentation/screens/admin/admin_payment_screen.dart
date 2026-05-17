import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// AdminPaymentScreen — Quản lý thanh toán (chỉ ADMIN).
/// Tab 1: Tổng quan (revenue stats + phí khám)
/// Tab 2: Giao dịch (transaction list với filter)
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
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(),
                  const _TransactionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AdminColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài Chính',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              Text(
                'Quản lý thanh toán & doanh thu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AdminColors.success,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AdminColors.textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Giao dịch'),
        ],
      ),
    );
  }
}

// ─── Tab 1: Overview ──────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doanh thu tháng này',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1,400,000đ',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '+3 giao dịch so với tháng trước',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tổng giao dịch',
                  value: '7',
                  icon: Icons.receipt_long_rounded,
                  color: AdminColors.aiPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Đã thanh toán',
                  value: '5',
                  icon: Icons.check_circle_rounded,
                  color: AdminColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Đang chờ',
                  value: '2',
                  icon: Icons.pending_rounded,
                  color: AdminColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Hôm nay',
                  value: '1',
                  icon: Icons.today_rounded,
                  color: AdminColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Consultation fee setting
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded,
                        size: 16, color: AdminColors.aiPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Phí khám tư vấn',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '200,000đ',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showEditFeeDialog(context),
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('Chỉnh sửa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.aiPrimary,
                        side: BorderSide(
                            color: AdminColors.aiPrimary.withValues(alpha: 0.5)),
                        textStyle:
                            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cập nhật lần cuối: 17/05/2026',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditFeeDialog(BuildContext context) {
    final controller = TextEditingController(text: '200000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cập nhật phí khám',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AdminColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Phí khám (VND)',
            labelStyle: GoogleFonts.inter(color: AdminColors.textSecondary),
            suffixText: 'VND',
            filled: true,
            fillColor: AdminColors.elevated,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.aiPrimary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: GoogleFonts.inter(color: AdminColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: call PaymentService.setConsultationFee
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật phí khám: ${controller.text} VND',
                      style: GoogleFonts.inter()),
                  backgroundColor: AdminColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.aiPrimary,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('Lưu',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'PAID', 'PENDING', 'FAILED'].map((f) {
                final isSelected = _filter == f;
                final label = {'ALL': 'Tất cả', 'PAID': 'Đã thanh toán',
                    'PENDING': 'Đang chờ', 'FAILED': 'Thất bại'}[f]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AdminColors.success
                            : AdminColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AdminColors.success
                              : AdminColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : AdminColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) => _TransactionRow(
              patientName: 'Nguyễn Văn ${String.fromCharCode(65 + index)}',
              appointmentTitle: 'Khám tổng quát',
              date: '${17 - index}/05/2026',
              amount: 200000,
              status: index == 1 ? 'PENDING' : (index == 3 ? 'FAILED' : 'PAID'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.patientName,
    required this.appointmentTitle,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String patientName;
  final String appointmentTitle;
  final String date;
  final int amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'PAID':
        statusColor = AdminColors.success;
        statusLabel = 'Đã thanh toán';
      case 'PENDING':
        statusColor = AdminColors.warning;
        statusLabel = 'Đang chờ';
      default:
        statusColor = AdminColors.danger;
        statusLabel = 'Thất bại';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(
              status == 'PAID'
                  ? Icons.check_rounded
                  : status == 'PENDING'
                      ? Icons.access_time_rounded
                      : Icons.close_rounded,
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  '$appointmentTitle · $date',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(amount / 1000).toStringAsFixed(0)}k VND',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
