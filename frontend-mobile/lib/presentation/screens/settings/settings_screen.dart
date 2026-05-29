import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/services/biometric_service.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/sheets/change_password_sheet.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/sheets/recovery_key_sheet.dart';

// ─── Color tokens ─────────────────────────────
const _kTextMuted = Color(0xFF94A3B8);
// Staff-portal dark color tokens (match AdminColors without importing)
const _kStaffBg      = Color(0xFF080E1A);
const _kStaffSurface = Color(0xFF0F1829);
const _kStaffBorder  = Color(0xFF1E2D42);
const _kStaffMuted   = Color(0xFF445566);
const _kStaffText    = Color(0xFFEFF3FF);
const _kStaffSub     = Color(0xFF7A90B0);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Biometric quick-login state ──────────────────────────────────────
  final _storage = SecureStorageService();
  final _bio     = BiometricService();
  bool _bioEnabled   = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadBioState();
  }

  Future<void> _loadBioState() async {
    final enabled   = await _storage.isBiometricLoginEnabled();
    final available = await _bio.isAvailable();
    final enrolled  = await _bio.isBiometricEnrolled();
    if (!mounted) return;
    setState(() {
      _bioEnabled   = enabled;
      _bioAvailable = available && enrolled;
    });
  }

  Future<void> _toggleDark() async {
    await AppThemeNotifier.toggle();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Determine role for colour-theming
    final authState = context.read<AuthBloc>().state;
    final role = authState is Authenticated
        ? (authState.user.role?.toUpperCase() ?? 'PATIENT')
        : 'PATIENT';
    final isStaff = role == 'DOCTOR' || role == 'ADMIN';

    // Header gradient — staff gets dark navy doctor/admin theme
    final headerGradient = isStaff
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C4A42), Color(0xFF080E1A)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.kPrimaryDark, Color(0xFF134E4A)],
          );

    return Scaffold(
      backgroundColor: isStaff
          ? _kStaffBg
          : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(gradient: headerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (context.canPop())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(100),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'settings.title'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileHeaderCard(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tài khoản & Bảo mật ─────────────────────────
            _buildSection(context, 'settings.account_security'.tr(), [
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.key,
                label: 'settings.change_password'.tr(),
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () => _showChangePassword(context),
              ),
              _BiometricToggleItem(
                isStaff:   isStaff,
                enabled:   _bioEnabled,
                available: _bioAvailable,
                onToggle:  (val) => _handleBiometricToggle(context, val),
              ),
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.rotateCcw,
                label: 'settings.recovery_key'.tr(),
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () => _showRecoveryKey(context),
              ),
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.shield,
                label: 'settings.sessions'.tr(),
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                trailing: _badge('settings.sessions_device'.tr(), const Color(0xFF3B82F6)),
                onTap: () => _showSessions(context),
              ),
            ], isStaff: isStaff),

            const SizedBox(height: 12),

            _buildSection(context, 'settings.application'.tr(), [
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.bell,
                label: 'settings.notifications'.tr(),
                iconBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                onTap: () => _showNotifications(context),
              ),
              _buildItem(
                isStaff: isStaff,
                icon: AppThemeNotifier.isDark ? LucideIcons.sun : LucideIcons.moon,
                label: AppThemeNotifier.isDark
                    ? 'settings.dark_mode_to_light'.tr()
                    : 'settings.dark_mode_to_dark'.tr(),
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                onTap: _toggleDark,
                trailing: _toggleSwitch(AppThemeNotifier.isDark),
              ),
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.globe,
                label: 'settings.language'.tr(),
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                onTap: () => _showLanguage(context),
                trailing: Text(
                  'settings.language_value'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isStaff ? _kStaffSub : _kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.smartphone,
                label: 'settings.mobile_app'.tr(),
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                onTap: () => _showMobileApp(context),
              ),
            ], isStaff: isStaff),

            const SizedBox(height: 12),

            _buildSection(context, 'settings.about'.tr(), [
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.info,
                label: 'settings.version'.tr(),
                iconBg: AppTheme.kPrimaryLight,
                iconColor: const Color(0xFF14B8A6),
                trailing: _badge('settings.badge_latest'.tr(), const Color(0xFF16A34A)),
              ),
              _buildItem(
                isStaff: isStaff,
                icon: LucideIcons.lifeBuoy,
                label: 'settings.support'.tr(),
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
                onTap: () => _showSupport(context),
              ),
            ], isStaff: isStaff),

            const SizedBox(height: 12),

            // ── Đăng xuất ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: isStaff ? _kStaffSurface : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showLogoutDialog(context),
                  splashColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isStaff
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: isStaff
                                ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25))
                                : null,
                          ),
                          child: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'settings.logout'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DIALOGS & BOTTOM SHEETS
  // ─────────────────────────────────────────────────────────

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  /// Toggle bật/tắt Biometric Quick Unlock.
  Future<void> _handleBiometricToggle(BuildContext context, bool enable) async {
    if (enable) {
      // Bật: kiểm tra hardware rồi lưu credentials nếu đã có
      final creds = await _storage.getQuickLoginCredentials();
      if (creds != null) {
        await _storage.setBiometricLoginEnabled(true);
        setState(() => _bioEnabled = true);
      } else {
        // Không có credentials → hiện thông báo cần đăng nhập lại
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng đăng xuất và đăng nhập lại để bật tính năng này.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } else {
      // Tắt: xác nhận rồi xóa credentials
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tắt đăng nhập bằng vân tay?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: const Text(
            'Bạn sẽ cần nhập mật khẩu mỗi lần đăng nhập.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tắt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _storage.clearQuickLoginCredentials();
        setState(() => _bioEnabled = false);
      }
    }
  }

  void _showRecoveryKey(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecoveryKeySheet(),
    );
  }

  void _showSessions(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF182030)
        : const Color(0xFFF8FAFC);
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3A50)
        : const Color(0xFFE2E8F0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('settings.sessions'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.phone_android, color: AppTheme.kPrimaryDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('settings.sessions_this_device'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('settings.sessions_active'.tr(), style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                    child: Text('settings.sessions_current'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('settings.close'.tr()),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationSheet(),
    );
  }

  void _showLanguage(BuildContext context) {
    // Đọc locale hiện tại từ context parameter (an toàn vì gọi từ build())
    String selected = context.locale.languageCode;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final langs = [
            {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
            {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
          ];
          return Container(
            decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3A50) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ))),
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: Text('language_sheet.title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                ...langs.map((l) => Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setModalState(() => selected = l['code']!),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected == l['code']
                            ? AppTheme.kPrimaryDark.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF182030) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected == l['code'] ? AppTheme.kPrimaryDark : (isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0))),
                      ),
                      child: Row(children: [
                        Text(l['flag']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l['name']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (selected == l['code']) const Icon(Icons.check_circle, color: AppTheme.kPrimaryDark, size: 20),
                      ]),
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('locale', selected);
                      if (ctx.mounted) {
                        await ctx.setLocale(Locale(selected));
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kPrimaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('language_sheet.apply'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMobileApp(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A3A50) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ))),
            const SizedBox(height: 20),
            Text('settings.mobile_app'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('settings.mobile_app_body'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 8),
            Text('settings.mobile_app_version'.tr(), style: const TextStyle(color: AppTheme.kPrimaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('settings.close'.tr()))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSupport(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? const Color(0xFF2A3A50) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('settings.support'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    _faqItem('support.faq1_q'.tr(), 'support.faq1_a'.tr()),
                    _faqItem('support.faq2_q'.tr(), 'support.faq2_a'.tr()),
                    _faqItem('support.faq3_q'.tr(), 'support.faq3_a'.tr()),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('support.contact'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _contactItem(ctx, Icons.email_outlined, 'support@medichain.vn', 'support.email_label'.tr()),
                    _contactItem(ctx, Icons.discord, 'discord.gg/medichain', 'support.discord_label'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String q, String a) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [Text(a, style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13))],
    );
  }

  Widget _contactItem(BuildContext context, IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182030) : const Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0))
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.kPrimaryDark),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(label, style: const TextStyle(fontSize: 11, color: _kTextMuted)),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD HELPERS
  // ─────────────────────────────────────────────────────────

  Widget _buildSection(BuildContext context, String title, List<Widget> items, {bool isStaff = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isStaff ? _kStaffMuted : _kTextMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isStaff ? _kStaffSurface : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isStaff ? Border.all(color: _kStaffBorder) : null,
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    bool isStaff = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final labelColor = isStaff
            ? _kStaffText
            : Theme.of(context).textTheme.bodyLarge?.color;
        final iconGrey = isStaff
            ? _kStaffSub
            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
        final chevronColor = isStaff
            ? _kStaffMuted
            : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1));
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: isStaff
                ? Colors.white.withValues(alpha: 0.04)
                : AppTheme.kPrimary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: iconGrey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                  trailing ?? Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: chevronColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _toggleSwitch(bool value) {
    return Container(
      width: 44, height: 24,
      decoration: BoxDecoration(color: value ? AppTheme.kPrimaryDark : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(100)),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20, height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────
// NOTIFICATION BOTTOM SHEET
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
// BIOMETRIC TOGGLE ITEM
// Row dùng trong Settings → Tài khoản & Bảo mật
// ─────────────────────────────────────────────────────────
class _BiometricToggleItem extends StatelessWidget {
  final bool isStaff;
  final bool enabled;
  final bool available;
  final ValueChanged<bool> onToggle;

  const _BiometricToggleItem({
    required this.isStaff,
    required this.enabled,
    required this.available,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor   = isStaff ? _kStaffText  : Theme.of(context).textTheme.bodyLarge?.color;
    final subColor     = isStaff ? _kStaffMuted  : const Color(0xFF94A3B8);
    final iconGrey     = isStaff ? _kStaffSub    : const Color(0xFF94A3B8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: available ? () => onToggle(!enabled) : null,
        splashColor: isStaff
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.kPrimary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(LucideIcons.fingerprint, size: 22, color: iconGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng nhập bằng vân tay',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    available
                        ? (enabled ? 'Đang bật · Chạm để tắt' : 'Đang tắt · Chạm để bật')
                        : 'Thiết bị chưa đăng ký vân tay',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: enabled ? const Color(0xFF10B981) : subColor,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle visual
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46, height: 26,
              decoration: BoxDecoration(
                color: !available
                    ? const Color(0xFFCBD5E1)
                    : (enabled ? AppTheme.kPrimary : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(100),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// BIOMETRIC STATUS SHEET (kept for reference, not used in main flow)
// ─────────────────────────────────────────────────────────
class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet();

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  bool _enabled = false;
  int _hour = 8, _minute = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _enabled = prefs.getBool('notifEnabled') ?? false;
        _hour = prefs.getInt('notifHour') ?? 8;
        _minute = prefs.getInt('notifMinute') ?? 0;
      });
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifEnabled', _enabled);
    await prefs.setInt('notifHour', _hour);
    await prefs.setInt('notifMinute', _minute);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext ctx) {
    final surfaceColor = Theme.of(ctx).colorScheme.surface;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3A50) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ))),
        const SizedBox(height: 16),
        Text('settings.notifications'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('settings.notif_subtitle'.tr(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('settings.notif_enable'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('settings.notif_show_bar'.tr(), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ])),
          Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v), activeThumbColor: AppTheme.kPrimaryDark),
        ]),
        if (_enabled) ...[
          const Divider(height: 24),
          Text('settings.notif_daily_hour'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              initialValue: _hour,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
              onChanged: (v) => setState(() => _hour = v!),
            )),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Expanded(child: DropdownButtonFormField<int>(
              initialValue: _minute,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: [0, 15, 30, 45].map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))).toList(),
              onChanged: (v) => setState(() => _minute = v!),
            )),
          ]),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('settings.cancel'.tr()))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimaryDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('settings.save'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PROFILE HEADER CARD
// ─────────────────────────────────────────────────────────
class _ProfileHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String name = 'Người dùng';
        String email = '';
        String role = 'PATIENT';
        if (state is Authenticated) {
          name = state.user.name ?? name;
          email = state.user.email ?? '';
          role = state.user.role?.toUpperCase() ?? 'PATIENT';
        }
        final isStaff = role == 'DOCTOR' || role == 'ADMIN';

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isStaff ? null : () => context.push('/profile'),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  if (isStaff)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        role == 'DOCTOR' ? 'BÁC SĨ' : 'ADMIN',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    Icon(LucideIcons.chevronRight, color: Colors.white.withOpacity(0.6), size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// LOGOUT DIALOG
// ─────────────────────────────────────────────────────────
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      title: Row(
        children: [
          const Expanded(child: Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
      content: const Text('Bạn có chắc chắn muốn thoát không?', style: TextStyle(color: Color(0xFF64748B))),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Builder(
              builder: (btnCtx) => ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  btnCtx.read<AuthBloc>().add(LogoutRequested());
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

