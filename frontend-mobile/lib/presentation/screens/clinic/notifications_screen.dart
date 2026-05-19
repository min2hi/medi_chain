import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays == 1) return 'Hôm qua';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${dt.day}/${dt.month}';
}

/// NotificationsScreen — thiết kế theo chuẩn Doximity / Practo:
/// Danh sách phẳng, phân nhóm theo ngày, unread có left-accent teal.
/// [embedded]: true khi dùng bên trong modal sheet (bỏ Scaffold wrapper)
class NotificationsScreen extends StatefulWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch ngay khi mở tab và mark all read sau 1s (user đã thấy)
    context.read<NotificationBloc>().add(NotificationFetchRequested());
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.read<NotificationBloc>().add(NotificationMarkAllReadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF080E1A);
    const textColor = Color(0xFFEFF3FF);
    const subColor = Color(0xFF7A90B0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông báo',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        BlocBuilder<NotificationBloc, NotificationState>(
                          builder: (context, state) {
                            if (state is NotificationLoaded && state.unreadCount > 0) {
                              return Text(
                                '${state.unreadCount} chưa đọc',
                                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.kPrimary),
                              );
                            }
                            return Text(
                              'Đã đọc tất cả',
                              style: GoogleFonts.inter(fontSize: 13, color: subColor),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1E293B)),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimary),
                    );
                  }
                  if (state is NotificationError) {
                    return _buildEmpty(
                      icon: LucideIcons.wifiOff,
                      title: 'Không thể tải thông báo',
                      sub: state.message,
                    );
                  }
                  if (state is NotificationLoaded && state.items.isEmpty) {
                    return _buildEmpty(
                      icon: LucideIcons.bell,
                      title: 'Chưa có thông báo',
                      sub: 'Thông báo lịch hẹn và cập nhật hệ thống\nsẽ xuất hiện tại đây',
                    );
                  }
                  if (state is NotificationLoaded) {
                    return _buildGroupedList(context, state.items);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(BuildContext context, List<NotificationItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Nhóm theo ngày
    final Map<String, List<NotificationItem>> grouped = {};
    for (final item in items) {
      final day = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      final String key;
      if (day == today) {
        key = 'Hôm nay';
      } else if (day == yesterday) {
        key = 'Hôm qua';
      } else {
        key = '${day.day}/${day.month}/${day.year}';
      }
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: grouped.entries.length,
      itemBuilder: (context, groupIndex) {
        final entry = grouped.entries.elementAt(groupIndex);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                entry.key,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D5166),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ...entry.value.map((n) => _NotificationTile(item: n)),
          ],
        );
      },
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1829),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E2D42)),
              ),
              child: Icon(icon, size: 28, color: const Color(0xFF3D5166)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEFF3FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF7A90B0),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF080E1A);
    const unreadBg = Color(0xFF071A1A);

    return Container(
      color: item.isRead ? bg : unreadBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar — chỉ khi unread (Practo pattern)
          Container(
            width: 3,
            height: 68,
            color: item.isRead ? Colors.transparent : AppTheme.kPrimary,
          ),
          // Icon type
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconColor().withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconData(), size: 17, color: _iconColor()),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w600,
                            color: const Color(0xFFEFF3FF),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(item.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF3D5166),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF7A90B0),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconData() {
    switch (item.type) {
      case 'APPOINTMENT':
        return LucideIcons.calendar;
      case 'MEDICINE':
        return LucideIcons.pill;
      default:
        return LucideIcons.bell;
    }
  }

  Color _iconColor() {
    switch (item.type) {
      case 'APPOINTMENT':
        return AppTheme.kPrimary;
      case 'MEDICINE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
