import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class AlertSection extends StatelessWidget {
  final List<AlertItem> alerts;

  const AlertSection({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: alerts.map((alert) => _buildAlertItem(context, alert)).toList(),
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertItem alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
