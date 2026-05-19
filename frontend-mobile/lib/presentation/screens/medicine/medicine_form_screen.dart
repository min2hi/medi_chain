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
          widget.medicine == null ? 'ThÃªm thuá»‘c má»›i' : 'Chá»‰nh sá»­a thuá»‘c',
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
                  'TÃªn thuá»‘c',
                  LucideIcons.pill,
                  validator: (v) =>
                      v!.isEmpty ? 'Vui lÃ²ng nháº­p tÃªn thuá»‘c' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _dosageController,
                        'Liá»u lÆ°á»£ng',
                        LucideIcons.activity,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        _frequencyController,
                        'Táº§n suáº¥t',
                        LucideIcons.clock,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  _instructionController,
                  'HÆ°á»›ng dáº«n sá»­ dá»¥ng',
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
                      'LÆ°u thÃ´ng tin',
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

  Widget _buildDateSection() {
    return Column(
      children: [
        _buildDatePicker(
          'NgÃ y báº¯t Ä‘áº§u',
          _startDate,
          (date) => setState(() => _startDate = date!),
        ),
        SizedBox(height: 16),
        _buildDatePicker(
          'NgÃ y káº¿t thÃºc (khÃ´ng báº¯t buá»™c)',
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
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Chá»n ngÃ y',
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
      final data = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'frequency': _frequencyController.text,
        'instruction': _instructionController.text,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
      };

      if (widget.medicine == null) {
        context.read<MedicineBloc>().add(MedicineCreateRequested(data));
      } else {
        context.read<MedicineBloc>().add(
          MedicineUpdateRequested(widget.medicine!.id, data),
        );
      }
    }
  }
}
