import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';
import 'appointment_detail_sheet.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BLoC được provide từ ClinicShell (shared state)
    return BlocListener<ClinicAppointmentBloc, ClinicAppointmentState>(
      listener: (context, state) {
        if (state is ClinicAppointmentActionSuccess) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(state.message, style: GoogleFonts.inter(fontSize: 13)),
              ]),
              backgroundColor: _C.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          );
        }
      },
      child: Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(child: _buildTabBody()),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final wd = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${wd[now.weekday - 1]}, ${now.day}/${now.month}',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: _C.textSecondary, letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lịch Hẹn',
                  style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w700,
                    color: _C.textPrimary, height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
            builder: (context, state) {
              if (state is! ClinicAppointmentsLoaded) return const SizedBox(width: 40);
              final n = state.appointments.where((a) => a['status'] == 'PENDING').length;
              if (n == 0) return const SizedBox(width: 40);
              return _PendingPill(count: n);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: _PillIndicator(),
        dividerColor: Colors.transparent,
        labelColor: AppTheme.kPrimary,
        unselectedLabelColor: _C.textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        labelPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(text: 'Chờ duyệt'),
          Tab(text: 'Xác nhận'),
          Tab(text: 'Hoàn thành'),
          Tab(text: 'Tất cả'),
        ],
      ),
    );
  }


  Widget _buildTabBody() {
    return TabBarView(
      controller: _tabController,
      children: const [
        _AptList(filter: 'PENDING'),
        _AptList(filter: 'CONFIRMED'),
        _AptList(filter: 'COMPLETED'),
        _AptList(filter: 'ALL'),
      ],
    );
  }
}

// ─── Pill / Capsule Tab Indicator ────────────────────────────────────────────
class _PillIndicator extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _PillPainter();
}

class _PillPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final h = (cfg.size?.height ?? 36) * 0.72;
    final w = (cfg.size?.width ?? 80) - 16;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx + 8,
        offset.dy + ((cfg.size?.height ?? 36) - h) / 2,
        w,
        h,
      ),
      const Radius.circular(20),
    );
    final paint = Paint()
      ..color = AppTheme.kPrimary.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    final borderPaint = Paint()
      ..color = AppTheme.kPrimary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rect, borderPaint);
  }
}



// ─── Pending pill badge — pulse dot = urgency indicator ─────────────────────
class _PendingPill extends StatefulWidget {
  const _PendingPill({required this.count});
  final int count;

  @override
  State<_PendingPill> createState() => _PendingPillState();
}

class _PendingPillState extends State<_PendingPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    // 1.6s loop — tốc độ heartbeat, đủ để nhận ra mà không gây annoying
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 0.3).animate(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _C.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulse dot — live indicator (Linear / Slack / Notion pattern)
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 5, height: 5,
              decoration: const BoxDecoration(
                color: _C.warning, shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${widget.count} chờ',
            style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: _C.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment List ─────────────────────────────────────────────────────────
class _AptList extends StatelessWidget {
  const _AptList({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicAppointmentBloc, ClinicAppointmentState>(
      builder: (context, state) {
        if (state is ClinicAppointmentLoading || state is ClinicAppointmentInitial) {
          return const _ShimmerList();
        }

        if (state is ClinicAppointmentError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<ClinicAppointmentBloc>().add(ClinicAppointmentsFetchRequested()),
          );
        }

        if (state is ClinicAppointmentsLoaded) {
          final items = state.appointments
              .where((a) => filter == 'ALL' || a['status'] == filter)
              .toList();

          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: _C.surface,
            strokeWidth: 2,
            onRefresh: () async {
              context.read<ClinicAppointmentBloc>().add(ClinicAppointmentsRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: items.isEmpty
                ? _EmptyView(filter: filter)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final apt = items[i];
                      return StaggeredListItem(
                        index: i,
                        child: _AptCard(
                          apt: apt,
                          onTap: () => showAppointmentDetail(context, apt),
                          onConfirm: () => context.read<ClinicAppointmentBloc>().add(
                              ClinicAppointmentStatusUpdateRequested(
                                  apt['id'] as String, 'CONFIRMED')),
                          onCancel: () => context.read<ClinicAppointmentBloc>().add(
                              ClinicAppointmentStatusUpdateRequested(
                                  apt['id'] as String, 'CANCELLED')),
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

// ─── Appointment Card ─────────────────────────────────────────────────────────
class _AptCard extends StatelessWidget {
  const _AptCard({
    required this.apt,
    required this.onTap,
    required this.onConfirm,
    required this.onCancel,
  });
  final Map<String, dynamic> apt;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final status      = apt['status'] as String? ?? 'PENDING';
    final date        = DateTime.tryParse(apt['date'] ?? '')?.toLocal() ?? DateTime.now();
    final patientName = apt['user']?['name'] as String? ?? 'Bệnh nhân';
    final title       = apt['title'] as String? ?? 'Khám dịch vụ';
    final isPaid      = apt['paymentStatus'] == 'PAID';
    final isPending   = status == 'PENDING';

    final Color accent = switch (status) {
      'CONFIRMED' => _C.success,
      'CANCELLED' => _C.danger,
      'COMPLETED' => AppTheme.kPrimary,
      _           => _C.warning,
    };

    final String statusLabel = switch (status) {
      'CONFIRMED' => 'Đã xác nhận',
      'CANCELLED' => 'Đã hủy',
      'COMPLETED' => 'Hoàn thành',
      _           => 'Chờ duyệt',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias, // ripple & children clipped to rounded corners
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.kPrimary.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.borderSubtle),
            ),
            child: Column(
              children: [
                // ── Main row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Time column
                      SizedBox(
                        width: 54, // was 46 → caused '06:3\n6' wrap bug
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _C.textPrimary,
                                fontFeatures: [const FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _C.textMuted,
                                fontFeatures: [const FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        width: 1, height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: _C.borderSubtle,
                      ),
                      // Patient + service
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _C.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Status chip — dot + text, no border
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Bottom row ──
                Container(
                  height: 1,
                  color: _C.borderSubtle,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  child: Row(
                    children: [
                      // Payment status — plain text, no chip
                      Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 12,
                        color: isPaid ? _C.success : _C.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isPaid ? _C.success : _C.textMuted,
                        ),
                      ),
                      const Spacer(),
                      // Actions
                      if (isPending) ...[
                        _ActionBtn(
                          label: 'Hủy',
                          color: _C.danger,
                          filled: false,
                          onTap: onCancel,
                        ),
                        const SizedBox(width: 6),
                        _ActionBtn(
                          label: 'Xác nhận',
                          color: AppTheme.kPrimary,
                          filled: true,
                          onTap: onConfirm,
                        ),
                      ] else
                        InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  'Xem chi tiết',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _C.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: _C.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
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

// ─── Action button ───────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub) = switch (filter) {
      'PENDING' => (
          Icons.check_circle_outline_rounded,
          'Không có lịch chờ duyệt',
          'Tất cả lịch hẹn đã được xử lý'
        ),
      'CONFIRMED' => (
          Icons.event_available_outlined,
          'Chưa có lịch xác nhận',
          'Duyệt lịch từ tab Chờ duyệt'
        ),
      'COMPLETED' => (
          Icons.medical_services_outlined,
          'Chưa có ca khám hoàn thành',
          'Ca khám đã hoàn thành sẽ hiện ở đây'
        ),
      _ => (
          Icons.calendar_today_outlined,
          'Chưa có lịch hẹn nào',
          'Lịch hẹn sẽ hiện ở đây'
        ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.borderSubtle),
                ),
                child: Icon(icon, size: 28, color: _C.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                sub,
                style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                '↓  Kéo xuống để làm mới',
                style: GoogleFonts.inter(
                  fontSize: 11, color: _C.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatefulWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    setState(() => _retrying = true);
    widget.onRetry();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isServerError = widget.message.toLowerCase().contains('server') ||
        widget.message.toLowerCase().contains('500') ||
        widget.message.toLowerCase().contains('connect');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container — Epic MyChart style
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.borderSubtle),
              ),
              child: Icon(
                isServerError ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                size: 32,
                color: _C.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isServerError ? 'Máy chủ không phản hồi' : 'Không thể tải dữ liệu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isServerError
                  ? 'Backend đang khởi động (Render free tier\nmất ~30s). Vui lòng thử lại sau.'
                  : widget.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _retrying ? null : _handleRetry,
                icon: _retrying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  _retrying ? 'Đang kết nối lại...' : 'Thử lại',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  disabledBackgroundColor: AppTheme.kPrimary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer List ─────────────────────────────────────────────────────────────
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      itemCount: 3,
      itemBuilder: (context, i) => AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => _ShimmerCard(anim: _anim.value),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.anim});
  final double anim;

  LinearGradient get _g => LinearGradient(
        begin: Alignment(anim - 1, 0),
        end: Alignment(anim, 0),
        colors: [_C.elevated, _C.shimmer, _C.elevated],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.borderSubtle),
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                // Time block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 22, width: 52, decoration: BoxDecoration(gradient: _g, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 5),
                    Container(height: 10, width: 34, decoration: BoxDecoration(gradient: _g, borderRadius: BorderRadius.circular(3))),
                  ],
                ),
                Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 14), color: _C.borderSubtle),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: double.infinity, decoration: BoxDecoration(gradient: _g, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 120, decoration: BoxDecoration(gradient: _g, borderRadius: BorderRadius.circular(3))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom bar
          Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: _g,
              border: Border(top: BorderSide(color: _C.borderSubtle)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Color alias (admin dark palette) ────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF080E1A);
  static const surface     = Color(0xFF0F1829);
  static const elevated    = Color(0xFF162237);
  static const shimmer     = Color(0xFF1E2D42);
  static const borderSubtle= Color(0xFF1E2D42);
  static const textPrimary = Color(0xFFEFF3FF);
  static const textSecondary= Color(0xFF7A90B0);
  static const textMuted   = Color(0xFF3D5166);
  static const success     = Color(0xFF10B981);
  static const warning     = Color(0xFFF59E0B);
  static const danger      = Color(0xFFEF4444);
}
