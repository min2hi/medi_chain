import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// ClinicAppointmentsScreen — Hàng đợi lịch hẹn cho Doctor/Admin.
/// Hiển thị danh sách appointments, cho phép Confirm / Reject từng lịch.
class ClinicAppointmentsScreen extends StatefulWidget {
  const ClinicAppointmentsScreen({super.key});

  @override
  State<ClinicAppointmentsScreen> createState() => _ClinicAppointmentsScreenState();
}

class _ClinicAppointmentsScreenState extends State<ClinicAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabViews()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AdminColors.aiPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AdminColors.aiPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch Hẹn',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Quản lý và xác nhận lịch khám',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _StatChip(label: 'Chờ xác nhận', value: '3', color: AdminColors.warning),
              const SizedBox(width: 8),
              _StatChip(label: 'Hôm nay', value: '5', color: AdminColors.aiPrimary),
              const SizedBox(width: 8),
              _StatChip(label: 'Tuần này', value: '12', color: AdminColors.success),
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
          color: AdminColors.aiPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AdminColors.textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Chờ duyệt'),
          Tab(text: 'Đã xác nhận'),
          Tab(text: 'Tất cả'),
        ],
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _AppointmentList(status: 'PENDING'),
        _AppointmentList(status: 'CONFIRMED'),
        _AppointmentList(status: 'ALL'),
      ],
    );
  }
}

// ─── Appointment List ─────────────────────────────────────────────────────────
class _AppointmentList extends StatelessWidget {
  const _AppointmentList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to AppointmentBloc / API
    // Hiển thị placeholder UI đúng cấu trúc trước
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _AppointmentCard(
        patientName: 'Bệnh nhân ${index + 1}',
        title: 'Khám tổng quát',
        date: '17/05/2026 ${14 + index}:00',
        status: status == 'ALL'
            ? (index == 0 ? 'PENDING' : 'CONFIRMED')
            : status,
        paymentStatus: index == 0 ? 'PAID' : 'UNPAID',
      ),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.patientName,
    required this.title,
    required this.date,
    required this.status,
    required this.paymentStatus,
  });

  final String patientName;
  final String title;
  final String date;
  final String status;
  final String paymentStatus;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'PENDING';
    final isPaid = paymentStatus == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AdminColors.warning.withValues(alpha: 0.4)
              : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminColors.aiPrimary.withValues(alpha: 0.15),
                child: Text(
                  patientName[0],
                  style: GoogleFonts.inter(
                    color: AdminColors.aiPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AdminColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                date,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AdminColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AdminColors.success.withValues(alpha: 0.15)
                      : AdminColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? '✓ Đã thanh toán' : '⏳ Chưa thanh toán',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isPaid ? AdminColors.success : AdminColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(color: AdminColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: reject appointment
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.danger,
                      side: BorderSide(
                          color: AdminColors.danger.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: confirm appointment
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      textStyle: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets nhỏ ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING':
        color = AdminColors.warning;
        label = 'Chờ duyệt';
      case 'CONFIRMED':
        color = AdminColors.success;
        label = 'Đã xác nhận';
      case 'COMPLETED':
        color = AdminColors.info;
        label = 'Hoàn thành';
      case 'CANCELLED':
        color = AdminColors.danger;
        label = 'Đã hủy';
      default:
        color = AdminColors.textMuted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
