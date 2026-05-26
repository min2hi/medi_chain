import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/medical/medical_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';

class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MedicalBloc>()..add(RecordsFetchRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'records.title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(LucideIcons.plus, size: 24),
                onPressed: () => context.push('/record-form').then(
                  (_) => context.read<MedicalBloc>().add(RecordsFetchRequested()),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<MedicalBloc, MedicalState>(
          builder: (context, state) {
            if (state is MedicalLoading) return const AppSkeletonList(count: 5);
            if (state is MedicalError) return _buildErrorState(context, state.message);
            if (state is RecordsLoaded) {
              if (state.records.isEmpty) return _buildEmptyState(context);
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<MedicalBloc>().add(RecordsFetchRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) => StaggeredListItem(
                    index: index,
                    child: _RecordCard(record: state.records[index]),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 36,
              color: isDark ? const Color(0xFF2D4A6A) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 20),
            Text(
              'records.empty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'records.empty_sub'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => context.push('/record-form').then(
                (_) => context.read<MedicalBloc>().add(RecordsFetchRequested()),
              ),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('records.add'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimary,
                side: const BorderSide(color: AppTheme.kPrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppTheme.kDanger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<MedicalBloc>().add(RecordsFetchRequested()),
              child: Text('records.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Record Card — icon system per type ───────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final MedicalRecordModel record;
  const _RecordCard({required this.record});

  _RecordType get _type {
    final q = '${record.title} ${record.diagnosis ?? ''}'.toLowerCase();
    if (q.contains('xét nghiệm') ||
        q.contains('lab') ||
        q.contains('máu') ||
        q.contains('nước tiểu')) return _RecordType.lab;
    if (q.contains('đơn thuốc') ||
        q.contains('toa') ||
        q.contains('prescription')) return _RecordType.prescription;
    if (q.contains('nhập viện') ||
        q.contains('phẫu thuật') ||
        q.contains('mổ') ||
        q.contains('hospital')) return _RecordType.hospitalization;
    if (q.contains('chủng ngừa') ||
        q.contains('vắc') ||
        q.contains('vaccine')) return _RecordType.vaccine;
    return _RecordType.checkup;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : AppTheme.kSurface;
    final border  = isDark ? const Color(0xFF2D3F55) : AppTheme.kBorder;
    final type    = _type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
        boxShadow: isDark ? null : AppShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/record-form', extra: record).then(
              (_) => context.read<MedicalBloc>().add(RecordsFetchRequested()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon — the DNA of this card
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: type.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(type.icon, size: 18, color: type.color),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + chevron
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                record.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFE2E8F0)
                                      : AppTheme.kTextPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 15,
                              color: isDark
                                  ? const Color(0xFF4A6080)
                                  : AppTheme.kBorder,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Type chip + date row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(0.10),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                type.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: type.color,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.calendar,
                              size: 11,
                              color: isDark
                                  ? const Color(0xFF4A6080)
                                  : AppTheme.kTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(record.date)),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.kTextMuted,
                              ),
                            ),
                          ],
                        ),

                        // Hospital row
                        if (record.hospital != null &&
                            record.hospital!.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.building2,
                                size: 11,
                                color: isDark
                                    ? const Color(0xFF4A6080)
                                    : AppTheme.kTextMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  record.hospital!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.kTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Diagnosis chip
                        if (record.diagnosis != null &&
                            record.diagnosis!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.kPrimaryDark.withOpacity(0.12)
                                  : AppTheme.kPrimaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              record.diagnosis!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF5EEAD4)
                                    : AppTheme.kPrimaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Record Type System ────────────────────────────────────────────────────────

enum _RecordType { checkup, lab, prescription, hospitalization, vaccine }

extension _RecordTypeX on _RecordType {
  IconData get icon => switch (this) {
        _RecordType.checkup         => LucideIcons.stethoscope,
        _RecordType.lab             => LucideIcons.flaskConical,
        _RecordType.prescription    => LucideIcons.fileText,
        _RecordType.hospitalization => LucideIcons.hotel,
        _RecordType.vaccine         => LucideIcons.syringe,
      };

  Color get color => switch (this) {
        _RecordType.checkup         => AppTheme.kPrimary,
        _RecordType.lab             => const Color(0xFF8B5CF6),
        _RecordType.prescription    => const Color(0xFF3B82F6),
        _RecordType.hospitalization => AppTheme.kDanger,
        _RecordType.vaccine         => AppTheme.kSuccess,
      };

  String get label => switch (this) {
        _RecordType.checkup         => 'Khám tổng quát',
        _RecordType.lab             => 'Xét nghiệm',
        _RecordType.prescription    => 'Đơn thuốc',
        _RecordType.hospitalization => 'Nhập viện',
        _RecordType.vaccine         => 'Tiêm chủng',
      };
}

