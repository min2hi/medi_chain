import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/core/utils/prescription_parser.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';

/// PatientResultSheet — "After Visit Summary" cho bệnh nhân.
/// Thiết kế theo Epic MyChart: clinical, trắng sạch, typography rõ ràng.
void showPatientResultSheet(BuildContext context, AppointmentModel apt) {
  final medicineBloc = context.read<MedicineBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: medicineBloc,
      child: _PatientResultSheet(apt: apt),
    ),
  );
}

class _PatientResultSheet extends StatelessWidget {
  final AppointmentModel apt;
  const _PatientResultSheet({required this.apt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF182030) : Colors.white;
    final surface = isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1520);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);

    final date = DateTime.tryParse(apt.date)?.toLocal();
    final completedDate = apt.completedAt != null
        ? DateTime.tryParse(apt.completedAt!)?.toLocal()
        : null;
    final hasDoctorNotes = apt.doctorNotes != null && apt.doctorNotes!.isNotEmpty;

    String fmt(DateTime? d) {
      if (d == null) return '--';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    String fee(int? f) {
      if (f == null) return 'Không có';
      final parts = f.toString().split('').reversed.toList();
      return '${List.generate(parts.length, (i) => (i > 0 && i % 3 == 0) ? '${parts[i]}.' : parts[i]).reversed.join()}đ';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: border, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header với status badge ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.clipboardList, size: 20, color: AppTheme.kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả sau khám',
                          style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: textColor,
                          ),
                        ),
                        Text(
                          apt.title,
                          style: GoogleFonts.inter(fontSize: 13, color: subColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.kPrimary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Hoàn thành',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: border),

            // ── Scrollable content ────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [

                  // ── Ghi chú bác sĩ (Most important — top) ───────
                  _SectionLabel(
                    icon: LucideIcons.stethoscope,
                    text: 'GHI CHÚ CỦA BÁC SĨ',
                    color: AppTheme.kPrimary,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasDoctorNotes
                          ? (isDark ? const Color(0xFF0F2A2A) : const Color(0xFFF0FDFA))
                          : surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasDoctorNotes
                            ? AppTheme.kPrimary.withOpacity(0.2)
                            : border,
                      ),
                    ),
                    child: hasDoctorNotes
                        ? Text(
                            apt.doctorNotes!,
                            style: GoogleFonts.inter(
                              fontSize: 14, color: textColor, height: 1.7,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(LucideIcons.info, size: 16, color: subColor),
                              const SizedBox(width: 8),
                              Text(
                                'Bác sĩ chưa để lại ghi chú',
                                style: GoogleFonts.inter(
                                  fontSize: 13, color: subColor, fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                  ),

                  if (hasDoctorNotes) ...[
                    Builder(
                      builder: (ctx) {
                        final parsedMeds = _parseDoctorNotes(apt.doctorNotes);
                        if (parsedMeds.isEmpty) return const SizedBox();
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showImportConfirmation(ctx, parsedMeds),
                              icon: const Icon(LucideIcons.download, size: 16),
                              label: const Text(
                                'Nhập đơn thuốc vào Tủ thuốc',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kPrimaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Thông tin buổi khám ───────────────────────────
                  _SectionLabel(
                    icon: LucideIcons.calendar,
                    text: 'THÔNG TIN BUỔI KHÁM',
                    color: subColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Lý do khám',
                          value: apt.title,
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Ngày khám',
                          value: fmt(date),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Hoàn thành lúc',
                          value: fmt(completedDate),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Phí khám',
                          value: fee(apt.consultFee),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: 'Thanh toán',
                          value: _paymentLabel(apt.paymentStatus),
                          valueColor: _paymentColor(apt.paymentStatus),
                          isDark: isDark,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  // ── Ghi chú bệnh nhân (nếu có) ──────────────────
                  if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                      icon: LucideIcons.messageSquare,
                      text: 'GHI CHÚ KHI ĐẶT LỊCH',
                      color: subColor,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        apt.notes!,
                        style: GoogleFonts.inter(
                          fontSize: 13, color: subColor, height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String? status) {
    switch (status) {
      case 'PAID': return 'Đã thanh toán';
      case 'PENDING': return 'Đang xử lý';
      case 'FAILED': return 'Thất bại';
      case 'REFUNDED': return 'Đã hoàn tiền';
      default: return 'Chưa thanh toán';
    }
  }

  Color _paymentColor(String? status) {
    switch (status) {
      case 'PAID': return const Color(0xFF10B981);
      case 'PENDING': return const Color(0xFFF59E0B);
      case 'FAILED': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }

  List<ParsedMedicine> _parseDoctorNotes(String? notes) {
    if (notes == null || notes.isEmpty) return [];
    final results = <ParsedMedicine>[];
    final lines = notes.split('\n');
    
    bool isMedicationSection = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'THUỐC KÊ:') {
        isMedicationSection = true;
        continue;
      }
      if (trimmed.startsWith('───') || trimmed == 'LỜI DẶN:') {
        isMedicationSection = false;
        continue;
      }
      
      if (isMedicationSection && trimmed.startsWith('•')) {
        final medText = trimmed.substring(1).trim();
        final parts = medText.split(RegExp(r'\s*[—\-]\s*'));
        if (parts.isNotEmpty) {
          final nameAndDosage = parts[0].trim();
          
          String name = nameAndDosage;
          String dosage = '';
          
          final dosageRegex = RegExp(
            r'^(.*?)\s+(\d+(?:[,.]\d+)?\s*(?:mg|mcg|g|ml|IU|%|viên|vien|gói|goi|ống|ong|giọt|giot))$',
            caseSensitive: false,
          );
          final match = dosageRegex.firstMatch(nameAndDosage);
          if (match != null) {
            name = match.group(1)?.trim() ?? nameAndDosage;
            dosage = match.group(2)?.trim() ?? '';
          }
          
          String frequency = '';
          if (parts.length > 1) {
            frequency = parts[1].trim();
          }
          
          int? durationDays;
          if (parts.length > 2) {
            final durationStr = parts[2].trim();
            final daysMatch = RegExp(r'(\d+)\s*ngày', caseSensitive: false).firstMatch(durationStr);
            if (daysMatch != null) {
              durationDays = int.tryParse(daysMatch.group(1) ?? '');
            }
          }
          
          results.add(ParsedMedicine(
            name: name,
            dosage: dosage,
            frequency: frequency,
            durationDays: durationDays,
          ));
        }
      }
    }
    return results;
  }

  void _showImportConfirmation(BuildContext context, List<ParsedMedicine> meds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF182030) : Colors.white;
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1520);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => _ImportConfirmationSheet(
        meds: meds,
        medicineBloc: context.read<MedicineBloc>(),
        isDark: isDark,
        surface: surface,
        border: border,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _SectionLabel({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool showDivider;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1520);
    final border = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, color: subColor),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? textColor,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: border, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _ImportConfirmationSheet extends StatefulWidget {
  final List<ParsedMedicine> meds;
  final MedicineBloc medicineBloc;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _ImportConfirmationSheet({
    required this.meds,
    required this.medicineBloc,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_ImportConfirmationSheet> createState() => _ImportConfirmationSheetState();
}

class _ImportConfirmationSheetState extends State<_ImportConfirmationSheet> {
  late List<bool> _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.meds.length, true);
    
    // Mặc định bỏ chọn các thuốc đã trùng lặp trong tủ thuốc
    final state = widget.medicineBloc.state;
    if (state is MedicinesLoaded) {
      _applyDuplicateDefaults(state.medicines);
    }
  }

  void _applyDuplicateDefaults(List<MedicineModel> existingMeds) {
    for (int i = 0; i < widget.meds.length; i++) {
      final med = widget.meds[i];
      final cleanNewName = med.name.trim().toLowerCase();
      final isDup = existingMeds.any((existing) {
        final cleanExistingName = existing.name.trim().toLowerCase();
        final isNameMatch = cleanNewName == cleanExistingName;
        
        bool isActive = true;
        if (existing.endDate != null) {
          try {
            final end = DateTime.parse(existing.endDate!);
            isActive = end.isAfter(DateTime.now());
          } catch (_) {
            isActive = true;
          }
        }
        return isNameMatch && isActive;
      });
      if (isDup) {
        _selected[i] = false;
      }
    }
  }

  Future<void> _importMedicines() async {
    final selectedMeds = <ParsedMedicine>[];
    for (int i = 0; i < widget.meds.length; i++) {
      if (_selected[i]) {
        selectedMeds.add(widget.meds[i]);
      }
    }

    if (selectedMeds.isEmpty) return;

    setState(() => _isSaving = true);
    int savedCount = 0;

    for (final med in selectedMeds) {
      final startDate = DateTime.now();
      final endDate = med.durationDays != null
          ? startDate.add(Duration(days: med.durationDays!))
          : null;

      widget.medicineBloc.add(
        MedicineCreateRequested({
          'name': med.name,
          'dosage': med.dosage,
          'frequency': med.frequency,
          'instruction': med.instruction,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        }),
      );

      // Wait for BLoC action to succeed or fail before next item
      final resultState = await widget.medicineBloc.stream
          .firstWhere((s) => s is MedicineActionSuccess || s is MedicineError)
          .timeout(const Duration(seconds: 10), onTimeout: () => MedicineError('Timeout'));

      if (resultState is MedicineActionSuccess) {
        savedCount++;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pop(context); // Close confirmation sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedCount > 0
              ? 'Đã thêm thành công $savedCount thuốc vào Tủ thuốc!'
              : 'Không thể thêm thuốc. Vui lòng thử lại.',
        ),
        backgroundColor: savedCount > 0 ? AppTheme.kPrimaryDark : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicineBloc, MedicineState>(
      bloc: widget.medicineBloc,
      builder: (context, state) {
        final existingMeds = state is MedicinesLoaded ? state.medicines : <MedicineModel>[];

        final isDuplicateList = widget.meds.map((med) {
          final cleanNewName = med.name.trim().toLowerCase();
          return existingMeds.any((existing) {
            final cleanExistingName = existing.name.trim().toLowerCase();
            final isNameMatch = cleanNewName == cleanExistingName;
            
            bool isActive = true;
            if (existing.endDate != null) {
              try {
                final end = DateTime.parse(existing.endDate!);
                isActive = end.isAfter(DateTime.now());
              } catch (_) {
                isActive = true;
              }
            }
            return isNameMatch && isActive;
          });
        }).toList();

        final allSelected = _selected.every((val) => val);

        return Container(
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: widget.border, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Xác nhận thêm vào Tủ thuốc',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (int i = 0; i < _selected.length; i++) {
                          _selected[i] = !allSelected;
                        }
                      });
                    },
                    child: Text(
                      allSelected ? 'Bỏ chọn hết' : 'Chọn tất cả',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.kPrimaryDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.meds.length,
                  itemBuilder: (context, index) {
                    final med = widget.meds[index];
                    final isDup = isDuplicateList[index];

                    return Opacity(
                      opacity: isDup && !_selected[index] ? 0.65 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0D1520) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDup ? const Color(0xFFF59E0B).withOpacity(0.4) : widget.border,
                            width: isDup ? 1.5 : 1.0,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _selected[index],
                          onChanged: _isSaving
                              ? null
                              : (val) {
                                  setState(() {
                                    _selected[index] = val ?? false;
                                  });
                                },
                          activeColor: AppTheme.kPrimaryDark,
                          title: Text(
                            med.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${med.dosage.isNotEmpty ? "${med.dosage}  •  " : ""}'
                                '${med.frequency.isNotEmpty ? "${med.frequency}  •  " : ""}'
                                '${med.durationDays != null ? "${med.durationDays} ngày" : ""}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: widget.textSecondary,
                                ),
                              ),
                              if (isDup) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.alertTriangle,
                                      size: 12,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Đã có trong Tủ thuốc (đang dùng)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFFD97706),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          dense: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selected.every((val) => !val) || _isSaving
                      ? null
                      : _importMedicines,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kPrimaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Thêm ${_selected.where((v) => v).length} thuốc vào tủ thuốc',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

