import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/profile/profile_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initControllers(ProfileModel profile) {
    _bloodTypeController.text = profile.bloodType ?? '';
    _allergiesController.text = profile.allergies ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _addressController.text = profile.address ?? '';
    _phoneController.text = profile.phone ?? '';
  }

  void _handleSave(BuildContext context) {
    final profile = ProfileModel(
      bloodType: _bloodTypeController.text,
      allergies: _allergiesController.text,
      weight: double.tryParse(_weightController.text),
      height: double.tryParse(_heightController.text),
      phone: _phoneController.text,
      address: _addressController.text,
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
            style: TextStyle(fontWeight: FontWeight.bold),
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
                        backgroundColor: Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'profile.save'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                return SizedBox();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) _initControllers(state.profile);
            if (state is ProfileUpdateSuccess) {
              _initControllers(state.profile);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('profile.update_success'.tr()),
                  ]),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return Center(child: CircularProgressIndicator());
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
                      iconColor: Color(0xFF14B8A6),
                      iconBg: Color(0xFFF0FDFA),
                      title: 'profile.biometric_info'.tr(),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _bloodTypeController,
                                'profile.blood_type'.tr(),
                                icon: LucideIcons.droplets,
                              ),
                            ),
                            SizedBox(width: 16),
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
                        SizedBox(height: 14),
                        _field(
                          _heightController,
                          'profile.height'.tr(),
                          icon: LucideIcons.ruler,
                          isNumber: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSection(
                      icon: LucideIcons.alertCircle,
                      iconColor: Color(0xFFEA580C),
                      iconBg: Color(0xFFFFF7ED),
                      title: 'profile.medical_allergies'.tr(),
                      children: [
                        _field(
                          _allergiesController,
                          'profile.allergies'.tr(),
                          icon: LucideIcons.alertCircle,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSection(
                      icon: LucideIcons.phone,
                      iconColor: Color(0xFF16A34A),
                      iconBg: Color(0xFFF0FDF4),
                      title: 'profile.contact'.tr(),
                      children: [
                        _field(_phoneController, 'profile.phone'.tr(), icon: LucideIcons.phone),
                        SizedBox(height: 14),
                        _field(_addressController, 'profile.address'.tr(), icon: LucideIcons.mapPin, maxLines: 2),
                      ],
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
                SizedBox(width: 12),
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
          Divider(height: 1, indent: 16, endIndent: 16),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
}
