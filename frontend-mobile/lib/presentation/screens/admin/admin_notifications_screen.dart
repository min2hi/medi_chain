import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

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
      final authState = context.read<AuthBloc>().state;
      return authState is Authenticated &&
          authState.user.role?.toUpperCase() == 'ADMIN';
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
        title: isAdmin ? 'Nhật ký hệ thống' : 'Thông báo',
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
                .where((n) => isAdmin ? n.type == 'SYSTEM' : n.type == 'APPOINTMENT')
                .toList();

            if (items.isEmpty) {
              return AdminEmptyState(
                icon: isAdmin ? LucideIcons.shieldCheck : LucideIcons.bellOff,
                message: isAdmin ? 'Không có sự kiện hệ thống' : 'Không có thông báo',
                description: isAdmin
                    ? 'Hoạt động đăng ký, lịch hẹn và thanh toán\nsẽ xuất hiện ở đây.'
                    : 'Các thông báo liên quan đến lịch hẹn phòng khám\nsẽ được hiển thị tại đây.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppTheme.kPrimary,
              backgroundColor: isAdmin ? AdminColors.surface : AppTheme.kSurface,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
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
// - Icon 36×36 rounded-10 với màu semantic và viền glowing mảnh
// - Unread: dot nhỏ phát sáng trước title + bg tint nhẹ
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
      decoration: BoxDecoration(
        color: isRead ? Colors.transparent : accent.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: isAdmin 
                ? AdminColors.border.withValues(alpha: 0.4) 
                : AppTheme.kBorder.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon với viền glowing mảnh ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(_icon(), size: 15, color: accent),
          ),
          const SizedBox(width: 12),

          // ── Nội dung thông báo ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isRead)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8, top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _timeLabel(item.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textSecondary.withValues(alpha: 0.85),
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
