import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

import 'package:medi_chain_mobile/logic/clinic/clinic_patient_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';

/// ClinicPatientsScreen — redesigned.
/// Clean patient registry, monochrome avatars, compact info rows.
class ClinicPatientsScreen extends StatefulWidget {
  const ClinicPatientsScreen({super.key});

  @override
  State<ClinicPatientsScreen> createState() => _ClinicPatientsScreenState();
}

class _ClinicPatientsScreenState extends State<ClinicPatientsScreen> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ClinicPatientBloc>()..add(ClinicPatientsFetchRequested()),
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearch(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<ClinicPatientBloc, ClinicPatientState>(
      builder: (context, state) {
        final count = state is ClinicPatientsLoaded ? state.patients.length : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bệnh Nhân',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count bệnh nhân đã đặt lịch',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearch() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: TextField(
          controller: _search,
          onChanged: (val) => context.read<ClinicPatientBloc>().add(ClinicPatientsSearchChanged(val)),
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tên, số điện thoại...',
            hintStyle: GoogleFonts.inter(color: AdminColors.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.textSecondary, size: 18),
            filled: true,
            fillColor: AdminColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.kPrimary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return BlocBuilder<ClinicPatientBloc, ClinicPatientState>(
      builder: (context, state) {
        if (state is ClinicPatientLoading || state is ClinicPatientInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ClinicPatientError) {
          return Center(child: Text(state.message, style: GoogleFonts.inter(color: AdminColors.danger)));
        }
        if (state is ClinicPatientsLoaded) {
          final filtered = state.filteredPatients;
          if (filtered.isEmpty) {
            return Center(child: Text('Không tìm thấy', style: GoogleFonts.inter(color: AdminColors.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: filtered.length,
            separatorBuilder: (context2, i2) => const Divider(height: 1, color: AdminColors.border, indent: 56),
            itemBuilder: (context, i) => _PatientRow(patient: filtered[i]),
          );
        }
        return const SizedBox();
      },
    );
  }
}

// ─── Patient row — compact, linear style ─────────────────────────────────────
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});
  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    // Initials — max 2 chars
    final name = patient['name'] ?? 'Ẩn danh';
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : (name.length >= 2 ? name.substring(0, 2) : name);
        
    final date = DateTime.tryParse(patient['lastVisit'] ?? '')?.toLocal();
    final lastVisitStr = date != null ? '${date.day}/${date.month}/${date.year}' : 'Chưa có';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Avatar — monochrome, no random colors
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminColors.elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textSecondary,
                    ),
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
                        fontWeight: FontWeight.w500,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient['phone'] ?? 'Không có SĐT'}  ·  Khám gần nhất $lastVisitStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Appointment count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.elevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${patient['count'] ?? 0} lịch',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AdminColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
