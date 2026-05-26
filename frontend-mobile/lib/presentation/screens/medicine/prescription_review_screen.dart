import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/core/utils/prescription_parser.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';

/// Màn hình review & xác nhận các thuốc đã OCR.
///
/// Nhận [MedicineBloc] từ caller (qua BlocProvider.value) — không tạo instance mới.
/// User tick chọn, chỉnh sửa inline từng thuốc, rồi bulk-create qua BLoC.
///
/// Logic save đúng: Gọi [MedicineCreateRequested] tuần tự và lắng nghe
/// [MedicineActionSuccess] thay vì dùng Future.delayed giả tạo.
class PrescriptionReviewScreen extends StatefulWidget {
  final List<ParsedMedicine> medicines;
  final String rawText;

  const PrescriptionReviewScreen({
    super.key,
    required this.medicines,
    required this.rawText,
  });

  @override
  State<PrescriptionReviewScreen> createState() =>
      _PrescriptionReviewScreenState();
}

class _PrescriptionReviewScreenState extends State<PrescriptionReviewScreen> {
  late final List<_ItemState> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.medicines.map(_ItemState.fromParsed).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  /// Gọi MedicineCreateRequested cho từng thuốc được chọn, tuần tự.
  /// Mỗi call đợi BLoC emit Success/Error trước khi gửi item tiếp theo.
  Future<void> _saveAll() async {
    final bloc = context.read<MedicineBloc>();
    final selected = _items.where((i) => i.selected).toList();
    if (selected.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    int savedCount = 0;

    for (final item in selected) {
      final name = item.nameCtrl.text.trim();
      if (name.isEmpty) continue;

      final startDate = DateTime.now();
      final endDate = item.durationDays != null
          ? startDate.add(Duration(days: item.durationDays!))
          : null;

      bloc.add(
        MedicineCreateRequested({
          'name': name,
          'dosage': item.dosageCtrl.text.trim(),
          'frequency': item.freqCtrl.text.trim(),
          'instruction': item.instrCtrl.text.trim(),
          'startDate': startDate.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        }),
      );

      // Đợi BLoC xử lý xong (Success hoặc Error) trước khi gửi item tiếp
      await bloc.stream
          .firstWhere((s) => s is MedicineActionSuccess || s is MedicineError)
          .timeout(const Duration(seconds: 10), onTimeout: () => MedicineError('Timeout'));

      if (bloc.state is MedicineActionSuccess) savedCount++;
    }

    if (!mounted) return;

    setState(() => _isSaving = false);
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedCount > 0
              ? 'Đã thêm $savedCount thuốc vào tủ thuốc'
              : 'Không thể lưu thuốc',
        ),
        backgroundColor:
            savedCount > 0 ? AppTheme.kPrimaryDark : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    if (savedCount > 0) {
      // Pop cả scanner lẫn review về medicine list
      Navigator.pop(context); // review
      Navigator.pop(context); // scanner
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _items.where((i) => i.selected).length;
    final allSelected = _items.isNotEmpty && _items.every((i) => i.selected);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xác nhận thuốc'),
            Text(
              '${_items.length} thuốc nhận dạng được',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF182030) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0D1520),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final i in _items) i.selected = !allSelected;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.kPrimaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              allSelected ? 'Bỏ chọn' : 'Chọn tất cả',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: _items.isEmpty
          ? _EmptyView(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _items.length,
              itemBuilder: (_, i) => StaggeredListItem(
                index: i,
                child: _MedCard(
                  item: _items[i],
                  isDark: isDark,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
      bottomNavigationBar: _BottomBar(
        selectedCount: selectedCount,
        isSaving: _isSaving,
        onSave: _saveAll,
        isDark: isDark,
      ),
    );
  }
}

// ─── Medicine Card ────────────────────────────────────────────────────────────
class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.item,
    required this.isDark,
    required this.onChanged,
  });

  final _ItemState item;
  final bool isDark;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1520);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.selected ? AppTheme.kPrimaryDark.withOpacity(0.35) : border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row — tap để toggle select ──
          InkWell(
            onTap: () {
              item.selected = !item.selected;
              onChanged();
            },
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  // Checkbox — dùng built-in Checkbox, không tự vẽ
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: item.selected,
                      onChanged: (v) {
                        item.selected = v ?? false;
                        onChanged();
                      },
                      activeColor: AppTheme.kPrimaryDark,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nameCtrl.text.isEmpty
                          ? 'Tên thuốc'
                          : item.nameCtrl.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.nameCtrl.text.isEmpty
                            ? textSecondary
                            : textPrimary,
                      ),
                    ),
                  ),
                  if (item.durationDays != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${item.durationDays} ngày',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Edit fields (chỉ hiện khi đang được chọn) ──
          if (item.selected) ...[
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  _Field(
                    ctrl: item.nameCtrl,
                    icon: LucideIcons.pill,
                    label: 'Tên thuốc',
                    isDark: isDark,
                    onChanged: onChanged,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          ctrl: item.dosageCtrl,
                          icon: LucideIcons.activity,
                          label: 'Liều lượng',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          ctrl: item.freqCtrl,
                          icon: LucideIcons.clock,
                          label: 'Tần suất',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    ctrl: item.instrCtrl,
                    icon: LucideIcons.alignLeft,
                    label: 'Hướng dẫn sử dụng',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.icon,
    required this.label,
    required this.isDark,
    this.onChanged,
  });

  final TextEditingController ctrl;
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return TextField(
      controller: ctrl,
      onChanged: onChanged != null ? (_) => onChanged!() : null,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 14, color: textSecondary),
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        filled: true,
        fillColor: fill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selectedCount,
    required this.isSaving,
    required this.onSave,
    required this.isDark,
  });

  final int selectedCount;
  final bool isSaving;
  final VoidCallback onSave;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final divider =
        isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7);

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: selectedCount == 0 || isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.kPrimaryDark,
            disabledBackgroundColor: AppTheme.kPrimaryDark.withOpacity(0.35),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  selectedCount == 0
                      ? 'Chưa chọn thuốc nào'
                      : 'Thêm $selectedCount thuốc vào tủ thuốc',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.fileX,
            size: 36,
            color: isDark
                ? const Color(0xFF2A3A50)
                : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy thuốc nào',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item State ───────────────────────────────────────────────────────────────
class _ItemState {
  bool selected;
  final TextEditingController nameCtrl;
  final TextEditingController dosageCtrl;
  final TextEditingController freqCtrl;
  final TextEditingController instrCtrl;
  final int? durationDays;

  _ItemState({
    required this.selected,
    required this.nameCtrl,
    required this.dosageCtrl,
    required this.freqCtrl,
    required this.instrCtrl,
    this.durationDays,
  });

  factory _ItemState.fromParsed(ParsedMedicine m) => _ItemState(
        selected: true,
        nameCtrl: TextEditingController(text: m.name),
        dosageCtrl: TextEditingController(text: m.dosage),
        freqCtrl: TextEditingController(text: m.frequency),
        instrCtrl: TextEditingController(text: m.instruction),
        durationDays: m.durationDays,
      );

  void dispose() {
    nameCtrl.dispose();
    dosageCtrl.dispose();
    freqCtrl.dispose();
    instrCtrl.dispose();
  }
}




