import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// Unified card widget cho toàn app Patient portal.
/// Thay thế mọi Container decoration pattern lặp lại.
///
/// Supports:
///   - Left accent bar (urgency color)
///   - Tap ripple với InkWell
///   - Optional top-right badge slot
///   - Subtle shadow elevation
///
/// Usage:
///   AppCard(
///     onTap: () => ...,
///     accentColor: AppTheme.kWarning,
///     child: ...,
///   )
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.accentColor,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
    this.showShadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Optional left bar color — dùng cho urgency/status visual cue
  final Color? accentColor;

  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final border  = isDark ? const Color(0xFF2D3F55) : AppTheme.kBorder;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 1),
        boxShadow: showShadow && !isDark ? AppShadow.card : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  }
                : null,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  if (accentColor != null)
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft:    Radius.circular(AppRadius.lg),
                          bottomLeft: Radius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                  // Content
                  Expanded(
                    child: Padding(padding: padding, child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

