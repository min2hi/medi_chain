import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/logic/payment/payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/routes/payment_routes.dart';
import 'package:url_launcher/url_launcher.dart';

/// MÃ n hÃ¬nh má»Ÿ URL PayOS checkout báº±ng External Browser / In-App WebView.
/// Sau khi PayOS redirect vá» app (deep link), BLoC poll status.
class PaymentWebViewScreen extends StatefulWidget {
  final CheckoutArgs args;

  const PaymentWebViewScreen({super.key, required this.args});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with WidgetsBindingObserver {
  bool _launched = false;
  bool _returned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _launchPayOS();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Khi app resume tá»« background (user quay vá» sau khi thanh toÃ¡n)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _launched && !_returned) {
      _returned = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.read<PaymentBloc>().add(
                PaymentStatusCheckRequested(widget.args.orderCode),
              );
        }
      });
    }
  }

  Future<void> _launchPayOS() async {
    // Reset flag má»—i láº§n má»Ÿ láº¡i PayOS Ä‘á»ƒ lifecycle observer hoáº¡t Ä‘á»™ng Ä‘Ãºng
    setState(() => _returned = false);
    final uri = Uri.parse(widget.args.checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _launched = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KhÃ´ng thá»ƒ má»Ÿ trang thanh toÃ¡n')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          PaymentRoutes.openSuccess(context, state.orderCode);
        }
        if (state is PaymentFailed) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.creditCard,
                    size: 36,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _launched
                      ? 'Äang chá» xÃ¡c nháº­n thanh toÃ¡n...'
                      : 'Äang má»Ÿ trang thanh toÃ¡n...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _launched
                      ? 'HoÃ n táº¥t thanh toÃ¡n trÃªn trang PayOS.\nSau khi xong, quay láº¡i á»©ng dá»¥ng.'
                      : 'Vui lÃ²ng Ä‘á»£i trong giÃ¢y lÃ¡t...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_launched) ...[
                  // Má»Ÿ láº¡i náº¿u user Ä‘Ã³ng trÃ¬nh duyá»‡t
                  OutlinedButton.icon(
                    onPressed: _launchPayOS,
                    icon: const Icon(LucideIcons.externalLink, size: 16),
                    label: const Text('Má»Ÿ láº¡i trang thanh toÃ¡n'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kiá»ƒm tra thá»§ cÃ´ng
                  TextButton(
                    onPressed: () => context.read<PaymentBloc>().add(
                          PaymentStatusCheckRequested(widget.args.orderCode),
                        ),
                    child: const Text(
                      'TÃ´i Ä‘Ã£ thanh toÃ¡n xong',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Huá»·',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
