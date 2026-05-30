import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/appointment_detail_sheet.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/doctor_notes_modal.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/doctor_header.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/doctor_quick_actions.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/next_patient_card.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/urgent_card.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/widgets/today_timeline.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';
import 'package:shimmer/shimmer.dart';

/// DoctorDashboardScreen — Simplified, modular dashboard screen for doctors.
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

  SnackBar _infoSnack(String msg) {
    return SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: AppTheme.kPrimary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    final shortDate = _shortDate();
    final doctorName = _doctorName();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: AppTheme.kBg,
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

          final todayApts = apts.where(isToday).toList()
            ..sort((a, b) => _dateOf(a).compareTo(_dateOf(b)));

          final pending = apts.where((a) => a['status'] == 'PENDING').toList();
          final confirmed = apts.where((a) => a['status'] == 'CONFIRMED').toList();
          final completedToday = apts
              .where((a) => isToday(a) && a['status'] == 'COMPLETED')
              .toList();

          final confirmedToday = todayApts.where((a) => a['status'] == 'CONFIRMED').toList();
          final nextApt = confirmedToday.isNotEmpty ? confirmedToday.first : null;

          final isLoading = state is ClinicAppointmentLoading ||
              state is ClinicAppointmentInitial;

          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: AppTheme.kSurface,
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
                  child: DoctorHeader(
                    greeting: greeting,
                    shortDate: shortDate,
                    doctorName: doctorName,
                    todayCount: todayApts.length,
                    pendingCount: pending.length,
                    confirmedCount: confirmed.length,
                    doneCount: completedToday.length,
                  ),
                ),

                // 2. Bệnh nhân tiếp theo — hero card
                if (!isLoading && nextApt != null)
                  SliverToBoxAdapter(
                    child: NextPatientCard(
                      apt: nextApt,
                      onStart: () => showAppointmentDetail(context, nextApt),
                    ),
                  ),

                // 3. Quick actions
                SliverToBoxAdapter(
                  child: DoctorQuickActions(
                    pendingCount: pending.length,
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
                          : confirmed.isNotEmpty
                              ? confirmed.first
                              : null;
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
                      accentColor: AppTheme.kWarning,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => StaggeredListItem(
                        index: i,
                        child: UrgentCard(
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
                    child: TodayTimeline(
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
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(
              color: hasRx ? AppTheme.kPrimary : AppTheme.kBorder,
              width: hasRx ? 3 : 1,
            ),
            top:    const BorderSide(color: AppTheme.kBorder),
            right:  const BorderSide(color: AppTheme.kBorder),
            bottom: const BorderSide(color: AppTheme.kBorder),
          ),
          boxShadow: AppShadow.card,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Text(timeStr, style: GoogleFonts.robotoMono(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.kTextMuted,
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppTheme.kTextSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppTheme.kTextMuted,
                )),
                Text(title, style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.kTextMuted,
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
              Icon(LucideIcons.checkCircle, size: 16, color: AppTheme.kSuccess),
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
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.kBorder),
            boxShadow: AppShadow.card,
          ),
          child: Icon(LucideIcons.calendar, size: 30,
            color: AppTheme.kPrimary.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 18),
        Text('Ngày nghỉ hôm nay', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.kTextPrimary,
        )),
        const SizedBox(height: 6),
        Text(
          'Không có lịch hẹn nào hôm nay.\nKéo xuống để làm mới.',
          style: GoogleFonts.inter(
            fontSize: 13, color: AppTheme.kTextSecondary, height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

// ─── Loading skeleton (using native Shimmer library) ──────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.kSurface,
      highlightColor: AppTheme.kBorder,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
