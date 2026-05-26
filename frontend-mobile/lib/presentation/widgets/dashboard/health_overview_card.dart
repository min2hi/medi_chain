import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

/// Hero health overview card — priority waterfall:
///   1. Upcoming appointment (time-sensitive → most urgent)
///   2. Latest vitals text (nếu có chỉ số gần đây)
///   3. Medicine count (fallback luôn có)
/// Sau hero là compact info rows (blood type, allergy, diagnosis).
class HealthOverviewCard extends StatelessWidget {
  final DashboardStats? stats;
  const HealthOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final border  = isDark ? const Color(0xFF2D3F55) : AppTheme.kBorder;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
        boxShadow: isDark ? null : AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          _CardHeader(isDark: isDark),

          Divider(height: 1, color: border),

          // ── Hero metric — priority waterfall ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildHeroMetric(context, isDark),
          ),

          // ── Compact info rows ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _InfoRow(
                  icon: LucideIcons.droplets,
                  label: 'Nhóm máu',
                  value: stats?.profile?.bloodType,
                  isDark: isDark,
                ),
                _InfoRow(
                  icon: LucideIcons.shieldAlert,
                  label: 'Dị ứng',
                  value: stats?.profile?.allergies,
                  isDark: isDark,
                ),
                _InfoRow(
                  icon: LucideIcons.clipboardList,
                  label: 'Chẩn đoán',
                  value: stats?.latestDiagnosis,
                  isDark: isDark,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(BuildContext context, bool isDark) {
    // Priority 1: upcoming appointment
    final appt = stats?.upcomingAppointment;
    if (appt != null) {
      return _HeroAppointment(appt: appt, isDark: isDark);
    }

    // Priority 2: vitals text
    final vitals = stats?.latestVitalsText;
    if (vitals != null && vitals.isNotEmpty && vitals != '—') {
      return _HeroVitals(vitals: vitals, date: stats?.latestVitalDate, isDark: isDark);
    }

    // Priority 3: medicine count fallback
    final count = stats?.medicineCount ?? 0;
    return _HeroMedicineCount(count: count, isDark: isDark);
  }
}

// ── Card Header ───────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final bool isDark;
  const _CardHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.kPrimaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              LucideIcons.heartPulse,
              size: 15,
              color: AppTheme.kPrimaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tình trạng sức khỏe',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE2E8F0) : AppTheme.kTextPrimary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero variants ─────────────────────────────────────────────────────────────

class _HeroAppointment extends StatelessWidget {
  final UpcomingAppointment appt;
  final bool isDark;
  const _HeroAppointment({required this.appt, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _HeroTile(
      color: AppTheme.kInfo,
      bgColor: isDark
          ? const Color(0xFF0C1E3D)
          : AppTheme.kInfoSurface,
      icon: LucideIcons.calendarCheck,
      label: 'Lịch hẹn tiếp theo',
      title: appt.title,
      subtitle: appt.date,
      isDark: isDark,
      onTap: () {
        HapticFeedback.selectionClick();
        context.go('/appointments');
      },
    );
  }
}

class _HeroVitals extends StatelessWidget {
  final String vitals;
  final String? date;
  final bool isDark;
  const _HeroVitals({required this.vitals, required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _HeroTile(
      color: AppTheme.kPrimaryDark,
      bgColor: isDark
          ? AppTheme.kPrimaryDark.withOpacity(0.12)
          : AppTheme.kPrimaryLight,
      icon: LucideIcons.activity,
      label: 'Chỉ số gần nhất',
      title: vitals,
      subtitle: date,
      isDark: isDark,
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/metrics');
      },
    );
  }
}

class _HeroMedicineCount extends StatelessWidget {
  final int count;
  final bool isDark;
  const _HeroMedicineCount({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _HeroTile(
      color: AppTheme.kPrimaryDark,
      bgColor: isDark
          ? AppTheme.kPrimaryDark.withOpacity(0.10)
          : AppTheme.kPrimaryLight,
      icon: LucideIcons.pill,
      label: 'Đang điều trị',
      title: count > 0 ? '$count thuốc đang dùng' : 'Chưa có thuốc nào',
      subtitle: count > 0 ? 'Nhấn để xem danh sách thuốc' : null,
      isDark: isDark,
      onTap: () {
        HapticFeedback.selectionClick();
        context.go('/medicines');
      },
    );
  }
}

/// Unified hero tile — tránh lặp code giữa 3 hero variants
class _HeroTile extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _HeroTile({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.18)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : AppTheme.kTextPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : AppTheme.kTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron
              Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact info row ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty && value != '—';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              // Icon + label (fixed width to prevent overflow)
              Icon(
                icon,
                size: 13,
                color: isDark
                    ? const Color(0xFF4A6080)
                    : const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 8),
              // Label — cố định max 50% width để value không bị đẩy
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.kTextSecondary
                        : AppTheme.kTextSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Value — bên phải, giới hạn 2 dòng, right-aligned
              Expanded(
                flex: 5,
                child: hasValue
                    ? Text(
                        value!,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : AppTheme.kTextPrimary,
                          height: 1.3,
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '—',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF2D3F55)
                                : AppTheme.kBorder,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF1E2D3D)
                : const Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}

