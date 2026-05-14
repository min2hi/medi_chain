import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// AppBar chuẩn cho tất cả Admin sub-screens.
/// Thay thế 7 lần viết lại _buildAppBar() riêng lẻ.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showRefresh;
  final VoidCallback? onRefresh;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showRefresh = false,
    this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: AdminColors.bg,
          foregroundColor: AdminColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: Text(
            title,
            style: const TextStyle(
              color: AdminColors.textPrimary,
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
                  color: AdminColors.textSecondary,
                )
              : null,
          actions: [
            if (showRefresh && onRefresh != null)
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: onRefresh,
                color: AdminColors.textMuted,
              ),
            ...?actions,
          ],
        ),
        Container(height: 1, color: AdminColors.border),
      ],
    );
  }
}
