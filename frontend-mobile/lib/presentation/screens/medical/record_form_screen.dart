import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/logic/medical/medical_bloc.dart';

class MedicalRecordFormScreen extends StatefulWidget {
  final MedicalRecordModel? record;

  const MedicalRecordFormScreen({super.key, this.record});

  @override
  State<MedicalRecordFormScreen> createState() =>
      _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends State<MedicalRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _hospitalController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _contentController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record?.title);
    _hospitalController = TextEditingController(text: widget.record?.hospital);
    _diagnosisController = TextEditingController(
      text: widget.record?.diagnosis,
    );
    _treatmentController = TextEditingController(
      text: widget.record?.treatment,
    );
    _contentController = TextEditingController(text: widget.record?.content);
    if (widget.record != null) {
      _selectedDate = DateTime.parse(widget.record!.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(
          widget.record == null ? 'Thêm hồ sơ mới' : 'Chỉnh sửa hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<MedicalBloc, MedicalState>(
        listener: (context, state) {
          if (state is MedicalActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.pop(context);
          }
          if (state is MedicalError) {
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
                  _titleController,
                  'Tiêu đề hồ sơ',
                  LucideIcons.fileText,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  _hospitalController,
                  'Bệnh viện / Cơ sở y tế',
                  LucideIcons.building2,
                ),
                SizedBox(height: 16),
                _buildDatePicker(),
                SizedBox(height: 24),
                _buildTextField(
                  _diagnosisController,
                  'Chẩn đoán',
                  LucideIcons.stethoscope,
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  _treatmentController,
                  'Hướng điều trị',
                  LucideIcons.activity,
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  _contentController,
                  'Ghi chú chi tiết',
                  LucideIcons.alignLeft,
                  maxLines: 4,
                ),
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
                      'Lưu hồ sơ',
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
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày khám',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1E293B) : Color(0xFFF8FAFC),
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
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
      final data = {
        'title': _titleController.text,
        'hospital': _hospitalController.text,
        'date': _selectedDate.toIso8601String(),
        'diagnosis': _diagnosisController.text,
        'treatment': _treatmentController.text,
        'content': _contentController.text,
      };

      if (widget.record == null) {
        context.read<MedicalBloc>().add(RecordCreateRequested(data));
      } else {
        context.read<MedicalBloc>().add(
          RecordUpdateRequested(widget.record!.id, data),
        );
      }
    }
  }
}
