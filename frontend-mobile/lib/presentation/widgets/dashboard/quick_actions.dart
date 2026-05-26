import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// QuickActions — 4 icon shortcuts, minimal strip layout
//
// Design rationale:
//   - Không có outer tile box — tránh "icon grid" look phổ biến ở mọi app
//   - Chỉ icon circle (teal tint) + label — focus vào action, không vào decoration
//   - Scale press feedback 0.94 + haptic — tactile, purposeful
//   - Không có "QUICK ACTIONS" section header — layout tự nói lên mình
// ════════════════════════════════════════════════════════════════════════════
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _QATile(
          label: 'Hồ sơ',
          icon: LucideIcons.filePlus2,
          isDark: isDark,
          onTap: () => context.push('/record-form'),
        ),
        _QATile(
          label: 'Thuốc',
          icon: LucideIcons.pill,
          isDark: isDark,
          onTap: () => context.push('/medicine-form'),
        ),
        _QATile(
          label: 'Đặt lịch',
          icon: LucideIcons.calendarPlus,
          isDark: isDark,
          onTap: () =>
              context.go('/', extra: {'initialTab': 3, 'openAddDialog': true}),
        ),
        _QATile(
          label: 'Chỉ số',
          icon: LucideIcons.activity,
          isDark: isDark,
          onTap: () => context.push('/metrics'),
        ),
      ],
    );
  }
}

// ── Private tile ─────────────────────────────────────────────────────────────
class _QATile extends StatefulWidget {
  const _QATile({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_QATile> createState() => _QATileState();
}

class _QATileState extends State<_QATile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) async {
          await _ctrl.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle — visual anchor duy nhất
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppTheme.kPrimary.withValues(alpha: 0.12)
                      : AppTheme.kPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 21,
                  color: AppTheme.kPrimary,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? const Color(0xFFCBD5E1)
                      : AppTheme.kTextPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
