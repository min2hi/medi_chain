import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon nhỏ, không có circle container — Linear style
            Icon(icon, color: AdminColors.textMuted, size: 22),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(
                description!,
                style: const TextStyle(
                  color: AdminColors.textMuted,
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AdminColors.danger,
              size: 22,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: AdminColors.aiPrimary,
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
