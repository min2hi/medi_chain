import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

String _timeLabel(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return 'Vừa xong';
  if (diff.inMinutes < 60)  return '${diff.inMinutes}p trước';
  if (diff.inHours   < 24)  return '${diff.inHours}h trước';
  if (diff.inDays    == 1)  return 'Hôm qua';
  if (diff.inDays    < 7)   return '${diff.inDays}d trước';
  return '${dt.day}/${dt.month}';
}

/// AdminNotificationsScreen — System event feed cho Admin/Doctor portal.
/// Design: đồng nhất 100% với các admin screen khác.
///   - Dùng AdminAppBar, AdminEmptyState, AdminErrorState
///   - AdminColors.bg / surface / border / textMuted
///   - Chỉ hiển thị SYSTEM type — không lẫn với patient notifications
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(NotificationFetchRequested());
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context
            .read<NotificationBloc>()
            .add(NotificationMarkAllReadRequested());
      }
    });
  }

  void _refresh() =>
      context.read<NotificationBloc>().add(NotificationFetchRequested());

  bool _isAdmin(BuildContext context) {
    try {
      final path = GoRouterState.of(context).uri.toString();
      return path.contains('/admin');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin(context);
    return Scaffold(
      backgroundColor: isAdmin ? AdminColors.bg : AppTheme.kBg,
      appBar: AdminAppBar(
        title: 'Nhật ký hệ thống',
        showRefresh: true,
        onRefresh: _refresh,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.kPrimary,
              ),
            );
          }

          if (state is NotificationError) {
            final msg = state.message == 'server_cold_start'
                ? 'Backend đang khởi động (~30s). Vui lòng thử lại.'
                : state.message;
            return AdminErrorState(message: msg, onRetry: _refresh);
          }

          if (state is NotificationLoaded) {
            final items = state.items
                .where((n) => n.type == 'SYSTEM')
                .toList();

            if (items.isEmpty) {
              return const AdminEmptyState(
                icon: LucideIcons.shieldCheck,
                message: 'Không có sự kiện hệ thống',
                description:
                    'Hoạt động đăng ký, lịch hẹn và thanh toán\nsẽ xuất hiện ở đây.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppTheme.kPrimary,
              backgroundColor: isAdmin ? AdminColors.surface : AppTheme.kSurface,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isAdmin ? AdminColors.border : AppTheme.kBorder,
                  indent: 60,
                  endIndent: 0,
                ),
                itemBuilder: (context, i) => _EventRow(item: items[i], isAdmin: isAdmin),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

// ─── Event row ────────────────────────────────────────────────────────────────
// Pattern: Vercel Activity Log, Linear Notification Feed.
// - Compact horizontal layout, không dùng Card — giống các admin screen khác
// - Icon 32×32 rounded-8 với màu semantic
// - Unread: dot nhỏ trước title + bg tint nhẹ
class _EventRow extends StatelessWidget {
  final NotificationItem item;
  final bool isAdmin;
  const _EventRow({required this.item, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final isRead = item.isRead;
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;

    return Container(
      color: isRead ? Colors.transparent : accent.withOpacity(0.04),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ──
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(), size: 14, color: accent),
          ),
          const SizedBox(width: 12),

          // ── Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isRead)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(right: 6, top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _timeLabel(item.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    final t = item.title.toLowerCase();
    if (t.contains('lịch') || t.contains('hẹn') || t.contains('appointment')) {
      return LucideIcons.calendarCheck;
    }
    if (t.contains('thanh toán') || t.contains('payment') || t.contains('tiền')) {
      return LucideIcons.creditCard;
    }
    if (t.contains('đăng ký') || t.contains('user') || t.contains('tài khoản')) {
      return LucideIcons.userPlus;
    }
    if (t.contains('hủy') || t.contains('cancel')) {
      return LucideIcons.calendarX;
    }
    if (t.contains('lỗi') || t.contains('error') || t.contains('fail')) {
      return LucideIcons.alertTriangle;
    }
    return LucideIcons.activity;
  }

  Color _accent() {
    final t = item.title.toLowerCase();
    if (t.contains('lịch') || t.contains('hẹn')) {
      return isAdmin ? AdminColors.success : AppTheme.kSuccess;
    }
    if (t.contains('thanh toán') || t.contains('payment')) {
      return isAdmin ? AdminColors.info : AppTheme.kPrimary;
    }
    if (t.contains('đăng ký') || t.contains('user')) {
      return isAdmin ? AdminColors.purple : const Color(0xFF8B5CF6);
    }
    if (t.contains('hủy') || t.contains('cancel')) {
      return isAdmin ? AdminColors.danger : AppTheme.kDanger;
    }
    if (t.contains('lỗi') || t.contains('error')) {
      return isAdmin ? AdminColors.warning : AppTheme.kWarning;
    }
    return isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;
  }
}
