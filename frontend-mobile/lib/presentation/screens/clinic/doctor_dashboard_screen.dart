import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
///   1. Gradient header: greeting + 4 stat chips
///   2. Quick actions (4 nút ngang)
///   3. "Cần xử lý ngay" — PENDING queue (max 3) với confirm/cancel inline
///   4. "Lịch hôm nay" — vertical timeline với dot+line, action buttons
///   5. "Hoàn thành hôm nay" — completed apts với eRx badge
///   6. Empty state khi không có dữ liệu
///
/// Colors: dùng AdminColors từ app_theme.dart — không duplicate _DC class.
/// onSwitchTab callback từ ClinicShell:
///   Tab 0=Tổng quan(this) 1=Lịch hẹn 2=Bệnh nhân 3=Scan 4=Thông báo
class DoctorDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;
  const DoctorDashboardScreen({super.key, this.onSwitchTab});

  // ── Helpers ──────────────────────────────────────────────────────────────
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
      final parts = (authState.user.name ?? '').trim().split(' ');
      return parts.isNotEmpty ? parts.last : 'Bác sĩ';
    }
    return 'Bác sĩ';
  }

  static DateTime _dateOf(Map<String, dynamic> a) =>
      DateTime.tryParse(a['date'] ?? '')?.toLocal() ?? DateTime(0);

  @override
  Widget build(BuildContext context) {
    // Compute once — không tính lại nhiều lần trong subtree
    final greeting   = _greeting();
    final shortDate  = _shortDate();
    final doctorName = _doctorName();
    final today      = DateTime.now();
    final todayDate  = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
        builder: (context, state) {
          // ── Partition appointments ──────────────────────────────────────
          final apts = state is ClinicAppointmentsLoaded
              ? state.appointments
              : <Map<String, dynamic>>[];

          bool isToday(Map<String, dynamic> a) {
            final d = _dateOf(a);
            return DateTime(d.year, d.month, d.day) == todayDate;
          }

          final todayApts = apts
              .where(isToday)
              .toList()
            ..sort((a, b) => _dateOf(a).compareTo(_dateOf(b)));

          final pending        = apts.where((a) => a['status'] == 'PENDING').toList();
          final confirmed      = apts.where((a) => a['status'] == 'CONFIRMED').toList();
          final completedToday = apts
              .where((a) => isToday(a) && a['status'] == 'COMPLETED')
              .toList();

          // CONFIRMED hôm nay (kế thừa sort tăng dần của todayApts) + liịch tiếp theo
          final confirmedToday = todayApts
              .where((a) => a['status'] == 'CONFIRMED')
              .toList();
          final nextApt = confirmedToday.isNotEmpty ? confirmedToday.first : null;

          final isLoading = state is ClinicAppointmentLoading ||
              state is ClinicAppointmentInitial;

          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: AdminColors.surface,
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
                // 1. Header
                SliverToBoxAdapter(
                  child: _DoctorHeader(
                    greeting:      greeting,
                    shortDate:     shortDate,
                    doctorName:    doctorName,
                    todayCount:     todayApts.length,
                    pendingCount:   pending.length,
                    confirmedCount: confirmed.length,
                    doneCount:      completedToday.length,
                  ),
                ),

                // 2. Bệnh nhân tiếp theo — hero card
                //    chỉ hiện khi có dữ liệu và tồn tại lịch confirmed hôm nay
                if (!isLoading && nextApt != null)
                  SliverToBoxAdapter(
                    child: _NextPatientCard(
                      apt: nextApt,
                      onStart: () => showAppointmentDetail(context, nextApt),
                    ),
                  ),

                // 3. Quick actions — buttons LUÔN enabled, khi không có data thì show SnackBar
                SliverToBoxAdapter(
                  child: _QuickActions(
                    pendingCount:   pending.length,
                    confirmedCount: confirmedToday.length,
                    onTapNext: () {
                      if (nextApt != null) {
                        showAppointmentDetail(context, nextApt);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _infoSnack('Chưa có lịch xác nhận hôm nay'),
                        );
                      }
                    },
                    onTapPending: () {
                      if (pending.isNotEmpty) {
                        showAppointmentDetail(context, pending.first);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _infoSnack('Không có lịch chờ duyệt'),
                        );
                      }
                    },
                    onWriteRx: () {
                      final target = confirmedToday.isNotEmpty
                          ? confirmedToday.first
                          : confirmed.isNotEmpty ? confirmed.first : null;
                      if (target != null) {
                        final bloc = context.read<ClinicAppointmentBloc>();
                        showDoctorNotesModal(
                          context,
                          target['id'] as String,
                          target['user']?['name'] as String? ?? 'Bệnh nhân',
                          existingBloc: bloc,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _infoSnack('Không có lịch xác nhận để kê đơn'),
                        );
                      }
                    },
                    onScanQr: () => onSwitchTab?.call(3),
                  ),
                ),

                // 4. Loading skeleton
                if (isLoading)
                  const SliverToBoxAdapter(child: _DashboardSkeleton()),

                // 4. Urgent — PENDING queue
                if (!isLoading && pending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      icon: LucideIcons.alertCircle,
                      label: 'CẦN XỬ LÝ NGAY',
                      count: pending.length,
                      accentColor: AdminColors.warning,
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
                  if (pending.length > 3)
                    SliverToBoxAdapter(
                      child: _ViewAllButton(
                        label: 'Xem tất cả ${pending.length} lịch chờ duyệt',
                        onTap: () => onSwitchTab?.call(1),
                      ),
                    ),
                ],

                // 5. Timeline hôm nay
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

                // 6. Completed today
                if (!isLoading && completedToday.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      icon: LucideIcons.checkCircle,
                      label: 'HOÀN THÀNH HÔM NAY',
                      count: completedToday.length,
                      accentColor: AdminColors.success,
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

                // 7. Empty state
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
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _DoctorHeader extends StatelessWidget {
  final String greeting;
  final String shortDate;
  final String doctorName;
  final int todayCount;
  final int pendingCount;
  final int confirmedCount;
  final int doneCount;

  const _DoctorHeader({
    required this.greeting,
    required this.shortDate,
    required this.doctorName,
    required this.todayCount,
    required this.pendingCount,
    required this.confirmedCount,
    required this.doneCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat('Hôm nay',   todayCount,     AppTheme.kPrimary),
      _Stat('Chờ duyệt', pendingCount,   AdminColors.warning),
      _Stat('Xác nhận',  confirmedCount, AdminColors.success),
      _Stat('Xong',      doneCount,      AdminColors.info),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4A42), AdminColors.bg],
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
              // Role badge + online status + settings button
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
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: AdminColors.success, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: AdminColors.success.withValues(alpha: 0.5), blurRadius: 4,
                    )],
                  ),
                ),
                const SizedBox(width: 6),
                Text('Trực tuyến', style: GoogleFonts.inter(
                  fontSize: 11, color: AdminColors.success,
                )),
                const SizedBox(width: 14),
                Material(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/settings'),
                    borderRadius: BorderRadius.circular(100),
                    splashColor: Colors.white.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        LucideIcons.settings,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 18),

              Text(greeting, style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.7),
              )),
              const SizedBox(height: 2),
              Text('Dr. $doctorName', style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: Colors.white, height: 1.1,
              )),
              const SizedBox(height: 8),
              Text(shortDate, style: GoogleFonts.robotoMono(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.5,
              )),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _StatChip(stat: stats[0])),
                  const SizedBox(width: 8),
                  Expanded(child: _StatChip(stat: stats[1])),
                  const SizedBox(width: 8),
                  Expanded(child: _StatChip(stat: stats[2])),
                  const SizedBox(width: 8),
                  Expanded(child: _StatChip(stat: stats[3])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat model & chip ────────────────────────────────────────────────────────
class _Stat {
  final String label;
  final int value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
}

class _StatChip extends StatelessWidget {
  final _Stat stat;
  const _StatChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: stat.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${stat.value}',
            style: GoogleFonts.robotoMono(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            stat.label,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: stat.color,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final int pendingCount;
  final int confirmedCount;
  final VoidCallback onTapNext;
  final VoidCallback onTapPending;
  final VoidCallback onWriteRx;
  final VoidCallback onScanQr;

  const _QuickActions({
    required this.pendingCount,
    required this.confirmedCount,
    required this.onTapNext,
    required this.onTapPending,
    required this.onWriteRx,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // bottom 20 để sliver không clip bóng/viền dưới của nút
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text('THAO TÁC NHANH', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: AdminColors.textMuted, letterSpacing: 0.8,
            )),
          ),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // 1. Khám tiếp
              _QuickActionBtn(
                icon: LucideIcons.stethoscope,
                label: 'Khám tiếp',
                color: AppTheme.kPrimary,
                onTap: onTapNext,
              ),
              const SizedBox(width: 8),
              // 2. Xác nhận — badge số lịch chờ
              _QuickActionBtn(
                icon: LucideIcons.checkCircle,
                label: 'Xác nhận',
                color: AdminColors.success,
                badge: pendingCount > 0 ? '$pendingCount' : null,
                onTap: onTapPending,
              ),
              const SizedBox(width: 8),
              // 3. Kê đơn — badge số lịch confirmed
              _QuickActionBtn(
                icon: LucideIcons.clipboardCheck,
                label: 'Kê đơn',
                color: AdminColors.warning,
                badge: confirmedCount > 0 ? '$confirmedCount' : null,
                onTap: onWriteRx,
              ),
              const SizedBox(width: 8),
              // 4. Scan QR
              _QuickActionBtn(
                icon: LucideIcons.scanLine,
                label: 'Scan QR',
                color: AdminColors.purple,
                onTap: onScanQr,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Nút quick action — luôn enabled, badge count tùy chọn.
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          splashColor: color.withValues(alpha: 0.14),
          highlightColor: color.withValues(alpha: 0.07),
          child: Container(
            // Dùng padding thay fixed height — tự co giãn theo nội dung
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: color.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Badge góc trên phải — nằm TRONG card, tính từ Stack
                if (badge != null)
                  Positioned(
                    top: -6, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 4, offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Nội dung nút — icon + label
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.13),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SnackBar helper ────────────────────────────────────────────────────────────────
SnackBar _infoSnack(String message) => SnackBar(
  content: Text(message, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
  behavior: SnackBarBehavior.floating,
  backgroundColor: AdminColors.elevated,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  duration: const Duration(seconds: 2),
);

// ─── Next patient hero card ────────────────────────────────────────────────────
/// Hero card bệnh nhân tiếp theo: countdown, avatar, tên, dịch vụ, CTA button.
/// Countdown color: đỏ (<15p), vàng (15-30p), xanh (>30p / đang diễn ra).
class _NextPatientCard extends StatelessWidget {
  final Map<String, dynamic> apt;
  final VoidCallback onStart;
  const _NextPatientCard({required this.apt, required this.onStart});

  String _countdown(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.isNegative) {
      return diff.inMinutes > -45 ? 'Đang diễn ra' : 'Đã qua';
    }
    if (diff.inHours >= 1) {
      final m = diff.inMinutes % 60;
      return 'Còn ${diff.inHours}g${m.toString().padLeft(2, '0')}p';
    }
    return 'Còn ${diff.inMinutes} phút';
  }

  Color _cColor(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.isNegative) return AdminColors.success;
    if (diff.inMinutes <= 15) return AdminColors.danger;
    if (diff.inMinutes <= 30) return AdminColors.warning;
    return AdminColors.info;
  }

  @override
  Widget build(BuildContext context) {
    final date        = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title       = apt['title'] as String? ?? 'Khám dịch vụ';
    final timeStr     = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final countdown   = _countdown(date);
    final cColor      = _cColor(date);
    final inProgress  = date.difference(DateTime.now()).isNegative &&
        date.difference(DateTime.now()).inMinutes > -45;

    final parts    = patientName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : patientName.substring(0, patientName.length.clamp(0, 2)).toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left:   BorderSide(color: AppTheme.kPrimary, width: 3),
            top:    const BorderSide(color: AdminColors.border),
            right:  const BorderSide(color: AdminColors.border),
            bottom: const BorderSide(color: AdminColors.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: label + countdown badge
              Row(children: [
                const Icon(LucideIcons.userRound, size: 11, color: AppTheme.kPrimary),
                const SizedBox(width: 5),
                Text('BỆNH NHÂN TIẾP THEO', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppTheme.kPrimary, letterSpacing: 0.7,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: cColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (inProgress)
                      _PulseDot(color: cColor)
                    else
                      Icon(LucideIcons.clock, size: 9, color: cColor),
                    const SizedBox(width: 4),
                    Text(countdown, style: GoogleFonts.robotoMono(
                      fontSize: 10, fontWeight: FontWeight.w700, color: cColor,
                    )),
                  ]),
                ),
              ]),

              const SizedBox(height: 12),

              // Patient info row
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(initials, style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppTheme.kPrimary,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName, style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(children: [
                        Flexible(
                          child: Text(title, style: GoogleFonts.inter(
                            fontSize: 12, color: AdminColors.textSecondary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: 3, height: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AdminColors.textMuted, shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Text(timeStr, style: GoogleFonts.robotoMono(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        )),
                      ]),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 12),

              // CTA button
              Material(
                color: AppTheme.kPrimary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onStart();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            inProgress ? 'Tiếp tục khám' : 'Bắt đầu khám',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

// ─── Urgent card (PENDING) ────────────────────────────────────────────────────
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
        child: Ink(
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border(
              left:   BorderSide(color: AdminColors.warning, width: 3),
              top:    const BorderSide(color: AdminColors.border),
              right:  const BorderSide(color: AdminColors.border),
              bottom: const BorderSide(color: AdminColors.border),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            splashColor: AdminColors.warning.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Text(timeStr, style: GoogleFonts.robotoMono(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.warning,
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AdminColors.textPrimary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(title, style: GoogleFonts.inter(
                            fontSize: 11, color: AdminColors.textSecondary,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    _PulseDot(color: AdminColors.warning),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _DashBtn(
                        label: 'Hủy',
                        color: AdminColors.danger,
                        onTap: onCancel,
                        expanded: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DashBtn(
                        label: 'Xác nhận',
                        color: AppTheme.kPrimary,
                        filled: true,
                        onTap: onConfirm,
                        expanded: true,
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
  final void Function(Map<String, dynamic>) onTap;
  final void Function(Map<String, dynamic>) onWriteRx;
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
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AdminColors.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: List.generate(apts.length, (i) {
            return Column(
              children: [
                if (i > 0) Container(height: 0.5, color: AdminColors.border),
                _TimelineItem(
                  apt: apts[i],
                  isLast: i == apts.length - 1,
                  onTap: () => onTap(apts[i]),
                  onWriteRx: () => onWriteRx(apts[i]),
                ),
              ],
            );
          }),
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

    final dotColor = switch (status) {
      'CONFIRMED' => AdminColors.success,
      'CANCELLED' => AdminColors.danger,
      'COMPLETED' => AppTheme.kPrimary,
      _           => AdminColors.warning,
    };

    final statusLabel = switch (status) {
      'CONFIRMED' => 'Xác nhận',
      'CANCELLED' => 'Đã hủy',
      'COMPLETED' => 'Xong',
      _           => 'Chờ',
    };

    final isConfirmed = status == 'CONFIRMED';
    final isCompleted = status == 'COMPLETED';
    final isPending   = status == 'PENDING';
    final hasRx       = (apt['doctorNotes'] as String?)?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.kPrimary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: IntrinsicHeight(
            // IntrinsicHeight cho phép timeline line stretch theo content height
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time column (fixed width)
                SizedBox(
                  width: 44,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(timeStr, style: GoogleFonts.robotoMono(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AdminColors.textSecondary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    )),
                  ),
                ),

                // Dot + line (stretch to content height)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.kPrimary
                              : dotColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.only(top: 2),
                            color: AdminColors.border,
                          ),
                        ),
                    ],
                  ),
                ),

                // Content (fills remaining width)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(patientName, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AdminColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: AdminColors.textMuted,
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
                        fontSize: 11, color: AdminColors.textMuted,
                      )),
                      const SizedBox(height: 6),

                      // Contextual action per status
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
                            fontSize: 10, color: AdminColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (isCompleted)
                        Row(children: [
                          Icon(
                            hasRx ? LucideIcons.send : LucideIcons.checkCircle,
                            size: 10,
                            color: hasRx ? AppTheme.kPrimary : AdminColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasRx
                                ? 'Phiếu khám đã gửi bệnh nhân'
                                : 'Hoàn thành · chưa kê đơn',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: hasRx ? AppTheme.kPrimary : AdminColors.textMuted,
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
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
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(
              color: hasRx ? AppTheme.kPrimary : AdminColors.border,
              width: hasRx ? 3 : 1,
            ),
            top:    const BorderSide(color: AdminColors.border),
            right:  const BorderSide(color: AdminColors.border),
            bottom: const BorderSide(color: AdminColors.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Text(timeStr, style: GoogleFonts.robotoMono(
              fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textMuted,
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AdminColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AdminColors.textMuted,
                )),
                Text(title, style: GoogleFonts.inter(
                  fontSize: 11, color: AdminColors.textMuted,
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
              Icon(LucideIcons.checkCircle, size: 16, color: AdminColors.success),
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

// ─── Reusable dash button ─────────────────────────────────────────────────────
class _DashBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool compact;
  final IconData? icon;
  final VoidCallback onTap;
  final bool expanded;
  const _DashBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.compact = false,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Ink(
        width: expanded ? double.infinity : null,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          splashColor: filled ? Colors.white.withValues(alpha: 0.15) : color.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical:   compact ? 5  : 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
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

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _pulse;

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.2)),
          ),
          child: Icon(LucideIcons.calendar, size: 30,
            color: AppTheme.kPrimary.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 18),
        Text('Ngày nghỉ hôm nay', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary,
        )),
        const SizedBox(height: 6),
        Text(
          'Không có lịch hẹn nào hôm nay.\nKéo xuống để làm mới.',
          style: GoogleFonts.inter(
            fontSize: 13, color: AdminColors.textSecondary, height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
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
  late final Animation<double>   _anim;

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final g = LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end:   Alignment(_anim.value,     0),
          colors: [
            AdminColors.elevated,
            AdminColors.shimmer,
            AdminColors.elevated,
          ],
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 120,
                decoration: BoxDecoration(
                  gradient: g,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                )),
              const SizedBox(height: 12),
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: g,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
