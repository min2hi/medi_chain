import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';

class HealthOverviewCard extends StatelessWidget {
  final DashboardStats? stats;

  const HealthOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.activity,
                  color: Color(0xFF14B8A6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tình trạng sức khỏe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            stats?.status ?? 'Bình thường',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dựa trên hồ sơ cập nhật gần nhất',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            LucideIcons.droplets,
            'Nhóm máu',
            stats?.profile?.bloodType ?? '—',
          ),
          _buildDivider(),
          _buildInfoRow(
            LucideIcons.shieldAlert,
            'Dị ứng',
            stats?.profile?.allergies ?? '—',
          ),
          _buildDivider(),
          _buildInfoRow(
            LucideIcons.clipboardList,
            'Bệnh nền / Chẩn đoán',
            stats?.latestDiagnosis ?? '—',
          ),
          _buildDivider(),
          _buildInfoRow(
            LucideIcons.activity,
            'Chỉ số gần nhất',
            stats?.latestVitalsText ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF1F5F9),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
