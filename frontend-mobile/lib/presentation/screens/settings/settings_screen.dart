import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/sheets/change_password_sheet.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/sheets/recovery_key_sheet.dart';

// ─── Color tokens ─────────────────────────────
const _kPrimary = Color(0xFF0D9488);
const _kPrimaryLight = Color(0xFFF0FDFA);
const _kTextMuted = Color(0xFF94A3B8);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = false;
  String _locale = 'vi';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isDark = prefs.getBool('isDark') ?? false;
      // Ưu tiên locale thực tế từ EasyLocalization (source of truth)
      _locale = context.locale.languageCode;
    });
  }

  Future<void> _toggleDark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDark = !_isDark);
    await prefs.setBool('isDark', _isDark);
    // TODO: apply ThemeMode via global state when ThemeBloc is added
  }


  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is Authenticated &&
        authState.user.role?.toUpperCase() == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Gradient header ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D9488), Color(0xFF134E4A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cài đặt',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileHeaderCard(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tài khoản & Bảo mật ─────────────────────────
            _buildSection('Tài khoản & Bảo mật', [
              _buildItem(
                icon: LucideIcons.key,
                label: 'Đổi mật khẩu',
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () => _showChangePassword(context),
              ),
              _buildItem(
                icon: LucideIcons.fingerprint,
                label: 'Biometric / Vân tay',
                iconBg: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF7C3AED),
                onTap: () => _showBiometricSheet(context),
                trailing: _badge('Mới', const Color(0xFF10B981)),
              ),
              _buildItem(
                icon: LucideIcons.rotateCcw,
                label: 'Sao lưu Recovery Key',
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () => _showRecoveryKey(context),
              ),
              _buildItem(
                icon: LucideIcons.shield,
                label: 'Phiên đăng nhập',
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                trailing: _badge('1 thiết bị', const Color(0xFF3B82F6)),
                onTap: () => _showSessions(context),
              ),
            ]),

            const SizedBox(height: 12),

            _buildSection('Ứng dụng', [
              _buildItem(
                icon: LucideIcons.bell,
                label: 'Thông báo nhắc nhở',
                iconBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                onTap: () => _showNotifications(context),
              ),
              _buildItem(
                icon: _isDark ? LucideIcons.sun : LucideIcons.moon,
                label: _isDark ? 'Chuyển sang Sáng' : 'Chuyển sang Tối',
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                onTap: _toggleDark,
                trailing: _toggleSwitch(_isDark),
              ),
              _buildItem(
                icon: LucideIcons.globe,
                label: 'settings.language'.tr(),
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                onTap: () => _showLanguage(context),
                trailing: Text(
                  'settings.language_value'.tr(),
                  style: const TextStyle(fontSize: 13, color: _kTextMuted, fontWeight: FontWeight.w500),
                ),
              ),
              _buildItem(
                icon: LucideIcons.smartphone,
                label: 'Ứng dụng di động',
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                onTap: () => _showMobileApp(context),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Admin Portal (chỉ hiện khi role == ADMIN) ────
            if (isAdmin) ...[
              _buildSection('settings.admin_portal'.tr(), [
                _buildItem(
                  icon: LucideIcons.layoutDashboard,
                  label: 'Admin Portal',
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  trailing: _badge('ADMIN', const Color(0xFFD97706)),
                  onTap: () => context.push('/admin'),
                ),
              ]),
              const SizedBox(height: 12),
            ],

            _buildSection('Về MediChain', [
              _buildItem(
                icon: LucideIcons.info,
                label: 'Phiên bản 1.0.0',
                iconBg: _kPrimaryLight,
                iconColor: const Color(0xFF14B8A6),
                trailing: _badge('Mới nhất', const Color(0xFF16A34A)),
              ),
              _buildItem(
                icon: LucideIcons.lifeBuoy,
                label: 'Hỗ trợ & Hướng dẫn',
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
                onTap: () => _showSupport(context),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Đăng xuất ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showLogoutDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
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

  void _showBiometricSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.fingerprint, size: 56, color: Color(0xFF7C3AED)),
            const SizedBox(height: 16),
            const Text('Biometric / Vân tay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tính năng đăng nhập bằng vân tay sẽ được kích hoạt trong phiên bản tiếp theo.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Phiên đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.phone_android, color: _kPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Điện thoại này', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Đang hoạt động', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                    child: const Text('Hiện tại', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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
                child: const Text('Đóng'),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          String selected = _locale;
          final langs = [
            {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
            {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
          ];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Ngôn ngữ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                ...langs.map((l) => GestureDetector(
                  onTap: () => setModalState(() => selected = l['code']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected == l['code'] ? _kPrimaryLight : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected == l['code'] ? _kPrimary : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(children: [
                      Text(l['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l['name']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (selected == l['code']) const Icon(Icons.check_circle, color: _kPrimary, size: 20),
                    ]),
                  ),
                )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('locale', selected);
                      // Dùng ctx (BuildContext của modal) để setLocale,
                      // đảm bảo EasyLocalization được tìm thấy trong widget tree
                      if (ctx.mounted) {
                        await ctx.setLocale(Locale(selected));
                      }
                      // Cập nhật state của SettingsScreen sau khi modal đóng
                      if (context.mounted) {
                        setState(() => _locale = selected);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Ứng dụng di động', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Bạn đang dùng ứng dụng MediChain Mobile! 🎉', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 8),
            const Text('Phiên bản 1.0.0', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Đóng'))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Hỗ trợ & Hướng dẫn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    _faqItem('Dữ liệu của tôi có được bảo mật không?', 'Có. Toàn bộ dữ liệu được mã hóa. MediChain không chia sẻ thông tin với bên thứ ba.'),
                    _faqItem('AI có thể thay thế bác sĩ không?', 'Không. Medi AI chỉ hỗ trợ tham khảo. Luôn tham khảo ý kiến bác sĩ cho quyết định y tế.'),
                    _faqItem('Tôi có thể xuất dữ liệu không?', 'Tính năng xuất PDF đang được phát triển và sẽ ra mắt sớm.'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Liên hệ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _contactItem(Icons.email_outlined, 'support@medichain.vn', 'Email hỗ trợ'),
                    _contactItem(Icons.discord, 'discord.gg/medichain', 'Cộng đồng Discord'),
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

  Widget _contactItem(IconData icon, String value, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Icon(icon, size: 18, color: _kPrimary),
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

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kTextMuted, letterSpacing: 0.8),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
              trailing ?? const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
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
      decoration: BoxDecoration(color: value ? _kPrimary : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(100)),
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
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Thông báo nhắc nhở', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Nhắc uống thuốc và lịch hẹn hàng ngày', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bật thông báo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Hiện trên thanh thông báo', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ])),
          Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v), activeThumbColor: const Color(0xFF0D9488)),
        ]),
        if (_enabled) ...[
          const Divider(height: 24),
          const Text('Giờ nhắc hàng ngày', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
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
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Lưu cài đặt', style: TextStyle(fontWeight: FontWeight.bold)),
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
        if (state is Authenticated) {
          name = state.user.name ?? name;
          email = state.user.email ?? '';
        }
        return GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                      Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.5), size: 18),
              ],
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
