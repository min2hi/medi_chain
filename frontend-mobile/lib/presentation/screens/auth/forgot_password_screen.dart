import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  late final AnimationController _checkController;
  late final Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnim = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        ForgotPasswordRequested(_emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          setState(() => _emailSent = true);
          _checkController.forward();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.arrowLeft,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          LucideIcons.keyRound,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'auth.forgot_title'.tr(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'auth.forgot_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _emailSent
                        ? _buildSuccessView()
                        : _buildFormView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Success View ──────────────────────────────────────
  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      children: [
        SizedBox(height: 16),
        ScaleTransition(
          scale: _checkAnim,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Color(0xFFF0FDFA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.mailCheck,
              size: 46,
              color: Color(0xFF14B8A6),
            ),
          ),
        ),
        SizedBox(height: 28),
        Text(
          'auth.check_inbox'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          'auth.reset_sent'.tr(namedArgs: {'email': _emailController.text.trim()}),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.6,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'auth.reset_link_expiry'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        SizedBox(height: 40),
        // Gửi lại
        TextButton.icon(
          onPressed: () => setState(() {
            _emailSent = false;
            _checkController.reset();
          }),
          icon: Icon(LucideIcons.refreshCw, size: 16),
          label: Text('auth.resend_email'.tr()),
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF14B8A6),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/login'),
            icon: Icon(LucideIcons.logIn, size: 16),
            label: Text('auth.back_to_login_page'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF14B8A6),
              side: const BorderSide(color: Color(0xFF14B8A6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form View ─────────────────────────────────────────
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth.registered_email'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'example@email.com',
              hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
              prefixIcon: Icon(LucideIcons.mail,
                  size: 18, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDC2626)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFDC2626), width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info,
                    size: 16, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'auth.reset_hint'.tr(),
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F766E),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _handleSubmit,
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(LucideIcons.send, size: 18),
                  label: Text(isLoading ? 'auth.sending'.tr() : 'auth.send_reset'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Color(0xFF99E6E0),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              style:
                  TextButton.styleFrom(foregroundColor: Color(0xFF64748B)),
              child: Text('auth.back_to_login'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
