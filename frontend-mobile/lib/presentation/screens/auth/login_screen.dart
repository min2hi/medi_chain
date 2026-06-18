import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

// ════════════════════════════════════════════════════════════════════════════
// LoginScreen — Biometric-first login
//
// Mode A (Biometric): Khi user đã bật Quick Unlock
//   → Hiện tên user + nút vân tay, auto-trigger ngay khi mount.
//   → Nút "Dùng mật khẩu" để fallback về Mode B.
//
// Mode B (Password): Lần đầu hoặc khi Biometric fail
//   → Form email + password truyền thống.
//   → Sau khi login thành công mà chưa bật biometric → hiện EnableBiometricSheet.
//
// Tham khảo: MyChart (Epic), NHS App, Practo
// ════════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus      = FocusNode();

  bool _obscurePassword = true;
  bool _isBiometricMode = false;   // true → hiện màn biometric
  String? _savedName;              // Tên user đã lưu (hiển thị trên màn biometric)
  String? _savedEmail;             // Email đã lưu (pre-fill form khi fallback)

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)),
      );

  Widget _anim(double s, double e, Widget child) => FadeTransition(
        opacity: _fade(s, e),
        child: SlideTransition(position: _slide(s, e), child: child),
      );

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _checkBiometricMode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Init logic: kiểm tra biometric preference + hardware ─────────────────
  Future<void> _checkBiometricMode() async {
    // Tạm thời vô hiệu hóa Biometric trên Emulator để demo an toàn
    return;
  }

  // ── Biometric trigger ─────────────────────────────────────────────────────
  void _triggerBiometric() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(BiometricLoginRequested());
  }

  // ── Password login ────────────────────────────────────────────────────────
  void _handleLogin() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              _emailController.text.trim(),
              _passwordController.text,
            ),
          );
    }
  }

  // ── Switch sang form password (fallback) ──────────────────────────────────
  void _switchToPassword() {
    setState(() => _isBiometricMode = false);
    if (_savedEmail != null && _emailController.text.isEmpty) {
      _emailController.text = _savedEmail!;
    }
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── BLoC listener ─────────────────────────────────────────────────────────
  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      final role    = state.user.role?.toUpperCase() ?? '';
      final isStaff = role == 'ADMIN' || role == 'DOCTOR';

      // Tạm thời chuyển thẳng vào màn hình chính để demo mượt mà, không hỏi biometric
      context.go(isStaff ? '/clinic' : '/');
    } else if (state is BiometricAuthFailed) {
      // Biometric fail → switch sang form password, pre-fill email
      if (state.savedEmail != null && _emailController.text.isEmpty) {
        _emailController.text = state.savedEmail!;
      }
      setState(() => _isBiometricMode = false);
      _animCtrl
        ..reset()
        ..forward();
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(state.message)),
          ]),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthState,
      child: Scaffold(
        backgroundColor: AppTheme.kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header banner ────────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.0, 0.45),
                  child: const _LoginBanner(),
                ),

                // ── Body: biometric mode hoặc password form ───────────────
                if (_isBiometricMode)
                  _buildBiometricMode()
                else
                  _buildPasswordMode(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mode A: Biometric ─────────────────────────────────────────────────────
  Widget _buildBiometricMode() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        children: [
          // Avatar + greeting
          _anim(0.1, 0.5,
            Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kPrimary, AppTheme.kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kPrimary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (_savedName?.isNotEmpty == true)
                        ? _savedName![0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chào mừng trở lại${_savedName != null ? ',' : '!'}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_savedName != null) ...[
                const SizedBox(height: 4),
                Text(
                  _savedName!,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
              if (_savedEmail != null) ...[
                const SizedBox(height: 4),
                Text(
                  _savedEmail!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.kTextMuted,
                  ),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 48),

          // Nút biometric chính
          _anim(0.3, 0.7,
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return GestureDetector(
                  onTap: isLoading ? null : _triggerBiometric,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: isLoading
                          ? AppTheme.kPrimary.withValues(alpha: 0.6)
                          : AppTheme.kPrimary,
                      shape: BoxShape.circle,
                      boxShadow: isLoading ? null : [
                        BoxShadow(
                          color: AppTheme.kPrimary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 28, height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                            size: 44,
                          ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          _anim(0.4, 0.8,
            Text(
              'Chạm để xác thực',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.kTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Divider "hoặc"
          _anim(0.5, 0.9,
            Row(children: [
              const Expanded(child: Divider(color: AppTheme.kBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'hoặc',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppTheme.kBorder)),
            ]),
          ),

          const SizedBox(height: 20),

          // Secondary actions
          _anim(0.6, 1.0,
            Column(children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _switchToPassword,
                  icon: const Icon(LucideIcons.keyRound, size: 16),
                  label: const Text('Dùng mật khẩu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.kTextSecondary,
                    side: const BorderSide(color: AppTheme.kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isBiometricMode = false;
                    _emailController.clear();
                  });
                  _animCtrl
                    ..reset()
                    ..forward();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.kTextMuted,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                ),
                child: Text(
                  'Dùng tài khoản khác',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Mode B: Email + Password ───────────────────────────────────────────────
  Widget _buildPasswordMode() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email
            _anim(0.2, 0.6,
              _AuthField(
                controller: _emailController,
                hint: 'example@email.com',
                label: 'Email',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 16),

            // Mật khẩu
            _anim(0.3, 0.7,
              _AuthField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                hint: '••••••••',
                label: 'Mật khẩu',
                icon: LucideIcons.lock,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                onEditingComplete: _handleLogin,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                    color: AppTheme.kTextMuted,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
            ),

            // Quên mật khẩu
            _anim(0.35, 0.75,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Quên mật khẩu?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kPrimary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nút đăng nhập
            _anim(0.4, 0.85,
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  final canUseBio = _savedEmail != null;

                  if (canUseBio) {
                    return Row(
                      children: [
                        Expanded(
                          child: _LoginButton(
                            isLoading: isLoading,
                            onTap: isLoading ? null : _handleLogin,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: isLoading ? null : () {
                            setState(() => _isBiometricMode = true);
                            _triggerBiometric();
                          },
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.kPrimary.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              color: AppTheme.kPrimary,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return _LoginButton(
                    isLoading: isLoading,
                    onTap: isLoading ? null : _handleLogin,
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Đăng ký
            _anim(0.5, 1.0,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.kTextSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.kPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Đăng ký',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _LoginBanner — Teal header
// ════════════════════════════════════════════════════════════════════════════
class _LoginBanner extends StatelessWidget {
  const _LoginBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3, height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Medi',
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Chain',
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.70), letterSpacing: -0.3,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Chào mừng trở lại',
            style: GoogleFonts.inter(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: -0.4, height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đăng nhập để tiếp tục sử dụng MediChain.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.70)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AuthField — Input field với label phía trên
// ════════════════════════════════════════════════════════════════════════════
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.kTextSecondary,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppTheme.kTextMuted, fontSize: 14),
            prefixIcon: Icon(icon, size: 17, color: AppTheme.kTextMuted),
            suffixIcon: suffixIcon != null
                ? Padding(padding: const EdgeInsets.only(right: 4), child: suffixIcon)
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.kPrimary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDC2626))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _LoginButton — CTA với primary glow
// ════════════════════════════════════════════════════════════════════════════
class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isLoading ? null : AppShadow.primaryGlow,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.kPrimary,
            disabledBackgroundColor: AppTheme.kPrimaryDark.withValues(alpha: 0.6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  'Đăng nhập',
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
