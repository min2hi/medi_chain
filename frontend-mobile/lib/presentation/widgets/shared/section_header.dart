import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// Shared section header dùng ở mọi screen có list.
///
/// Senior dev pattern: 1 component, dùng khắp nơi.
/// Khi designer muốn thay font/size/color → sửa 1 chỗ, cả app thay đổi.
///
/// Usage:
/// ```dart
/// SectionHeader(text: 'Lịch hẹn hôm nay')
/// SectionHeader(text: 'Quick Actions', trailing: TextButton(...))
/// SectionHeader(text: 'Chỉ số', showDivider: false)
/// ```
class SectionHeader extends StatelessWidget {
  /// Label hiển thị — sẽ tự động uppercase + letter-spacing.
  final String text;

  /// Widget tùy chọn bên phải — thường là "Xem tất cả" TextButton.
  final Widget? trailing;

  /// Padding bên ngoài (bottom của header trước content).
  final EdgeInsets padding;

  /// Có hiện divider dưới header không (default: false).
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.text,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12),
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF4A6080) : AppTheme.kTextMuted;

    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: labelColor,
        height: 1,
      ),
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row: label + optional trailing
          if (trailing != null)
            Row(
              children: [
                label,
                const Spacer(),
                trailing!,
              ],
            )
          else
            label,

          // Optional divider
          if (showDivider) ...[
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF1E2D3D)
                  : const Color(0xFFEEF2F7),
            ),
          ],
        ],
      ),
    );
  }
}
