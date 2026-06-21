import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';

class MedicineFormScreen extends StatefulWidget {
  final MedicineModel? medicine;

  const MedicineFormScreen({super.key, this.medicine});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late TextEditingController _instructionController;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name);
    _dosageController = TextEditingController(text: widget.medicine?.dosage);
    _frequencyController = TextEditingController(
      text: widget.medicine?.frequency,
    );
    _instructionController = TextEditingController(
      text: widget.medicine?.instruction,
    );
    if (widget.medicine != null) {
      _startDate = DateTime.parse(widget.medicine!.startDate);
      if (widget.medicine!.endDate != null) {
        _endDate = DateTime.parse(widget.medicine!.endDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(
          widget.medicine == null ? 'Thêm thuốc mới' : 'Chỉnh sửa thuốc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<MedicineBloc, MedicineState>(
        listener: (context, state) {
          if (state is MedicineActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.pop(context);
          }
          if (state is MedicineError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  _nameController,
                  'Tên thuốc',
                  LucideIcons.pill,
                  validator: (v) =>
                      v!.isEmpty ? 'Vui lòng nhập tên thuốc' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _dosageController,
                        'Liều lượng',
                        LucideIcons.activity,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        _frequencyController,
                        'Tần suất',
                        LucideIcons.clock,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  _instructionController,
                  'Hướng dẫn sử dụng',
                  LucideIcons.alignLeft,
                  maxLines: 3,
                ),
                SizedBox(height: 24),
                _buildDateSection(),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF14B8A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lưu thông tin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182030) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      children: [
        _buildDatePicker(
          'Ngày bắt đầu',
          _startDate,
          (date) => setState(() => _startDate = date!),
        ),
        SizedBox(height: 16),
        _buildDatePicker(
          'Ngày kết thúc (không bắt buộc)',
          _endDate,
          (date) => setState(() => _endDate = date),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    Function(DateTime?) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selected != null) onSelected(selected);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF182030) : Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Chọn ngày',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = <String, dynamic>{
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'frequency': _frequencyController.text,
        'instruction': _instructionController.text,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        if (widget.medicine?.drugCandidateId != null)
          'drugCandidateId': widget.medicine!.drugCandidateId,
        if (widget.medicine?.recommendationSessionId != null)
          'recommendationSessionId': widget.medicine!.recommendationSessionId,
      };

      final newDrugName = _nameController.text.trim().toLowerCase();
      final blocState = context.read<MedicineBloc>().state;
      final existingMeds = <String>[];
      if (blocState is MedicinesLoaded) {
        for (final m in blocState.medicines) {
          if (widget.medicine != null && m.id == widget.medicine!.id) continue;
          existingMeds.add(m.name.trim().toLowerCase());
        }
      }

      final knownInteractions = {
        'warfarin': ['aspirin', 'ibuprofen', 'paracetamol'],
        'aspirin': ['warfarin', 'ibuprofen', 'corticosteroid'],
        'metformin': ['rượu', 'corticosteroid'],
        'digoxin': ['thuốc lợi tiểu', 'corticosteroid'],
        'ibuprofen': ['aspirin', 'warfarin', 'corticosteroid']
      };

      final warnings = <String>[];
      for (final entry in knownInteractions.entries) {
        final drugKey = entry.key;
        if (newDrugName.contains(drugKey)) {
          for (final otherMed in existingMeds) {
            for (final dangerousPartner in entry.value) {
              if (otherMed.contains(dangerousPartner)) {
                warnings.add(
                  'Tương tác nguy hiểm giữa ${widget.medicine != null ? 'thuốc này' : _nameController.text} và "$otherMed" ($drugKey tương tác với $dangerousPartner).'
                );
              }
            }
          }
        }
      }

      if (warnings.isNotEmpty) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                const Text('Cảnh báo lâm sàng'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hệ thống phát hiện tương tác nguy hiểm với thuốc đang dùng:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(w, style: const TextStyle(fontSize: 12, height: 1.4)),
                  )),
                  const SizedBox(height: 12),
                  const Text('Bạn có chắc chắn muốn tiếp tục lưu thuốc này không?'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Quay lại sửa'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  _executeSubmit(data);
                },
                child: const Text('Vẫn lưu thuốc'),
              ),
            ],
          ),
        );
      } else {
        _executeSubmit(data);
      }
    }
  }

  void _executeSubmit(Map<String, dynamic> data) {
    if (widget.medicine == null || widget.medicine!.id.isEmpty) {
      context.read<MedicineBloc>().add(MedicineCreateRequested(data));
    } else {
      context.read<MedicineBloc>().add(
        MedicineUpdateRequested(widget.medicine!.id, data),
      );
    }
  }
}

