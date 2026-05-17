import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'appointment_detail_sheet.dart';

/// ClinicAppointmentsScreen — Agenda view (Practo Ray / Epic Haiku style).
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
    return BlocProvider(
      create: (context) => getIt<ClinicAppointmentBloc>()..add(ClinicAppointmentsFetchRequested()),
      child: BlocListener<ClinicAppointmentBloc, ClinicAppointmentState>(
        listener: (context, state) {
          if (state is ClinicAppointmentActionSuccess) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.inter()),
                backgroundColor: AdminColors.success,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
          if (state is ClinicAppointmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.inter()),
                backgroundColor: AdminColors.danger,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
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

// ─── Appointment List ─────────────────────────────────────────────────────────
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
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => const _ShimmerCard(),
          );
        }

        if (state is ClinicAppointmentError) {
          return _ErrorState(
            message: state.message,
            onRetry: () => context.read<ClinicAppointmentBloc>().add(ClinicAppointmentsFetchRequested()),
          );
        }

        if (state is ClinicAppointmentsLoaded) {
          final items = state.appointments
              .where((a) => filter == 'ALL' || a['status'] == filter)
              .toList();

          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: AdminColors.surface,
            onRefresh: () async {
              context.read<ClinicAppointmentBloc>().add(ClinicAppointmentsRefreshRequested());
              // Đợi state thay đổi
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: items.isEmpty
                ? _EmptyListView(filter: filter)
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ListView.separated(
                      key: ValueKey('${filter}_${items.length}'),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final apt = items[i];
                        return _AppointmentCard(
                          apt: apt,
                          onTap: () => showAppointmentDetail(context, apt),
                          onConfirm: () => context.read<ClinicAppointmentBloc>().add(
                            ClinicAppointmentStatusUpdateRequested(apt['id'], 'CONFIRMED'),
                          ),
                          onReject: () => context.read<ClinicAppointmentBloc>().add(
                            ClinicAppointmentStatusUpdateRequested(apt['id'], 'CANCELLED'),
                          ),
                        );
                      },
                    ),
                  ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

// ─── Empty list (scrollable for pull-to-refresh to work) ─────────────────────
class _EmptyListView extends StatelessWidget {
  const _EmptyListView({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String subtitle;

    switch (filter) {
      case 'PENDING':
        icon = Icons.check_circle_outline_rounded;
        title = 'Không có lịch chờ duyệt';
        subtitle = 'Tất cả lịch hẹn đã được xử lý';
      case 'CONFIRMED':
        icon = Icons.event_available_outlined;
        title = 'Chưa có lịch xác nhận';
        subtitle = 'Duyệt lịch hẹn ở tab Chờ duyệt';
      default:
        icon = Icons.calendar_today_outlined;
        title = 'Chưa có lịch hẹn nào';
        subtitle = 'Lịch hẹn sẽ xuất hiện ở đây';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 340,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AdminColors.elevated,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Icon(icon, size: 32, color: AdminColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text(title, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600, color: AdminColors.textPrimary,
              )),
              const SizedBox(height: 6),
              Text(subtitle, style: GoogleFonts.inter(
                fontSize: 13, color: AdminColors.textSecondary,
              )),
              const SizedBox(height: 6),
              Text('Kéo xuống để làm mới', style: GoogleFonts.inter(
                fontSize: 11, color: AdminColors.textMuted,
                fontStyle: FontStyle.italic,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AdminColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(Icons.wifi_off_rounded, size: 32, color: AdminColors.danger.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text('Không thể tải dữ liệu', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, color: AdminColors.textPrimary,
            )),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.inter(
              fontSize: 12, color: AdminColors.textSecondary,
            ), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Thử lại', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimary,
                side: BorderSide(color: AppTheme.kPrimary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, snapshot) => Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [AdminColors.elevated, AdminColors.surface, AdminColors.elevated],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.border, width: 0.5),
        ),
      ),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.apt,
    required this.onTap,
    required this.onConfirm,
    required this.onReject,
  });

  final Map<String, dynamic> apt;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';

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
      default:
        statusColor = AdminColors.warning;
        statusLabel = 'Chờ duyệt';
    }

    final date = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final isPaid = apt['paymentStatus'] == 'PAID';

    return Material(
      color: AdminColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
              top: const BorderSide(color: AdminColors.border, width: 0.5),
              right: const BorderSide(color: AdminColors.border, width: 0.5),
              bottom: const BorderSide(color: AdminColors.border, width: 0.5),
            ),
          ),
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
              const SizedBox(height: 8),
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
              // Quick actions — only for pending
              if (isPending) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AdminColors.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onReject,
                      style: TextButton.styleFrom(
                        foregroundColor: AdminColors.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                        side: BorderSide(color: AdminColors.danger.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      ),
    );
  }
}
