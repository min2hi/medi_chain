import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';

// ─── Model nội bộ ─────────────────────────────────────────────────────────────
enum _EventType { appointment, record, medicine }

class _Event {
  final String id;
  final DateTime date;
  final String title;
  final String? subtitle;
  final String? detail;
  final _EventType type;

  const _Event({
    required this.id,
    required this.date,
    required this.title,
    this.subtitle,
    this.detail,
    required this.type,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
/// Hành trình sức khỏe — hiển thị appointments, hồ sơ bệnh, đơn thuốc
/// theo trục thời gian từ mới đến cũ.
/// Không cần sensor/wearable — chỉ join data đã có trong backend.
class HealthTimelineScreen extends StatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> {
  final _repo = getIt<MedicalRepository>();

  List<_Event> _events = [];
  bool _loading = true;
  String? _error;

  bool _showAppointments = true;
  bool _showRecords      = true;
  bool _showMedicines    = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getAppointments(),
        _repo.getRecords(),
        _repo.getMedicines(),
      ]);

      final aptRes = results[0] as AppointmentsResponse;
      final recRes = results[1] as MedicalRecordsResponse;
      final medRes = results[2] as MedicinesResponse;

      final events = <_Event>[];

      for (final a in aptRes.data ?? []) {
        final dt = DateTime.tryParse(a.date);
        if (dt == null) continue;
        events.add(_Event(
          id: a.id,
          date: dt.toLocal(),
          title: a.title,
          subtitle: _aptLabel(a.status ?? 'PENDING'),
          detail: a.doctorNotes?.isNotEmpty == true
              ? a.doctorNotes
              : (a.notes?.isNotEmpty == true ? a.notes : null),
          type: _EventType.appointment,
        ));
      }

      for (final r in recRes.data ?? []) {
        final dt = DateTime.tryParse(r.date);
        if (dt == null) continue;
        events.add(_Event(
          id: r.id,
          date: dt.toLocal(),
          title: r.title,
          subtitle: r.diagnosis?.isNotEmpty == true ? r.diagnosis : r.hospital,
          detail: r.treatment,
          type: _EventType.record,
        ));
      }

      for (final m in medRes.data ?? []) {
        final dt = DateTime.tryParse(m.startDate);
        if (dt == null) continue;
        final parts = [
          if (m.dosage?.isNotEmpty == true) m.dosage!,
          if (m.frequency?.isNotEmpty == true) m.frequency!,
        ];
        events.add(_Event(
          id: m.id,
          date: dt.toLocal(),
          title: m.name,
          subtitle: parts.isEmpty ? null : parts.join(' · '),
          detail: m.instruction,
          type: _EventType.medicine,
        ));
      }

      events.sort((a, b) => b.date.compareTo(a.date));
      setState(() { _events = events; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Không thể tải dữ liệu. Vui lòng thử lại.'; _loading = false; });
    }
  }

  String _aptLabel(String status) => switch (status) {
        'COMPLETED' => 'Đã khám',
        'CONFIRMED' => 'Đã xác nhận',
        'CANCELLED' => 'Đã hủy',
        _           => 'Chờ khám',
      };

  List<_Event> get _filtered => _events.where((e) {
        if (!_showAppointments && e.type == _EventType.appointment) return false;
        if (!_showRecords      && e.type == _EventType.record)      return false;
        if (!_showMedicines    && e.type == _EventType.medicine)    return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng theme scaffold color — không override riêng
      appBar: AppBar(
        title: const Text('Hành trình sức khỏe'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppTheme.kPrimary,
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final items = _filtered;
    return Column(
      children: [
        _FilterRow(
          showAppointments: _showAppointments,
          showRecords: _showRecords,
          showMedicines: _showMedicines,
          onToggle: (type) => setState(() {
            if (type == _EventType.appointment) _showAppointments = !_showAppointments;
            if (type == _EventType.record)      _showRecords      = !_showRecords;
            if (type == _EventType.medicine)    _showMedicines    = !_showMedicines;
          }),
        ),
        Expanded(
          child: items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final showYear = i == 0 ||
                          items[i - 1].date.year != items[i].date.year;
                      return StaggeredListItem(
                        index: i,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showYear) _YearDivider(year: items[i].date.year),
                            _EventRow(
                              event: items[i],
                              isLast: i == items.length - 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.heartPulse,
              size: 36,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D4A6A)
                  : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có sự kiện nào',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lịch hẹn, hồ sơ bệnh và đơn thuốc\nsẽ xuất hiện ở đây theo thứ tự thời gian.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 36, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimary,
                side: const BorderSide(color: AppTheme.kPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter row ───────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final bool showAppointments;
  final bool showRecords;
  final bool showMedicines;
  final void Function(_EventType) onToggle;

  const _FilterRow({
    required this.showAppointments,
    required this.showRecords,
    required this.showMedicines,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Lịch hẹn',
            icon: LucideIcons.calendarCheck,
            active: showAppointments,
            color: AppTheme.kPrimary,
            onTap: () => onToggle(_EventType.appointment),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Hồ sơ',
            icon: LucideIcons.fileText,
            active: showRecords,
            color: const Color(0xFF3B82F6),
            onTap: () => onToggle(_EventType.record),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Thuốc',
            icon: LucideIcons.pill,
            active: showMedicines,
            color: const Color(0xFF8B5CF6),
            onTap: () => onToggle(_EventType.medicine),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = active
        ? color
        : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(isDark ? 0.12 : 0.07) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color.withOpacity(0.30) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Year divider ─────────────────────────────────────────────────────────────
class _YearDivider extends StatelessWidget {
  final int year;
  const _YearDivider({required this.year});

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color;
    final lineColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3A50)
        : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            '$year',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: mutedColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}

// ─── Event row ────────────────────────────────────────────────────────────────
// Giữ layout timeline nhưng dùng style đồng nhất với records_list_screen:
//  - Card dùng Theme.cardColor, border từ theme
//  - Accent left bar 4px (giống record card) thay vì icon box riêng
//  - Text dùng Theme.textTheme thay vì hardcode color
class _EventRow extends StatelessWidget {
  final _Event event;
  final bool isLast;

  const _EventRow({required this.event, required this.isLast});

  static const _colors = {
    _EventType.appointment: AppTheme.kPrimary,
    _EventType.record:      Color(0xFF3B82F6),
    _EventType.medicine:    Color(0xFF8B5CF6),
  };

  static const _icons = {
    _EventType.appointment: LucideIcons.calendarCheck,
    _EventType.record:      LucideIcons.fileText,
    _EventType.medicine:    LucideIcons.pill,
  };

  static const _months = [
    'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
    'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final accent     = _colors[event.type]!;
    final icon       = _icons[event.type]!;
    final borderColor = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date ──
          SizedBox(
            width: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${event.date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    height: 1,
                  ),
                ),
                Text(
                  _months[event.date.month - 1],
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          // ── Connector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: borderColor,
                    ),
                  ),
              ],
            ),
          ),

          // ── Card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Accent bar — giống records_list_screen
                      Container(width: 4, color: accent),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + icon
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.color,
                                      ),
                                    ),
                                  ),
                                  Icon(icon, size: 14, color: accent),
                                ],
                              ),
                              // Subtitle
                              if (event.subtitle?.isNotEmpty == true) ...[
                                const SizedBox(height: 5),
                                Text(
                                  event.subtitle!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ],
                              // Detail note
                              if (event.detail?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF115E59)
                                        : const Color(0xFFF0FDFA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    event.detail!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.kPrimary,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

