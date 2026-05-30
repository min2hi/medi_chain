import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// AppBar chuẩn cho tất cả Admin sub-screens.
/// Thay thế nhiều lần viết lại _buildAppBar() riêng lẻ.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showRefresh;
  final VoidCallback? onRefresh;
  final Color? backgroundColor;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showRefresh = false,
    this.onRefresh,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

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
    final bg = isAdmin ? (backgroundColor ?? AdminColors.bg) : (backgroundColor ?? AppTheme.kBg);
    final border = isAdmin ? AdminColors.border : AppTheme.kBorder;
    final textPrimary = isAdmin ? AdminColors.textPrimary : AppTheme.kTextPrimary;
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;
    final textMuted = isAdmin ? AdminColors.textMuted : AppTheme.kTextMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                  color: textSecondary,
                )
              : null,
          actions: [
            if (showRefresh && onRefresh != null)
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: onRefresh,
                color: textMuted,
              ),
            ...?actions,
          ],
        ),
        Container(height: 1, color: border),
      ],
    );
  }
}
