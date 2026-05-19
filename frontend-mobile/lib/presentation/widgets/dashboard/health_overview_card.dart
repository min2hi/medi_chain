import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class HealthOverviewCard extends StatelessWidget {
  final DashboardStats? stats;

  const HealthOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.activity,
                color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
                size: 22,
              ),
              SizedBox(width: 12),
              Text(
                'TÃ¬nh tráº¡ng sá»©c khá»e',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            stats?.status ?? 'BÃ¬nh thÆ°á»ng',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Dá»±a trÃªn há»“ sÆ¡ cáº­p nháº­t gáº§n nháº¥t',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 24),
          _buildInfoRow(
            context,
            LucideIcons.droplets,
            'NhÃ³m mÃ¡u',
            stats?.profile?.bloodType ?? 'â€”',
          ),
          _buildDivider(context),
          _buildInfoRow(
            context,
            LucideIcons.shieldAlert,
            'Dá»‹ á»©ng',
            stats?.profile?.allergies ?? 'â€”',
          ),
          _buildDivider(context),
          _buildInfoRow(
            context,
            LucideIcons.clipboardList,
            'Bá»‡nh ná»n / Cháº©n Ä‘oÃ¡n',
            stats?.latestDiagnosis ?? 'â€”',
          ),
          _buildDivider(context),
          _buildInfoRow(
            context,
            LucideIcons.activity,
            'Chá»‰ sá»‘ gáº§n nháº¥t',
            stats?.latestVitalsText ?? 'â€”',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Color(0xFF94A3B8)),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF334155) : Color(0xFFF1F5F9),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
