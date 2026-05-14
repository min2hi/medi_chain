import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/core/services/admin_session_service.dart';
import 'package:medi_chain_mobile/core/services/biometric_service.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

// ─── Dashboard ──────────────────────────────────────────────────────────────
// Reference: Linear sidebar nav, Vercel dashboard header, Datadog metrics bar.
// Pattern: flat header (không gradient), list nav (không card grid),
//          typography-driven hierarchy (không colored icon boxes).
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _session   = AdminSessionService();
  final _biometric = BiometricService();
  Map<String, dynamic>? _stats;
  bool _statsLoading = true;

  // Track các route đã truy cập trong phiên để tắt "notification dot"
  final Set<String> _visitedRoutes = {};

  @override
  void initState() {
    super.initState();
    _session.startSession();
    _fetchStats();
    _session.onSessionExpiring = () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⏱ Phiên Admin sắp hết hạn trong 2 phút.'),
        backgroundColor: AdminColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 6),
      ));
    };
    _session.onSessionExpired = () {
      if (!mounted) return;
      _showReauthDialog();
    };
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _statsLoading = true);
    try {
      final api  = getIt<ApiClient>();
      final resp = await api.get('/admin/stats');
      if (mounted) setState(() => _stats = resp.data['data'] as Map<String, dynamic>?);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  void dispose() {
    _session.endSession();
    super.dispose();
  }

  Future<void> _showReauthDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.overlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Phiên Admin hết hạn',
            style: TextStyle(color: AdminColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        content: const Text(
          'Phiên quản trị đã hết sau 30 phút để bảo vệ dữ liệu bệnh nhân.',
          style: TextStyle(color: AdminColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); context.go('/'); },
            child: const Text('Về Patient Portal', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              final result = await _biometric.authenticate(reason: 'Gia hạn phiên Admin — MediChain');
              if (!mounted) return;
              if (result == BiometricResult.success) {
                _session.renewSession();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Phiên Admin đã được gia hạn thêm 30 phút.'),
                  backgroundColor: AdminColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              } else if (result == BiometricResult.cancelled || result == BiometricResult.failed) {
                _showReauthDialog();
              } else {
                context.go('/');
              }
            },
            child: const Text('Xác thực lại',
                style: TextStyle(color: AdminColors.aiPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Derived stats ──────────────────────────────────────────────────────────
  int? get _pendingCount {
    final v = (_stats?['system'] as Map<String, dynamic>?)?['pendingReview'];
    return v is int ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final auth   = getIt<AuthBloc>().state;
    final name   = auth is Authenticated ? auth.user.name ?? 'Admin' : 'Admin';
    final role   = auth is Authenticated ? (auth.user.role ?? 'ADMIN') : 'ADMIN';

    // Tính toán notification state
    final pendingCount = _pendingCount ?? 0;
    final alertsCount  = (_stats?['activity'] as Map<String, dynamic>?)?['blockedAlertsLast24h'] as int? ?? 0;
    
    // Nếu có pending/alerts VÀ chưa vào trang đó trong phiên này -> hiện notification
    final reviewUnread = pendingCount > 0 && !_visitedRoutes.contains('/admin/review-queue');
    final logsUnread   = alertsCount > 0  && !_visitedRoutes.contains('/admin/access-logs');

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: _buildAppBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(name, role),
          _buildNavGroup('DUYỆT & KIỂM SOÁT', [
            _NavItem('Duyệt Đề Xuất AI',   '/admin/review-queue', hasNotification: reviewUnread, color: AdminColors.info, pendingCount: _pendingCount),
            _NavItem('Nhật Ký Hoạt Động',  '/admin/access-logs',  hasNotification: logsUnread,   color: AdminColors.aiPrimary),
          ]),
          _buildNavGroup('TRI THỨC LÂM SÀNG', [
            _NavItem('Từ Khóa An Toàn',    '/admin/keywords',     color: AdminColors.success),
            _NavItem('Quy Tắc Tổ Hợp',    '/admin/combos',       color: AdminColors.warning),
          ]),
          _buildNavGroup('HỆ THỐNG & QUẢN TRỊ', [
            _NavItem('Quản Lý Người Dùng', '/admin/users',        color: AdminColors.roleAdmin),
            _NavItem('Giám Sát Hệ Thống',  '/admin/telemetry',    color: AdminColors.purple),
          ]),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Column(children: [
        AppBar(
          backgroundColor: AdminColors.bg,
          automaticallyImplyLeading: false,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Row(children: [
            Icon(LucideIcons.shieldCheck, color: AdminColors.aiPrimary, size: 17),
            SizedBox(width: 9),
            Text('Admin Portal', style: TextStyle(
              color: AdminColors.textPrimary, fontSize: 15,
              fontWeight: FontWeight.w600, letterSpacing: -0.2,
            )),
          ]),
          actions: [
            IconButton(
              icon: _statsLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AdminColors.textMuted))
                  : const Icon(LucideIcons.refreshCw, size: 15, color: AdminColors.textMuted),
              onPressed: () { HapticFeedback.lightImpact(); _fetchStats(); },
            ),
          ],
        ),
        Container(height: 1, color: AdminColors.border),
      ]),
    );
  }

  // ── Header — Vercel flat style, không gradient, không avatar ──────────────
  Widget _buildHeader(String name, String role) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Chào buổi sáng,' : h < 18 ? 'Chào buổi chiều,' : 'Chào buổi tối,';
    final roleColor = role.toUpperCase() == 'ADMIN' ? AdminColors.roleAdmin : AdminColors.roleDoctor;

    final users    = (_stats?['users']    as Map<String, dynamic>?)?['total'];
    final pending  = (_stats?['system']   as Map<String, dynamic>?)?['pendingReview'];
    final aiDaily  = (_stats?['activity'] as Map<String, dynamic>?)?['aiQueriesLast24h'];
    final alerts   = (_stats?['activity'] as Map<String, dynamic>?)?['blockedAlertsLast24h'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + role chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(greeting, style: const TextStyle(
                    color: AdminColors.textMuted, fontSize: 12,
                  )),
                  // Double-tap → thoát về patient portal (không có text hint)
                  GestureDetector(
                    onDoubleTap: () { HapticFeedback.mediumImpact(); context.go('/'); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: roleColor.withOpacity(0.22)),
                      ),
                      child: Text(role.toUpperCase(), style: TextStyle(
                        color: roleColor, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8,
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Name — typography là hierarchy, không cần decoration
              Text(name, style: const TextStyle(
                color: AdminColors.textPrimary, fontSize: 22,
                fontWeight: FontWeight.w700, letterSpacing: -0.5,
              )),
              const SizedBox(height: 20),
              // Metrics bar — Datadog pattern: numbers only, no boxes
              _buildMetricsBar(
                users: '$users', pending: '$pending', aiDaily: '$aiDaily', alerts: '$alerts',
                hasPending: pending is int && pending > 0,
                hasAlerts: alerts is int && alerts > 0,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Container(height: 1, color: AdminColors.border),
      ],
    );
  }

  Widget _buildMetricsBar({
    required String users, required String pending,
    required String aiDaily, required String alerts,
    required bool hasPending, required bool hasAlerts,
  }) {
    return Row(children: [
      _metric(users,   'người dùng',  AdminColors.textPrimary,  false),
      _metricDivider(),
      _metric(pending, 'chờ duyệt',   AdminColors.warning,       hasPending),
      _metricDivider(),
      _metric(aiDaily, 'AI / 24h',    AdminColors.textPrimary,  false),
      _metricDivider(),
      _metric(alerts,  'cảnh báo',    AdminColors.danger,        hasAlerts),
    ]);
  }

  Widget _metric(String value, String label, Color accentColor, bool highlight) {
    return Expanded(
      child: Column(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _statsLoading
              ? Container(key: const ValueKey('sk'),
                  width: 30, height: 14,
                  decoration: BoxDecoration(color: AdminColors.elevated, borderRadius: BorderRadius.circular(4)))
              : Text(value, key: ValueKey(value), style: TextStyle(
                  color: highlight ? accentColor : AdminColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.bold,
                )),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AdminColors.textMuted, fontSize: 10)),
      ]),
    );
  }

  Widget _metricDivider() => Container(width: 1, height: 30, color: AdminColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── Nav group — Linear sidebar style ──────────────────────────────────────
  Widget _buildNavGroup(String label, List<_NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
          child: Text(label, style: const TextStyle(
            color: AdminColors.textMuted, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.3,
          )),
        ),
        ...items.map((item) => _NavRow(
          item: item,
          onTap: () async {
            // Đánh dấu đã đọc
            if (mounted) setState(() => _visitedRoutes.add(item.route));
            
            await context.push(item.route);
            // Refresh stats sau khi user quay lại (ví dụ: đã duyệt xong review queue)
            if (mounted) _fetchStats();
          },
        )),
        Container(height: 1, color: AdminColors.border),
      ],
    );
  }
}

// ── Nav data ──────────────────────────────────────────────────────────────────
class _NavItem {
  final String title;
  final String route;
  final Color color;
  final bool hasNotification;
  final int? pendingCount;

  const _NavItem(this.title, this.route, {
    required this.color,
    this.hasNotification = false,
    this.pendingCount,
  });
}

// ── Nav row — Linear pattern: dot indicator + text + count badge ──────────────
// Không dùng colored icon box. Typography + màu dot là toàn bộ hierarchy.
class _NavRow extends StatefulWidget {
  final _NavItem item;
  final VoidCallback onTap;
  const _NavRow({required this.item, required this.onTap});

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => _pressed = true); },
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? AdminColors.elevated : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          // Notification dot indicator — chuẩn y tế/slack: có việc mới thì hiện dot, đọc xong mất
          if (item.hasNotification)
            Container(
              width: 6, height: 6,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
            )
          else
            const SizedBox(width: 18), // Spacing bù cho dot
            
          // Title: "sáng lên" (textPrimary, w600) nếu có notification chưa đọc
          Expanded(
            child: Text(item.title, style: TextStyle(
              color: item.hasNotification ? AdminColors.textPrimary : AdminColors.textSecondary,
              fontSize: 14,
              fontWeight: item.hasNotification ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: -0.1,
            )),
          ),
          // Count badge — chỉ hiện khi có action cần xử lý
          if (item.pendingCount != null && item.pendingCount! > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AdminColors.warning.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.warning.withOpacity(0.3)),
              ),
              child: Text('${item.pendingCount}', style: const TextStyle(
                color: AdminColors.warning, fontSize: 11, fontWeight: FontWeight.w600,
              )),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, color: AdminColors.textMuted, size: 16),
        ]),
      ),
    );
  }
}
