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
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, i) => _EventRow(
                  item: items[i],
                  isAdmin: isAdmin,
                  isLast: i == items.length - 1,
                ),
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
// Pattern: Timeline Activity Feed (giống Supabase / Vercel Log).
// - Trục dọc Timeline nối liền các icon hành động
// - Card nội dung bên phải có bo tròn 12px mượt mà
// - Trạng thái chưa đọc: Card phát sáng nhẹ với màu accent tương ứng + dấu chấm glow
class _EventRow extends StatelessWidget {
  final NotificationItem item;
  final bool isAdmin;
  final bool isLast;
  const _EventRow({
    required this.item,
    required this.isAdmin,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final isRead = item.isRead;
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 20),
          // ── Timeline Axis Column (Cột trục thời gian) ──
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(_icon(), size: 14, color: accent),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isLast
                    ? const SizedBox()
                    : Container(
                        width: 1.2,
                        color: isAdmin 
                            ? AdminColors.border.withValues(alpha: 0.25)
                            : AppTheme.kBorder.withValues(alpha: 0.25),
                      ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Notification Detail Card (Thẻ nội dung chi tiết) ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 20, top: 6, bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRead ? Colors.transparent : accent.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRead 
                      ? Colors.transparent 
                      : accent.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isRead)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 8),
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
                            fontSize: 13,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
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
                    const SizedBox(height: 5),
                    _buildRichMessage(item.message, textSecondary, textPrimary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichMessage(String msg, Color textSecondary, Color textPrimary) {
    final List<InlineSpan> spans = [];
    final quoteRegex = RegExp(r'("[^"]*")');
    final matches = quoteRegex.allMatches(msg);
    
    if (matches.isEmpty) {
      return Text(
        msg,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary.withValues(alpha: 0.85),
          height: 1.45,
        ),
      );
    }
    
    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: msg.substring(lastIndex, match.start)));
      }
      final quoteText = msg.substring(match.start, match.end);
      spans.add(TextSpan(
        text: quoteText,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ));
      lastIndex = match.end;
    }
    
    if (lastIndex < msg.length) {
      spans.add(TextSpan(text: msg.substring(lastIndex)));
    }
    
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary.withValues(alpha: 0.85),
          height: 1.45,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
