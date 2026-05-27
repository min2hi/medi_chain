import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

// ════════════════════════════════════════════════════════════════════════════
// LoginScreen — Professional health app auth
//
// Design rationale:
//   - Không có teal banner block / gradient header → AI-gen template pattern
//   - Branding qua typography: "Medi"(teal) + "Chain"(dark) + vertical mark
//   - Uniform background toàn màn hình → clean, không split-screen
//   - Fields không có label text phía trên — hint + icon đủ rõ (Practo/ZocDoc)
//   - Primary button với subtle glow shadow — tactile, không flat
//   - textInputAction chuyển focus tự động email→password→submit
//
// Tham khảo: ZocDoc, Oscar Health, Teladoc, Practo
// ════════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController= TextEditingController();
  final _passwordFocus     = FocusNode();
  bool  _obscurePassword   = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          final isAdmin = state.user.role?.toUpperCase() == 'ADMIN';
          context.go(isAdmin ? '/admin' : '/');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0D1520) : AppTheme.kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),

                  // ── Brand mark ─────────────────────────────────
                  const _BrandMark(),

                  const SizedBox(height: 40),

                  // ── Section heading ────────────────────────────
                  Text(
                    'auth.welcome_back'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFECF0F6)
                          : AppTheme.kTextPrimary,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'auth.login_subtitle'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF8A9BB5)
                          : AppTheme.kTextSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Email field ────────────────────────────────
                  _AuthField(
                    controller: _emailController,
                    hint: 'example@email.com',
                    label: 'auth.email'.tr(),
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'auth.validate_email_required'.tr();
                      }
                      if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                          .hasMatch(v)) {
                        return 'auth.validate_email_invalid'.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Password field ─────────────────────────────
                  _AuthField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: '••••••••',
                    label: 'auth.password'.tr(),
                    icon: LucideIcons.lock,
                    obscure: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _handleLogin,
                    isDark: isDark,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF4E6280)
                            : AppTheme.kTextMuted,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'auth.validate_password_required'.tr();
                      }
                      if (v.length < 6) {
                        return 'auth.validate_password_short'.tr();
                      }
                      return null;
                    },
                  ),

                  // ── Forgot password ────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.kPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'auth.forgot_password'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Login button ───────────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return _LoginButton(
                        isLoading: isLoading,
                        onTap: isLoading ? null : _handleLogin,
                        isDark: isDark,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Register link ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.no_account'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF8A9BB5)
                              : AppTheme.kTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.kPrimary,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'auth.register_now'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _BrandMark — Logo typographic, không dùng icon
//
// Design: vertical teal line + "Medi"(teal bold) + "Chain"(dark bold)
// Không có icon heart/shield/cross → tránh generic health app template look
// ════════════════════════════════════════════════════════════════════════════
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical line mark + logo text
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Teal vertical bar — the only visual mark
            Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Medi',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kPrimaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Chain',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFECF0F6)
                          : AppTheme.kTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Tagline — nhỏ, muted, dưới brand
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            'Nền tảng y tế cá nhân hóa',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF4E6280)
                  : AppTheme.kTextMuted,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AuthField — Input field có label floating nhỏ phía trên
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
  final bool isDark;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    required this.isDark,
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
        // Label trên field
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFF8A9BB5)
                : AppTheme.kTextSecondary,
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
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark
                  ? const Color(0xFF2A3A50)
                  : AppTheme.kTextMuted,
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                icon,
                size: 17,
                color: isDark
                    ? const Color(0xFF4E6280)
                    : AppTheme.kTextMuted,
              ),
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: suffixIcon,
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF182030) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF2A3A50)
                    : AppTheme.kBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF2A3A50)
                    : AppTheme.kBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFDC2626), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _LoginButton — CTA button với primary glow shadow
// ════════════════════════════════════════════════════════════════════════════
class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  final bool isDark;

  const _LoginButton({
    required this.isLoading,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Glow shadow — chỉ khi không loading
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
            disabledBackgroundColor: AppTheme.kPrimaryDark.withOpacity(0.6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'auth.login'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
