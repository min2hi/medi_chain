import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════
// QuickActions — Row of 4 neutral icon tiles
//
// Thiết kế intentional (không AI gen):
//   - Surface trắng/neutral — KHÔNG dùng 4 màu gradient khác nhau
//   - Chỉ icon box có màu nhẹ (teal tint duy nhất), không color chaos
//   - Typography-led: label bold dưới icon
//   - Interaction: scale + ripple — giống Apple/Zocdoc
// ══════════════════════════════════════════════════════════════════════

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFF1F5F9);

    return Row(
      children: [
        _QATile(
          label: 'Hồ sơ',
          icon: LucideIcons.filePlus2,
          surface: surface,
          border: border,
          isDark: isDark,
          onTap: () => context.push('/record-form'),
        ),
        const SizedBox(width: 10),
        _QATile(
          label: 'Thuốc',
          icon: LucideIcons.pill,
          surface: surface,
          border: border,
          isDark: isDark,
          onTap: () => context.push('/medicine-form'),
        ),
        const SizedBox(width: 10),
        _QATile(
          label: 'Đặt lịch',
          icon: LucideIcons.calendarPlus,
          surface: surface,
          border: border,
          isDark: isDark,
          onTap: () => context.go('/', extra: {'initialTab': 3, 'openAddDialog': true}),
        ),
        const SizedBox(width: 10),
        _QATile(
          label: 'Chỉ số',
          icon: LucideIcons.activity,
          surface: surface,
          border: border,
          isDark: isDark,
          onTap: () => context.push('/metrics'),
        ),
      ],
    );
  }
}

// ── Private tile — icon trên, label dưới ───────────────────────────────────
class _QATile extends StatefulWidget {
  const _QATile({
    required this.label,
    required this.icon,
    required this.surface,
    required this.border,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color surface;
  final Color border;
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
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) async {
          await _ctrl.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.border, width: 1),
              boxShadow: widget.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon box — teal tint nhẹ, một màu duy nhất
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppTheme.kPrimary.withValues(alpha: 0.12)
                        : AppTheme.kPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: AppTheme.kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
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
      ),
    );
  }
}

