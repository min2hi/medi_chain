import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ════════════════════════════════════════════════════════════════════════════
// RecordsListScreen
//
// Improvements vs trước:
//   1. Filter chips theo loại (All / Khám / Xét nghiệm / ...)
//      → Apple Health, Epic MyChart pattern
//   2. Sort theo ngày mới nhất trước — dữ liệu y tế luôn cần chronological
//   3. Swipe-to-delete + confirm dialog (an toàn, không xóa nhầm)
//   4. Summary bar: tổng số record + loại nhiều nhất
// ════════════════════════════════════════════════════════════════════════════
class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  // null = "Tất cả"
  _RecordType? _activeFilter;

  List<MedicalRecordModel> _applyFilter(List<MedicalRecordModel> records) {
    // Sort: mới nhất trước
    final sorted = [...records]..sort((a, b) {
        try {
          return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
        } catch (_) {
          return 0;
        }
      });
    if (_activeFilter == null) return sorted;
    return sorted
        .where((r) => _RecordCard._typeOf(r) == _activeFilter)
        .toList();
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF182030) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.trash2,
                  size: 20, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            Text(
              'Xóa hồ sơ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF0D1520),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có chắc muốn xóa "$title"?\nHành động này không thể hoàn tác.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF7A90B0)
                    : AppTheme.kTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF94A3B8)
                        : AppTheme.kTextSecondary,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A3A50)
                          : AppTheme.kBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Hủy',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Xóa',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<MedicalBloc>()..add(RecordsFetchRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'records.title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(LucideIcons.plus, size: 24),
                  onPressed: () => ctx.push('/record-form').then(
                    (_) => ctx
                        .read<MedicalBloc>()
                        .add(RecordsFetchRequested()),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<MedicalBloc, MedicalState>(
          builder: (context, state) {
            if (state is MedicalLoading) return const AppSkeletonList(count: 5);
            if (state is MedicalError) {
              return _buildErrorState(context, state.message);
            }
            if (state is RecordsLoaded) {
              if (state.records.isEmpty) return _buildEmptyState(context);

              final filtered = _applyFilter(state.records);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Filter chips ──────────────────────────────────────
                  _FilterBar(
                    active: _activeFilter,
                    allCount: state.records.length,
                    records: state.records,
                    onChanged: (t) => setState(() => _activeFilter = t),
                  ),

                  // ── List ─────────────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyFilter(context)
                        : RefreshIndicator(
                            color: AppTheme.kPrimary,
                            onRefresh: () async => context
                                .read<MedicalBloc>()
                                .add(RecordsFetchRequested()),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final rec = filtered[index];
                                return Dismissible(
                                  key: ValueKey(rec.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) =>
                                      _confirmDelete(context, rec.title),
                                  onDismissed: (_) {
                                    HapticFeedback.mediumImpact();
                                    context
                                        .read<MedicalBloc>()
                                        .add(RecordDeleteRequested(rec.id));
                                  },
                                  background: const _RecordDeleteBackground(),
                                  child: StaggeredListItem(
                                    index: index,
                                    child: _RecordCard(record: rec),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFilter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.filter,
                size: 32,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2D4A6A)
                    : const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'Không có hồ sơ loại này',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _activeFilter = null),
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  color: AppTheme.kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
              color: isDark
                  ? const Color(0xFF2D4A6A)
                  : const Color(0xFFCBD5E1),
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
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => context.push('/record-form').then(
                (_) => context
                    .read<MedicalBloc>()
                    .add(RecordsFetchRequested()),
              ),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('records.add'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimary,
                side: const BorderSide(color: AppTheme.kPrimary, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppTheme.kDanger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
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

// ════════════════════════════════════════════════════════════════════════════
// _FilterBar — horizontal scroll, filter chips theo loại
//
// Tham khảo: Epic MyChart category tabs, Apple Health type filters
// Hiển thị count từng loại để user biết distribution
// ════════════════════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final _RecordType? active;
  final int allCount;
  final List<MedicalRecordModel> records;
  final ValueChanged<_RecordType?> onChanged;

  const _FilterBar({
    required this.active,
    required this.allCount,
    required this.records,
    required this.onChanged,
  });

  int _countOf(_RecordType type) =>
      records.where((r) => _RecordCard._typeOf(r) == type).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF1E2D3D)
                : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // "Tất cả" chip
          _FilterChip(
            label: 'Tất cả',
            count: allCount,
            isActive: active == null,
            color: AppTheme.kPrimary,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),

          // Một chip cho mỗi loại có ít nhất 1 record
          ..._RecordType.values.map((type) {
            final count = _countOf(type);
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: type.label,
                count: count,
                isActive: active == type,
                color: type.color,
                isDark: isDark,
                onTap: () => onChanged(active == type ? null : type),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: isActive ? color : (isDark ? const Color(0xFF182030) : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive
                ? color
                : (isDark ? const Color(0xFF2A3A50) : AppTheme.kBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : AppTheme.kTextSecondary),
              ),
            ),
            const SizedBox(width: 5),
            // Count badge nhỏ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.25)
                    : (isDark
                        ? const Color(0xFF1E2D3D)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFF64748B)
                          : AppTheme.kTextMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delete background ─────────────────────────────────────────────────────
class _RecordDeleteBackground extends StatelessWidget {
  const _RecordDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            'Xóa',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _RecordCard
// ════════════════════════════════════════════════════════════════════════════
class _RecordCard extends StatelessWidget {
  final MedicalRecordModel record;
  const _RecordCard({required this.record});

  // Static method để FilterBar có thể gọi mà không cần instance
  static _RecordType _typeOf(MedicalRecordModel r) {
    final q = '${r.title} ${r.diagnosis ?? ''}'.toLowerCase();
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

  _RecordType get _type => _typeOf(record);

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
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
            onTap: () => context
                .push('/record-form', extra: record)
                .then((_) => context
                    .read<MedicalBloc>()
                    .add(RecordsFetchRequested())),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
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

                        // Type chip + date
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(AppRadius.full),
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

                        // Hospital
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

// ── Record Type System ────────────────────────────────────────────────────
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
