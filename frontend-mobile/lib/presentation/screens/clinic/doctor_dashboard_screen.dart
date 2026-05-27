import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/appointment_detail_sheet.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/doctor_notes_modal.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';

/// DoctorDashboardScreen — Màn hình tổng quan dành riêng cho bác sĩ.
///
/// Layout (top → bottom, scrollable):
///   1. Gradient header: greeting + stat chips
///   2. Quick actions grid (2×2)
///   3. "Cần xử lý ngay" — PENDING appointments (max 3)
///   4. "Lịch hôm nay" — vertical timeline
///   5. "Hoàn thành hôm nay" — completed with eRx badge
///   6. Empty state khi không có dữ liệu
///
/// onSwitchTab: callback từ ClinicShell để switch bottom-nav tab.
/// Tab indices: 0=Dashboard 1=Lịch hẹn 2=Bệnh nhân 3=Scan 4=Thông báo
class DoctorDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;
  const DoctorDashboardScreen({super.key, this.onSwitchTab});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _shortDate() {
    final now = DateTime.now();
    const wd = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    return '${wd[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
  }

  String _doctorName() {
    final authState = getIt<AuthBloc>().state;
    if (authState is Authenticated) {
      final name = authState.user.name ?? '';
      // Hiển thị tên: lấy từ cuối (họ thường ở cuối trong tiếng Việt)
      final parts = name.trim().split(' ');
      return parts.isNotEmpty ? parts.last : 'Bác sĩ';
    }
    return 'Bác sĩ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DC.bg,
      body: BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
        builder: (context, state) {
          // ── Extract & partition data ─────────────────────────────────────
          final apts = state is ClinicAppointmentsLoaded
              ? state.appointments
              : <Map<String, dynamic>>[];

          final now   = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final todayApts = apts.where((a) {
            final d = DateTime.tryParse(a['date'] ?? '')?.toLocal();
            if (d == null) return false;
            return DateTime(d.year, d.month, d.day) == today;
          }).toList()
            ..sort((a, b) {
              final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(0);
              final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(0);
              return da.compareTo(db);
            });

          final pending     = apts.where((a) => a['status'] == 'PENDING').toList();
          final confirmed   = apts.where((a) => a['status'] == 'CONFIRMED').toList();
          final completedToday = apts.where((a) {
            final d = DateTime.tryParse(a['date'] ?? '')?.toLocal();
            return d != null &&
                DateTime(d.year, d.month, d.day) == today &&
                a['status'] == 'COMPLETED';
          }).toList();

          final isLoading = state is ClinicAppointmentLoading ||
              state is ClinicAppointmentInitial;

          // ── Screen ────────────────────────────────────────────────────────
          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: _DC.surface,
            strokeWidth: 2,
            onRefresh: () async {
              context
                  .read<ClinicAppointmentBloc>()
                  .add(ClinicAppointmentsRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Gradient header ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(
                    todayCount:     todayApts.length,
                    pendingCount:   pending.length,
                    confirmedCount: confirmed.length,
                    doneCount:      completedToday.length,
                  ),
                ),

                // ── 2. Quick actions grid ───────────────────────────────────
                SliverToBoxAdapter(child: _buildQuickActions(context)),

                // ── 3. Loading skeleton ─────────────────────────────────────
                if (isLoading)
                  const SliverToBoxAdapter(child: _DashboardSkeleton()),

                // ── 4. Urgent: cần xử lý ngay (PENDING) ────────────────────
                if (!isLoading && pending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      icon: LucideIcons.alertCircle,
                      label: 'CẦN XỬ LÝ NGAY',
                      count: pending.length,
                      accentColor: _DC.warning,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => StaggeredListItem(
                        index: i,
                        child: _UrgentCard(
                          apt: pending[i],
                          onTap: () => showAppointmentDetail(ctx, pending[i]),
                          onConfirm: () => ctx
                              .read<ClinicAppointmentBloc>()
                              .add(ClinicAppointmentStatusUpdateRequested(
                                  pending[i]['id'] as String, 'CONFIRMED')),
                          onCancel: () => ctx
                              .read<ClinicAppointmentBloc>()
                              .add(ClinicAppointmentStatusUpdateRequested(
                                  pending[i]['id'] as String, 'CANCELLED')),
                        ),
                      ),
                      childCount: pending.length.clamp(0, 3),
                    ),
                  ),
                  // "Xem tất cả" nếu nhiều hơn 3
                  if (pending.length > 3)
                    SliverToBoxAdapter(
                      child: _ViewAllButton(
                        label: 'Xem tất cả ${pending.length} lịch chờ',
                        onTap: () => onSwitchTab?.call(1),
                      ),
                    ),
                ],

                // ── 5. Timeline hôm nay ─────────────────────────────────────
                if (!isLoading && todayApts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      icon: LucideIcons.clock,
                      label: 'LỊCH HÔM NAY',
                      count: todayApts.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _TodayTimeline(
                      apts: todayApts,
                      onTap: (apt) => showAppointmentDetail(context, apt),
                      onWriteRx: (apt) {
                        final bloc = context.read<ClinicAppointmentBloc>();
                        showDoctorNotesModal(
                          context,
                          apt['id'] as String,
                          apt['user']?['name'] as String? ?? 'Bệnh nhân',
                          existingBloc: bloc,
                        );
                      },
                    ),
                  ),
                ],

                // ── 6. Hoàn thành hôm nay ──────────────────────────────────
                if (!isLoading && completedToday.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      icon: LucideIcons.checkCircle,
                      label: 'HOÀN THÀNH HÔM NAY',
                      count: completedToday.length,
                      accentColor: _DC.success,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => StaggeredListItem(
                        index: i,
                        child: _CompletedCard(apt: completedToday[i]),
                      ),
                      childCount: completedToday.length,
                    ),
                  ),
                ],

                // ── 7. Empty state ─────────────────────────────────────────
                if (!isLoading &&
                    pending.isEmpty &&
                    todayApts.isEmpty &&
                    completedToday.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyState()),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader({
    required int todayCount,
    required int pendingCount,
    required int confirmedCount,
    required int doneCount,
  }) {
    final stats = [
      _Stat('Hôm nay',    todayCount,     AppTheme.kPrimary),
      _Stat('Chờ duyệt',  pendingCount,   _DC.warning),
      _Stat('Xác nhận',   confirmedCount, _DC.success),
      _Stat('Xong',       doneCount,      _DC.info),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4A42), Color(0xFF080E1A)],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role badge + online dot
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.4)),
                  ),
                  child: Text('BÁC SĨ', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.kPrimary, letterSpacing: 1.2,
                  )),
                ),
                const Spacer(),
                // Animated online dot
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: _DC.success, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: _DC.success.withValues(alpha: 0.5), blurRadius: 4,
                    )],
                  ),
                ),
                const SizedBox(width: 6),
                Text('Trực tuyến', style: GoogleFonts.inter(
                  fontSize: 11, color: _DC.success,
                )),
              ]),

              const SizedBox(height: 18),

              // Greeting + name
              Text(_greeting(), style: GoogleFonts.inter(
                fontSize: 13, color: _DC.textSecondary,
              )),
              const SizedBox(height: 2),
              Text('Dr. ${_doctorName()}', style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: _DC.textPrimary, height: 1.1,
              )),
              const SizedBox(height: 8),
              Text(_shortDate(), style: GoogleFonts.robotoMono(
                fontSize: 12, color: _DC.textMuted, letterSpacing: 0.5,
              )),

              const SizedBox(height: 20),

              // Stat chips (horizontal scroll)
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stats.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _StatChip(stat: stats[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick actions (2×2 grid) ─────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THAO TÁC NHANH', style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: _DC.textMuted, letterSpacing: 0.8,
          )),
          const SizedBox(height: 12),
          Row(children: [
            _QuickAction(
              icon: LucideIcons.calendar,
              label: 'Lịch hẹn',
              color: AppTheme.kPrimary,
              onTap: () => onSwitchTab?.call(1),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: LucideIcons.users,
              label: 'Bệnh nhân',
              color: _DC.info,
              onTap: () => onSwitchTab?.call(2),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: LucideIcons.scanLine,
              label: 'Scan QR',
              color: _DC.purple,
              onTap: () => onSwitchTab?.call(3),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: LucideIcons.clipboardCheck,
              label: 'Kê đơn',
              color: _DC.warning,
              onTap: () => onSwitchTab?.call(1), // đến Lịch hẹn → Xác nhận tab
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Stat model ────────────────────────────────────────────────────────────────
class _Stat {
  final String label;
  final int value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final _Stat stat;
  const _StatChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: _DC.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          top: BorderSide(color: stat.color, width: 2),
          left: BorderSide(color: _DC.border),
          right: BorderSide(color: _DC.border),
          bottom: BorderSide(color: _DC.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${stat.value}',
            style: GoogleFonts.robotoMono(
              fontSize: 22, fontWeight: FontWeight.w700, color: stat.color,
            ),
          ),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 9, color: _DC.textMuted, fontWeight: FontWeight.w500,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Quick action button ────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          splashColor: color.withValues(alpha: 0.12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _DC.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: _DC.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(height: 6),
                Text(label, style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w500,
                  color: _DC.textSecondary,
                ),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color? accentColor;
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.count,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.kPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.7,
        )),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text('$count', style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: color,
          )),
        ),
      ]),
    );
  }
}

// ─── Urgent card (PENDING appointments) ─────────────────────────────────────
class _UrgentCard extends StatelessWidget {
  final Map<String, dynamic> apt;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _UrgentCard({
    required this.apt,
    required this.onTap,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final date        = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title       = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr     = '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: _DC.warning.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              color: _DC.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border(
                left: BorderSide(color: _DC.warning, width: 3),
                top: BorderSide(color: _DC.border),
                right: BorderSide(color: _DC.border),
                bottom: BorderSide(color: _DC.border),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Time badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _DC.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _DC.warning.withValues(alpha: 0.3)),
                      ),
                      child: Text(timeStr, style: GoogleFonts.robotoMono(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _DC.warning,
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _DC.textPrimary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(title, style: GoogleFonts.inter(
                            fontSize: 11, color: _DC.textSecondary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Pulsing dot
                    _PulseDot(color: _DC.warning),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _DashBtn(label: 'Hủy', color: _DC.danger, onTap: onCancel),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DashBtn(
                        label: 'Xác nhận',
                        color: AppTheme.kPrimary,
                        filled: true,
                        onTap: onConfirm,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Today Timeline ───────────────────────────────────────────────────────────
class _TodayTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> apts;
  final void Function(Map<String, dynamic> apt) onTap;
  final void Function(Map<String, dynamic> apt) onWriteRx;
  const _TodayTimeline({
    required this.apts,
    required this.onTap,
    required this.onWriteRx,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: _DC.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _DC.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: apts.asMap().entries.map((e) {
            final i   = e.key;
            final apt = e.value;
            return Column(
              children: [
                if (i > 0) Container(height: 0.5, color: _DC.border,
                    margin: const EdgeInsets.only(left: 60)),
                _TimelineItem(
                  apt: apt,
                  isLast: i == apts.length - 1,
                  onTap: () => onTap(apt),
                  onWriteRx: () => onWriteRx(apt),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> apt;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onWriteRx;
  const _TimelineItem({
    required this.apt,
    required this.isLast,
    required this.onTap,
    required this.onWriteRx,
  });

  @override
  Widget build(BuildContext context) {
    final date        = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final status      = apt['status'] as String? ?? 'PENDING';
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title       = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr     = '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
    final isConfirmed = status == 'CONFIRMED';
    final isCompleted = status == 'COMPLETED';
    final isPending   = status == 'PENDING';

    final dotColor = switch (status) {
      'CONFIRMED' => _DC.success,
      'CANCELLED' => _DC.danger,
      'COMPLETED' => AppTheme.kPrimary,
      _           => _DC.warning,
    };

    final statusLabel = switch (status) {
      'CONFIRMED' => 'Xác nhận',
      'CANCELLED' => 'Đã hủy',
      'COMPLETED' => 'Xong',
      _           => 'Chờ duyệt',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.kPrimary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 44,
                child: Text(timeStr, style: GoogleFonts.robotoMono(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _DC.textSecondary,
                  fontFeatures: [const FontFeature.tabularFigures()],
                )),
              ),

              // Timeline line + dot
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 2),
                child: Column(
                  children: [
                    Container(
                      width: 9, height: 9,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.kPrimary : dotColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1, height: 40,
                        margin: const EdgeInsets.only(top: 2),
                        color: _DC.border,
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(patientName, style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _DC.textPrimary,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: _DC.textMuted,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(statusLabel, style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700, color: dotColor,
                        )),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(title, style: GoogleFonts.inter(
                      fontSize: 11, color: _DC.textMuted,
                    )),
                    const SizedBox(height: 6),
                    // Action row
                    if (isConfirmed)
                      _DashBtn(
                        label: 'Kê đơn & Hoàn thành',
                        color: AppTheme.kPrimary,
                        icon: LucideIcons.clipboardCheck,
                        filled: true,
                        compact: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onWriteRx();
                        },
                      ),
                    if (isPending)
                      Text(
                        '↳ Cần xác nhận trước khi khám',
                        style: GoogleFonts.inter(
                          fontSize: 10, color: _DC.warning,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (isCompleted) ...[
                      Row(children: [
                        Icon(LucideIcons.send, size: 10, color: AppTheme.kPrimary),
                        const SizedBox(width: 4),
                        Text(
                          (apt['doctorNotes'] as String?)?.isNotEmpty == true
                              ? 'Phiếu khám đã gửi bệnh nhân'
                              : 'Hoàn thành · chưa kê đơn',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: (apt['doctorNotes'] as String?)?.isNotEmpty == true
                                ? AppTheme.kPrimary
                                : _DC.textMuted,
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Completed card with eRx badge ───────────────────────────────────────────
class _CompletedCard extends StatelessWidget {
  final Map<String, dynamic> apt;
  const _CompletedCard({required this.apt});

  @override
  Widget build(BuildContext context) {
    final date        = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title       = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr     = '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
    final hasRx       = (apt['doctorNotes'] as String?)?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _DC.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(
              color: hasRx ? AppTheme.kPrimary : _DC.border, width: hasRx ? 3 : 1,
            ),
            top: BorderSide(color: _DC.border),
            right: BorderSide(color: _DC.border),
            bottom: BorderSide(color: _DC.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Text(timeStr, style: GoogleFonts.robotoMono(
              fontSize: 13, fontWeight: FontWeight.w600, color: _DC.textMuted,
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: _DC.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: _DC.textMuted,
                )),
                Text(title, style: GoogleFonts.inter(
                  fontSize: 11, color: _DC.textMuted,
                )),
              ],
            )),
            if (hasRx)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.send, size: 9, color: AppTheme.kPrimary),
                  const SizedBox(width: 4),
                  Text('eRx đã gửi', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.kPrimary,
                  )),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _DC.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: _DC.border),
                ),
                child: Icon(LucideIcons.checkCircle, size: 12, color: _DC.success),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── View all button ──────────────────────────────────────────────────────────
class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.kPrimary,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
          )),
          const SizedBox(width: 4),
          const Icon(LucideIcons.arrowRight, size: 12),
        ]),
      ),
    );
  }
}

// ─── Dashboard button (compact action button) ─────────────────────────────────
class _DashBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool compact;
  final IconData? icon;
  final VoidCallback onTap;
  const _DashBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.compact = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: filled ? Colors.white : color),
                const SizedBox(width: 5),
              ],
              Text(label, style: GoogleFonts.inter(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pulse dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 0.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _pulse,
    child: Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: widget.color, shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: widget.color.withValues(alpha: 0.5), blurRadius: 4,
        )],
      ),
    ),
  );
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 60),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _DC.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.2)),
            ),
            child: Icon(LucideIcons.calendar, size: 30,
              color: AppTheme.kPrimary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 18),
          Text('Ngày nghỉ hôm nay', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: _DC.textPrimary,
          )),
          const SizedBox(height: 6),
          Text(
            'Không có lịch hẹn nào hôm nay.\nKéo xuống để làm mới.',
            style: GoogleFonts.inter(fontSize: 13, color: _DC.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────
class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final g = LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value, 0),
          colors: [_DC.elevated, _DC.shimmer, _DC.elevated],
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 120,
                decoration: BoxDecoration(gradient: g, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: g, borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

// ─── Color palette (Doctor dark theme — consistent với _C trong appointments) ──
class _DC {
  static const bg       = Color(0xFF080E1A);
  static const surface  = Color(0xFF0F1829);
  static const elevated = Color(0xFF162237);
  static const shimmer  = Color(0xFF1E2D42);
  static const border   = Color(0xFF1E2D42);
  static const textPrimary   = Color(0xFFEFF3FF);
  static const textSecondary = Color(0xFF7A90B0);
  static const textMuted     = Color(0xFF3D5166);
  static const success  = Color(0xFF10B981);
  static const warning  = Color(0xFFF59E0B);
  static const danger   = Color(0xFFEF4444);
  static const info     = Color(0xFF60A5FA);
  static const purple   = Color(0xFFA78BFA);
}
