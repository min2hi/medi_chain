import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/profile/profile_bloc.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _chronicConditionsController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String? _gender;
  bool _isPregnant = false;
  bool _isBreastfeeding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _chronicConditionsController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _initControllers(ProfileModel profile) {
    _nameController.text = profile.name ?? '';
    _bloodTypeController.text = profile.bloodType ?? '';
    _allergiesController.text = profile.allergies ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _addressController.text = profile.address ?? '';
    _phoneController.text = profile.phone ?? '';
    _chronicConditionsController.text = profile.chronicConditions ?? '';
    _isPregnant = profile.isPregnant ?? false;
    _isBreastfeeding = profile.isBreastfeeding ?? false;

    // Normalize gender: "Nam", "Nữ", "Khác"
    final dbGender = profile.gender?.trim().toLowerCase() ?? '';
    if (dbGender == 'nam' || dbGender == 'male') {
      _gender = 'Nam';
      _isPregnant = false;
      _isBreastfeeding = false;
    } else if (dbGender == 'nữ' || dbGender == 'female' || dbGender == 'nu') {
      _gender = 'Nữ';
    } else if (dbGender.isNotEmpty) {
      _gender = 'Khác';
    } else {
      _gender = null;
    }

    if (profile.birthday != null && profile.birthday!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(profile.birthday!);
        _birthdayController.text = parsed.toIso8601String().split('T')[0];
      } catch (_) {
        _birthdayController.text = profile.birthday!;
      }
    } else {
      _birthdayController.text = '';
    }
  }

  void _handleSave(BuildContext context) {
    bool finalIsPregnant = _isPregnant;
    bool finalIsBreastfeeding = _isBreastfeeding;
    if (_gender == 'Nam') {
      finalIsPregnant = false;
      finalIsBreastfeeding = false;
    }

    final profile = ProfileModel(
      name: _nameController.text,
      bloodType: _bloodTypeController.text,
      allergies: _allergiesController.text,
      weight: double.tryParse(_weightController.text),
      height: double.tryParse(_heightController.text),
      phone: _phoneController.text,
      address: _addressController.text,
      gender: _gender,
      birthday: _birthdayController.text.isNotEmpty ? _birthdayController.text : null,
      isPregnant: finalIsPregnant,
      isBreastfeeding: finalIsBreastfeeding,
      chronicConditions: _chronicConditionsController.text,
    );
    context.read<ProfileBloc>().add(ProfileUpdateRequested(profile));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileBloc>()..add(ProfileFetchRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'profile.title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoaded || state is ProfileUpdateSuccess) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: TextButton(
                      onPressed: () => _handleSave(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'profile.save'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              _initControllers(state.profile);
              context.read<AuthBloc>().add(UserNameUpdated(state.profile.name ?? ''));
            }
            if (state is ProfileUpdateSuccess) {
              _initControllers(state.profile);
              context.read<AuthBloc>().add(UserNameUpdated(state.profile.name ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text('profile.update_success'.tr()),
                  ]),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              _runRetrospectiveSafetyScan(context, state.profile);
            }
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      icon: LucideIcons.userCircle,
                      iconColor: const Color(0xFF14B8A6),
                      iconBg: const Color(0xFFF0FDFA),
                      title: 'profile.biometric_info'.tr(),
                      children: [
                        _field(
                          _nameController,
                          'Họ và tên',
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _bloodTypeController,
                                'profile.blood_type'.tr(),
                                icon: LucideIcons.droplets,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _field(
                                _weightController,
                                'profile.weight'.tr(),
                                icon: LucideIcons.scale,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _heightController,
                                'profile.height'.tr(),
                                icon: LucideIcons.ruler,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _genderDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _birthdayField(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      icon: LucideIcons.alertCircle,
                      iconColor: const Color(0xFFEA580C),
                      iconBg: const Color(0xFFFFF7ED),
                      title: 'profile.medical_allergies'.tr(),
                      children: [
                        _field(
                          _allergiesController,
                          'profile.allergies'.tr(),
                          icon: LucideIcons.alertCircle,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          _chronicConditionsController,
                          'Bệnh nền / Bệnh mãn tính',
                          icon: LucideIcons.activity,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildPregnancyNursingSwitches(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      icon: LucideIcons.phone,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFF0FDF4),
                      title: 'profile.contact'.tr(),
                      children: [
                        _field(_phoneController, 'profile.phone'.tr(), icon: LucideIcons.phone),
                        const SizedBox(height: 14),
                        _field(_addressController, 'profile.address'.tr(), icon: LucideIcons.mapPin, maxLines: 2),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _gender,
          hint: const Text('Chọn', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
          onChanged: (val) {
            setState(() {
              _gender = val;
              if (val == 'Nam') {
                _isPregnant = false;
                _isBreastfeeding = false;
              }
            });
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.user, size: 16, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182030) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0)),
            ),
          ),
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          items: const [
            DropdownMenuItem(value: 'Nam', child: Text('Nam')),
            DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
            DropdownMenuItem(value: 'Khác', child: Text('Khác')),
          ],
        ),
      ],
    );
  }

  Widget _birthdayField() {
    int? birthYear;
    int? age;
    if (_birthdayController.text.isNotEmpty) {
      try {
        final parsed = DateTime.parse(_birthdayController.text);
        birthYear = parsed.year;
        final today = DateTime.now();
        age = today.year - parsed.year;
        if (today.month < parsed.month || (today.month == parsed.month && today.day < parsed.day)) {
          age--;
        }
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 20));
            if (_birthdayController.text.isNotEmpty) {
              try {
                initial = DateTime.parse(_birthdayController.text);
              } catch (_) {}
            }
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _birthdayController.text = picked.toIso8601String().split('T')[0];
              });
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              controller: _birthdayController,
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182030) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
        ),
        if (birthYear != null && age != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 13,
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Năm sinh: $birthYear  •  Tuổi hiện tại: $age tuổi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPregnancyNursingSwitches() {
    final bool isMale = _gender == 'Nam';
    const Color activeCol = Color(0xFF14B8A6);
    
    return Column(
      children: [
        SwitchListTile(
          value: isMale ? false : _isPregnant,
          onChanged: isMale ? null : (val) {
            setState(() {
              _isPregnant = val;
            });
          },
          title: Text(
            'Đang mang thai',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMale ? const Color(0xFFCBD5E1) : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: isMale ? const Text('Không khả dụng cho Nam', style: TextStyle(fontSize: 11)) : null,
          secondary: Icon(
            LucideIcons.baby, 
            color: isMale ? const Color(0xFFCBD5E1) : activeCol,
          ),
          activeColor: activeCol,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: isMale ? false : _isBreastfeeding,
          onChanged: isMale ? null : (val) {
            setState(() {
              _isBreastfeeding = val;
            });
          },
          title: Text(
            'Đang cho con bú',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMale ? const Color(0xFFCBD5E1) : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: isMale ? const Text('Không khả dụng cho Nam', style: TextStyle(fontSize: 11)) : null,
          secondary: Icon(
            LucideIcons.heartHandshake, 
            color: isMale ? const Color(0xFFCBD5E1) : activeCol,
          ),
          activeColor: activeCol,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182030) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runRetrospectiveSafetyScan(BuildContext context, ProfileModel profile) async {
    try {
      final response = await getIt<MedicalRepository>().getMedicines();
      if (!response.success || response.data == null || response.data!.isEmpty) return;

      final medicines = response.data!;
      final warnings = <String>[];

      // 1. Quét dị ứng (Allergies)
      if (profile.allergies != null && profile.allergies!.trim().isNotEmpty) {
        final allergyTerms = profile.allergies!
            .toLowerCase()
            .split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.length > 2)
            .toList();

        for (final med in medicines) {
          final medName = med.name.toLowerCase();
          for (final term in allergyTerms) {
            if (medName.contains(term) || term.contains(medName)) {
              warnings.add(
                '• Thuốc "${med.name}" chứa hoạt chất trùng khớp hoặc có liên quan đến thành phần dị ứng của bạn ("$term").'
              );
            }
          }
        }
      }

      // 2. Quét chống chỉ định thai kỳ & cho con bú (Pregnancy & Lactation Contraindications)
      final contraindMeds = <String, List<String>>{
        if (profile.isPregnant == true) ...{
          'ibuprofen': ['Chống chỉ định trong thai kỳ (đặc biệt là 3 tháng cuối) do nguy cơ đóng sớm ống động mạch của thai nhi.'],
          'aspirin': ['Tránh dùng trong thai kỳ trừ khi có chỉ định đặc biệt từ bác sĩ sản khoa.'],
          'tetracycline': ['Có thể gây đổi màu răng vĩnh viễn ở thai nhi và ảnh hưởng xương.'],
          'corticosteroid': ['Cần thận trọng và hạn chế sử dụng trong thai kỳ.'],
        },
        if (profile.isBreastfeeding == true) ...{
          'aspirin': ['Có thể bài tiết qua sữa mẹ và gây hội chứng Reye ở trẻ sơ sinh.'],
          'tetracycline': ['Có thể ảnh hưởng đến men răng và xương của trẻ bú mẹ.'],
        }
      };

      for (final med in medicines) {
        final medName = med.name.toLowerCase();
        contraindMeds.forEach((drugKey, reasons) {
          if (medName.contains(drugKey)) {
            for (final reason in reasons) {
              warnings.add(
                '• Thuốc "${med.name}" không khuyến nghị dùng cho phụ nữ ${profile.isPregnant == true ? 'mang thai' : 'cho con bú'}: $reason'
              );
            }
          }
        });
      }

      if (warnings.isNotEmpty && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                const Text('Cảnh báo an toàn y tế'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hệ thống phát hiện một số thuốc trong tủ thuốc hiện tại có thể KHÔNG AN TOÀN với trạng thái sức khỏe mới cập nhật:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ...warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(w, style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.red)),
                  )),
                  const SizedBox(height: 12),
                  const Text(
                    'Vui lòng tham khảo ý kiến bác sĩ hoặc ngưng sử dụng để tránh tác dụng phụ nguy hại.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Tôi đã hiểu'),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }
}

