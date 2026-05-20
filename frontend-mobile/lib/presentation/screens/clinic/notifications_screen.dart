import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0D9488),
                    ),
                  );
                }
                if (state is NotificationError) {
                  return _buildErrorState(context, state.message);
                }
                if (state is NotificationLoaded && state.items.isEmpty) {
                  return _buildEmpty(context);
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
    );
  }

  // Gradient header đồng nhất với AppointmentListScreen & Settings
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF134E4A)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Colors.white),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    final count = state is NotificationLoaded
                        ? state.unreadCount
                        : 0;
                    return Text(
                      count > 0 ? '$count chưa đọc' : 'Đã đọc tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(count > 0 ? 0.95 : 0.7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<NotificationItem> items,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

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
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: grouped.entries.length,
      itemBuilder: (context, i) {
        final entry = grouped.entries.elementAt(i);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? const Color(0xFF4A6080)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            ...entry.value.asMap().entries.map((e) {
              final n = e.value;
              final isLast = e.key == entry.value.length - 1;
              return _NotificationTile(
                item: n,
                isDark: isDark,
                isLast: isLast,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bellOff,
              size: 36,
              color: isDark ? const Color(0xFF2D4A6A) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thông báo về lịch hẹn và\ncập nhật sức khỏe sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final isColdStart = message == 'server_cold_start';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isColdStart ? LucideIcons.serverCrash : LucideIcons.wifiOff,
              size: 40,
              color: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              isColdStart
                  ? 'Backend đang khởi động\n(Render free tier ~30s). Vui lòng thử lại.'
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(NotificationFetchRequested()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
  final bool isDark;
  final bool isLast;

  const _NotificationTile({
    required this.item,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead;
    final accent = _accentColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Container(
          decoration: BoxDecoration(
            color: isRead
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : (isDark
                    ? accent.withOpacity(0.06)
                    : accent.withOpacity(0.04)),
            border: Border(
              left: BorderSide(
                color: isRead ? Colors.transparent : accent,
                width: 3,
              ),
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                width: isLast ? 0 : 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconData(), size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF4A6080)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF7A90B0)
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Contextual deep-link hint
                    if (_destinationLabel() != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _destinationLabel()!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 12,
                            color: accent,
                          ),
                        ],
                      ),
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

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();
    switch (item.type) {
      case 'APPOINTMENT':
        context.go('/appointments');
      case 'MEDICINE':
        context.go('/medicines');
      default:
        break;
    }
  }

  String? _destinationLabel() {
    switch (item.type) {
      case 'APPOINTMENT': return 'Xem lịch hẹn';
      case 'MEDICINE':    return 'Xem tủ thuốc';
      default:            return null;
    }
  }

  IconData _iconData() {
    switch (item.type) {
      case 'APPOINTMENT': return LucideIcons.calendarCheck;
      case 'MEDICINE':    return LucideIcons.pill;
      default:            return LucideIcons.bell;
    }
  }

  Color _accentColor() {
    switch (item.type) {
      case 'APPOINTMENT': return const Color(0xFF0D9488);
      case 'MEDICINE':    return const Color(0xFF8B5CF6);
      default:            return const Color(0xFF64748B);
    }
  }
}
