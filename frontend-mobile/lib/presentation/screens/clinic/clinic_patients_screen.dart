import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_patient_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'patient_detail_sheet.dart';

/// ClinicPatientsScreen — enterprise-grade patient registry.
/// Design: Clean monochrome list, Practo-style detail on tap.
class ClinicPatientsScreen extends StatefulWidget {
  const ClinicPatientsScreen({super.key});

  @override
  State<ClinicPatientsScreen> createState() => _ClinicPatientsScreenState();
}

class _ClinicPatientsScreenState extends State<ClinicPatientsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
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
                      style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Refresh icon button
              if (state is ClinicPatientsLoaded)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: AdminColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => ctx.read<ClinicPatientBloc>().add(ClinicPatientsRefreshRequested()),
                    tooltip: 'Làm mới',
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
          onChanged: (val) =>
              context.read<ClinicPatientBloc>().add(ClinicPatientsSearchChanged(val)),
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tên, số điện thoại...',
            hintStyle: GoogleFonts.inter(color: AdminColors.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.textSecondary, size: 18),
            suffixIcon: _search.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AdminColors.textMuted),
                    onPressed: () {
                      _search.clear();
                      context.read<ClinicPatientBloc>().add(ClinicPatientsSearchChanged(''));
                    },
                  )
                : null,
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
          return _PatientShimmerList();
        }

        if (state is ClinicPatientError) {
          return _ErrorState(
            message: state.message,
            onRetry: () => context.read<ClinicPatientBloc>().add(ClinicPatientsFetchRequested()),
          );
        }

        if (state is ClinicPatientsLoaded) {
          final filtered = state.filteredPatients;

          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: AdminColors.surface,
            onRefresh: () async {
              context.read<ClinicPatientBloc>().add(ClinicPatientsRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: filtered.isEmpty
                ? _emptyList(state.searchQuery)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context2, i2) => const Divider(
                      height: 1,
                      color: AdminColors.border,
                      indent: 56,
                    ),
                    itemBuilder: (context, i) => _PatientRow(patient: filtered[i]),
                  ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _emptyList(String query) {
    final isSearch = query.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 340,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AdminColors.elevated,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Icon(
                  isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
                  size: 32,
                  color: AdminColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSearch ? 'Không tìm thấy "$query"' : 'Chưa có bệnh nhân nào',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSearch ? 'Thử tìm bằng tên đầy đủ hoặc SĐT' : 'Bệnh nhân sẽ xuất hiện khi đặt lịch',
                style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
              ),
              if (!isSearch) ...[
                const SizedBox(height: 6),
                Text(
                  'Kéo xuống để làm mới',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: AdminColors.textMuted, fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shimmer list ─────────────────────────────────────────────────────────────
class _PatientShimmerList extends StatefulWidget {
  @override
  State<_PatientShimmerList> createState() => _PatientShimmerListState();
}

class _PatientShimmerListState extends State<_PatientShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: 6,
      separatorBuilder: (context2, i2) => const Divider(height: 1, color: AdminColors.border, indent: 56),
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _anim,
        builder: (ctx2, snapshot) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_anim.value - 1, 0),
                    end: Alignment(_anim.value, 0),
                    colors: [AdminColors.elevated, AdminColors.surface, AdminColors.elevated],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_anim.value - 1, 0),
                          end: Alignment(_anim.value, 0),
                          colors: [AdminColors.elevated, AdminColors.surface, AdminColors.elevated],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_anim.value - 1, 0),
                          end: Alignment(_anim.value, 0),
                          colors: [AdminColors.elevated, AdminColors.surface, AdminColors.elevated],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AdminColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(Icons.wifi_off_rounded, size: 32,
                  color: AdminColors.danger.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text('Không thể tải dữ liệu',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
            const SizedBox(height: 6),
            Text(message,
                style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Thử lại', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimary,
                side: BorderSide(color: AppTheme.kPrimary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Patient Row ──────────────────────────────────────────────────────────────
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});
  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Ẩn danh';
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : (name.length >= 2 ? name.substring(0, 2) : name);

    final date = DateTime.tryParse(patient['lastVisit'] ?? '')?.toLocal();
    final lastVisitStr =
        date != null ? '${date.day}/${date.month}/${date.year}' : 'Chưa có';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showPatientDetail(context, patient),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AdminColors.elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
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
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient['phone'] ?? 'Không có SĐT'}  ·  Khám gần nhất $lastVisitStr',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.elevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${patient['count'] ?? 0} lịch',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w500,
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
