import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_patient_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'patient_detail_sheet.dart';

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
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(search: _search),
              Expanded(child: _Body(search: _search)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.search});
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicPatientBloc, ClinicPatientState>(
      builder: (context, state) {
        final loadedState = state is ClinicPatientsLoaded ? state : null;
        final isLoaded = loadedState != null;
        final isError  = state is ClinicPatientError;
        final isRefreshing = loadedState?.isRefreshing ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                            fontSize: 26, fontWeight: FontWeight.w700,
                            color: _C.textPrimary, height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            key: ValueKey(state.runtimeType),
                            isLoaded
                                ? '${loadedState.patients.length} bệnh nhân đã đặt lịch'
                                : isError ? 'Không tải được — nhấn ↺ để thử lại' : 'Đang tải...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isError ? _C.textMuted : _C.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nút refresh luôn hiện — kể cả error state
                  if (!isRefreshing)
                    _IconBtn(
                      icon: Icons.refresh_rounded,
                      onTap: () => context.read<ClinicPatientBloc>().add(
                        isError
                            ? ClinicPatientsFetchRequested()
                            : ClinicPatientsRefreshRequested(),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 36, height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.kPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: search,
                  onChanged: (v) => context.read<ClinicPatientBloc>().add(ClinicPatientsSearchChanged(v)),
                  style: GoogleFonts.inter(fontSize: 14, color: _C.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, số điện thoại...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _C.textMuted),
                    suffixIcon: search.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              search.clear();
                              context.read<ClinicPatientBloc>().add(ClinicPatientsSearchChanged(''));
                            },
                            child: const Icon(Icons.close_rounded, size: 16, color: _C.textMuted),
                          )
                        : null,
                    filled: true,
                    fillColor: _C.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.kPrimary.withValues(alpha: 0.6), width: 1.5),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  const _Body({required this.search});
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicPatientBloc, ClinicPatientState>(
      builder: (context, state) {
        if (state is ClinicPatientLoading || state is ClinicPatientInitial) {
          return const _ShimmerList();
        }

        if (state is ClinicPatientError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<ClinicPatientBloc>().add(ClinicPatientsFetchRequested()),
          );
        }

        if (state is ClinicPatientsLoaded) {
          final items = state.filteredPatients;
          return RefreshIndicator(
            color: AppTheme.kPrimary,
            backgroundColor: _C.surface,
            strokeWidth: 2,
            onRefresh: () async {
              context.read<ClinicPatientBloc>().add(ClinicPatientsRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: items.isEmpty
                ? _EmptyView(query: state.searchQuery)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: items.length,
                    separatorBuilder: (context2, i2) => Divider(
                      height: 1, color: _C.border, indent: 56,
                    ),
                    itemBuilder: (context, i) => _PatientRow(patient: items[i]),
                  ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

// ─── Patient Row — Contacts.app style ────────────────────────────────────────
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});
  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Ẩn danh';
    final phone = patient['phone'] as String? ?? '';
    final count = (patient['count'] as num?)?.toInt() ?? 0;

    final date = DateTime.tryParse(patient['lastVisit'] ?? '')?.toLocal();
    final lastStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : null;

    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();

    // Consistent avatar color based on name hash
    final avatarColors = [
      const Color(0xFF14B8A6), // teal
      const Color(0xFF6366F1), // indigo
      const Color(0xFF8B5CF6), // violet
      const Color(0xFF3B82F6), // blue
      const Color(0xFF10B981), // emerald
      const Color(0xFFF59E0B), // amber
    ];
    final avatarColor = avatarColors[name.codeUnits.fold(0, (a, b) => a + b) % avatarColors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showPatientDetail(context, patient),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (phone.isNotEmpty) phone else 'Không có SĐT',
                        if (lastStr != null) 'Khám $lastStr',
                      ].join('  ·  '),
                      style: GoogleFonts.inter(fontSize: 12, color: _C.textSecondary),
                    ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.border),
                ),
                child: Text(
                  '$count lịch',
                  style: GoogleFonts.inter(fontSize: 11, color: _C.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: _C.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Icon(
                  isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
                  size: 26, color: _C.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSearch ? 'Không tìm thấy "$query"' : 'Chưa có bệnh nhân nào',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isSearch
                    ? 'Thử tìm bằng tên đầy đủ hoặc SĐT'
                    : 'Bệnh nhân sẽ xuất hiện khi đặt lịch',
                style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (!isSearch) ...[
                const SizedBox(height: 20),
                Text(
                  '↓  Kéo xuống để làm mới',
                  style: GoogleFonts.inter(fontSize: 11, color: _C.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────
class _ErrorView extends StatefulWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    setState(() => _retrying = true);
    widget.onRetry();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isColdStart = widget.message == 'server_cold_start';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.border),
              ),
              child: Icon(
                isColdStart ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
                size: 32, color: _C.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isColdStart ? 'Máy chủ đang khởi động' : 'Không tải được',
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isColdStart
                  ? 'Backend đang warm up (~30s).\nVui lòng bấm Thử lại sau vài giây.'
                  : widget.message,
              style: GoogleFonts.inter(
                fontSize: 13, color: _C.textSecondary, height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _retrying ? null : _handleRetry,
                icon: _retrying
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  _retrying ? 'Đang kết nối lại...' : 'Thử lại',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  disabledBackgroundColor: AppTheme.kPrimary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer list ─────────────────────────────────────────────────────────────
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  LinearGradient get _g => LinearGradient(
        begin: Alignment(_anim.value - 1, 0),
        end: Alignment(_anim.value, 0),
        colors: [_C.surface, _C.shimmer, _C.surface],
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        itemCount: 7,
        separatorBuilder: (ctx, i) => Divider(height: 1, color: _C.border, indent: 56),
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(gradient: _g, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 13, width: double.infinity,
                    decoration: BoxDecoration(gradient: _g, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 11, width: 180,
                    decoration: BoxDecoration(gradient: _g, borderRadius: BorderRadius.circular(3))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Icon button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.border),
          ),
          child: Icon(icon, size: 18, color: _C.textSecondary),
        ),
      );
}

// ─── Color palette ────────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFF080E1A);
  static const surface      = Color(0xFF0F1829);
  static const shimmer      = Color(0xFF1A2840);
  static const border       = Color(0xFF1E2D42);
  static const textPrimary  = Color(0xFFEFF3FF);
  static const textSecondary= Color(0xFF7A90B0);
  static const textMuted    = Color(0xFF3D5166);
}
