import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class TodayScheduleCard extends StatelessWidget {
  final DashboardStats? stats;

  const TodayScheduleCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final upcomingAppointment = stats?.upcomingAppointment;
    final medicines = stats?.medicines ?? [];
    final medicineCount = stats?.medicineCount ?? 0;

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
                LucideIcons.calendar,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                size: 22,
              ),
              SizedBox(width: 12),
              Text(
                'Lịch trình hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (upcomingAppointment != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1E293B) : Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF334155) : Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: Color(0xFF14B8A6),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tái khám sắp tới',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${upcomingAppointment.title} — ${DateFormat('dd/MM/yyyy').format(DateTime.parse(upcomingAppointment.date))}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          if (medicineCount > 0) ...[
            Text.rich(
              TextSpan(
                text: 'Bạn đang theo dõi ',
                children: [
                  TextSpan(
                    text: '$medicineCount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const TextSpan(text: ' loại thuốc đang điều trị.'),
                ],
              ),
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            SizedBox(height: 12),
            Column(
              children: medicines.map((m) => _buildMedicineTile(context, m)).toList(),
            ),
          ] else
            Text(
              'Không có đơn thuốc nào đang hoạt động.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicineTile(BuildContext context, MedicineSummary med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Text(
            '${med.name}${med.dosage != null ? ' · ${med.dosage}' : ''}${med.frequency != null ? ' · ${med.frequency}' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
