import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Vá»«a xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} ph\u00fat tr\u01b0\u1edbc';
  if (diff.inHours < 24) return '${diff.inHours} gi\u1edd tr\u01b0\u1edbc';
  if (diff.inDays == 1) return 'H\u00f4m qua';
  if (diff.inDays < 7) return '${diff.inDays} ng\u00e0y tr\u01b0\u1edbc';
  return '${dt.day}/${dt.month}';
}

/// NotificationsScreen â€” thiáº¿t káº¿ theo chuáº©n Doximity / Practo:
/// Danh sÃ¡ch pháº³ng, phÃ¢n nhÃ³m theo ngÃ y, unread cÃ³ left-accent teal.
/// [embedded]: true khi dÃ¹ng bÃªn trong modal sheet (bá» Scaffold wrapper)
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
    // Fetch ngay khi má»Ÿ tab vÃ  mark all read sau 1s (user Ä‘Ã£ tháº¥y)
    context.read<NotificationBloc>().add(NotificationFetchRequested());
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.read<NotificationBloc>().add(NotificationMarkAllReadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ThÃ´ng bÃ¡o',
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
                                '${state.unreadCount} chÆ°a Ä‘á»c',
                                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.kPrimary),
                              );
                            }
                            return Text(
                              'ÄÃ£ Ä‘á»c táº¥t cáº£',
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

            // â”€â”€ List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (state is NotificationError) {
                    return _buildEmpty(
                      icon: LucideIcons.wifiOff,
                      title: 'KhÃ´ng thá»ƒ táº£i thÃ´ng bÃ¡o',
                      sub: state.message,
                      isDark: isDark,
                    );
                  }
                  if (state is NotificationLoaded && state.items.isEmpty) {
                    return _buildEmpty(
                      icon: LucideIcons.bell,
                      title: 'ChÆ°a cÃ³ thÃ´ng bÃ¡o',
                      sub: 'ThÃ´ng bÃ¡o lá»‹ch háº¹n vÃ  cáº­p nháº­t há»‡ thá»‘ng sáº½ xuáº¥t hiá»‡n táº¡i Ä‘Ã¢y',
                      isDark: isDark,
                    );
                  }
                  if (state is NotificationLoaded) {
                    return _buildGroupedList(context, state.items, isDark);
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

  Widget _buildGroupedList(BuildContext context, List<NotificationItem> items, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // NhÃ³m theo ngÃ y
    final Map<String, List<NotificationItem>> grouped = {};
    for (final item in items) {
      final day = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      final String key;
      if (day == today) {
        key = 'HÃ´m nay';
      } else if (day == yesterday) {
        key = 'HÃ´m qua';
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
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ...entry.value.map((n) => _NotificationTile(item: n, isDark: isDark)),
          ],
        );
      },
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String sub,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final bool isDark;
  const _NotificationTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final unreadBg = isDark ? const Color(0xFF0F2A2A) : const Color(0xFFF0FDFA);

    return Container(
      color: item.isRead ? bg : unreadBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar â€” chá»‰ khi unread (Practo pattern)
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
                color: _iconBg().withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconData(), size: 17, color: _iconBg()),
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
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(item.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
      case 'APPOINTMENT': return LucideIcons.calendar;
      case 'MEDICINE': return LucideIcons.pill;
      default: return LucideIcons.bell;
    }
  }

  Color _iconBg() {
    switch (item.type) {
      case 'APPOINTMENT': return AppTheme.kPrimary;
      case 'MEDICINE': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF64748B);
    }
  }
}
