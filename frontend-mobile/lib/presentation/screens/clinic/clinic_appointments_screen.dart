import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';

/// ClinicAppointmentsScreen — redesigned.
/// Design: Time-axis agenda view (Practo Ray / Apple Calendar style).
/// Màu: chỉ dùng status color cho state. Không random icon colors.
class ClinicAppointmentsScreen extends StatefulWidget {
  const ClinicAppointmentsScreen({super.key});

  @override
  State<ClinicAppointmentsScreen> createState() =>
      _ClinicAppointmentsScreenState();
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
    return BlocProvider(
      create: (context) => getIt<ClinicAppointmentBloc>()..add(ClinicAppointmentsFetchRequested()),
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    final day = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day, ${now.day}/${now.month}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lịch Hẹn',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
            builder: (context, state) {
              int pendingCount = 0;
              if (state is ClinicAppointmentsLoaded) {
                pendingCount = state.appointments.where((a) => a['status'] == 'PENDING').length;
              }
              if (pendingCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AdminColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AdminColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$pendingCount chờ duyệt',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.warning,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.kPrimary,
        unselectedLabelColor: AdminColors.textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppTheme.kPrimary, width: 2),
          insets: const EdgeInsets.symmetric(horizontal: 8),
        ),
        dividerColor: AdminColors.border,
        tabs: const [
          Tab(text: 'Chờ duyệt'),
          Tab(text: 'Đã xác nhận'),
          Tab(text: 'Tất cả'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: const [
        _AppointmentList(filter: 'PENDING'),
        _AppointmentList(filter: 'CONFIRMED'),
        _AppointmentList(filter: 'ALL'),
      ],
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────
class _AppointmentList extends StatelessWidget {
  const _AppointmentList({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
      builder: (context, state) {
        if (state is ClinicAppointmentLoading || state is ClinicAppointmentInitial) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(height: 1),
            itemBuilder: (context, index) => const _ShimmerCard(),
          );
        }

        if (state is ClinicAppointmentError) {
          return Center(
            child: Text(state.message, style: GoogleFonts.inter(color: AdminColors.danger)),
          );
        }

        if (state is ClinicAppointmentsLoaded) {
          final items = state.appointments.where((a) => filter == 'ALL' || a['status'] == filter).toList();
          
          if (items.isEmpty) {
            return Center(
              child: Text('Không có lịch hẹn', style: GoogleFonts.inter(color: AdminColors.textMuted, fontSize: 14)),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ListView.separated(
              key: ValueKey('${filter}_${items.length}'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 1),
              itemBuilder: (context, i) {
                final apt = items[i];
                return _AppointmentCard(
                  apt: apt,
                  onConfirm: () => context.read<ClinicAppointmentBloc>().add(
                    ClinicAppointmentStatusUpdateRequested(apt['id'], 'CONFIRMED')
                  ),
                  onReject: () => context.read<ClinicAppointmentBloc>().add(
                    ClinicAppointmentStatusUpdateRequested(apt['id'], 'CANCELLED')
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutSine,
      builder: (context, val, child) {
        return Opacity(
          opacity: val > 0.7 ? 1.4 - val : val, // Pulse effect
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminColors.border, width: 0.5),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 16, color: AdminColors.border),
                const SizedBox(height: 12),
                Container(width: 150, height: 20, color: AdminColors.border),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 12, color: AdminColors.border),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Card — Time-axis, Practo Ray style ───────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.apt,
    required this.onConfirm,
    required this.onReject,
  });
  final Map<String, dynamic> apt;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';

    // Status color + label — cover all 4 Prisma AppStatus values
    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'CONFIRMED':
        statusColor = AdminColors.success;
        statusLabel = 'Đã xác nhận';
      case 'CANCELLED':
        statusColor = AdminColors.danger;
        statusLabel = 'Đã hủy';
      case 'COMPLETED':
        statusColor = AppTheme.kPrimary;
        statusLabel = 'Hoàn thành';
      default: // PENDING
        statusColor = AdminColors.warning;
        statusLabel = 'Chờ duyệt';
    }

    // Format date string from "2026-05-17T14:00:00Z" to "14:00"
    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final isPaid = apt['paymentStatus'] == 'PAID';

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        boxShadow: [
          BoxShadow(
            color: AdminColors.border.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
          top: const BorderSide(color: AdminColors.border, width: 0.5),
          right: const BorderSide(color: AdminColors.border, width: 0.5),
          bottom: const BorderSide(color: AdminColors.border, width: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: time + status
            Row(
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '  ·  30p',
                  style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: patient name
            Text(
              apt['user']?['name'] ?? 'Bệnh nhân ẩn danh',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            // Row 3: type + payment
            Row(
              children: [
                Text(
                  apt['title'] ?? 'Khám dịch vụ',
                  style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Icon(
                  isPaid ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
                  size: 13,
                  color: isPaid ? AdminColors.success : AdminColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isPaid ? AdminColors.success : AdminColors.textMuted,
                  ),
                ),
              ],
            ),
            // Actions — only for pending
            if (isPending) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AdminColors.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: AdminColors.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Từ chối'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.kPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
