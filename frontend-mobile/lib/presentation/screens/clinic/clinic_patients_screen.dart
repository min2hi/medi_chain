import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// ClinicPatientsScreen — Danh sách bệnh nhân dành cho Doctor/Admin.
/// Hiển thị users đã đặt lịch, cho phép xem hồ sơ y tế được chia sẻ.
class ClinicPatientsScreen extends StatelessWidget {
  const ClinicPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildPatientList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdminColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: AdminColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bệnh Nhân',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              Text(
                'Danh sách bệnh nhân đã đặt lịch',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bệnh nhân...',
          hintStyle: GoogleFonts.inter(color: AdminColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AdminColors.textSecondary, size: 20),
          filled: true,
          fillColor: AdminColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AdminColors.aiPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    // TODO: Connect to API — patients who have appointments with this clinic
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => _PatientCard(
        name: 'Bệnh nhân ${index + 1}',
        phone: '090${index}000000',
        lastVisit: '${14 - index}/05/2026',
        appointmentCount: index + 1,
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.name,
    required this.phone,
    required this.lastVisit,
    required this.appointmentCount,
  });

  final String name;
  final String phone;
  final String lastVisit;
  final int appointmentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AdminColors.info.withValues(alpha: 0.15),
            child: Text(
              name[0],
              style: GoogleFonts.inter(
                color: AdminColors.info,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lần khám gần nhất: $lastVisit • $appointmentCount lịch hẹn',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: navigate to patient detail
            },
            icon: const Icon(Icons.chevron_right_rounded,
                color: AdminColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
