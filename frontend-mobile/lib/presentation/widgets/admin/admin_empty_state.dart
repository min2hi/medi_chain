import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

// ─── AdminEmptyState ─────────────────────────────────────────────────────────
// Reference: Linear, Vercel, Datadog empty states.
// Pattern: NO circle decoration. Chỉ icon nhỏ + text. Không decoration thừa.
// ─────────────────────────────────────────────────────────────────────────────

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? description;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
  });

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
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;
    final textMuted = isAdmin ? AdminColors.textMuted : AppTheme.kTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon nhỏ, không có circle container — Linear style
            Icon(icon, color: textMuted, size: 22),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(
                description!,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── AdminErrorState ──────────────────────────────────────────────────────────
// Cùng pattern: không có circle, chỉ icon + text + retry button nhỏ.
// ─────────────────────────────────────────────────────────────────────────────

class AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

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
    final textSecondary = isAdmin ? AdminColors.textSecondary : AppTheme.kTextSecondary;
    final danger = isAdmin ? AdminColors.danger : AppTheme.kDanger;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: danger,
              size: 22,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Thử lại',
                style: TextStyle(
                  color: isAdmin ? AdminColors.aiPrimary : AppTheme.kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
