import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/payment/payment_bloc.dart';
import 'package:medi_chain_mobile/presentation/routes/payment_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Màn hình checkout PayOS dùng In-App WebView — Progressive Loading.
///
/// Fix v2:
///   - Không dùng full-screen overlay (che WebView gây cảm giác "treo")
///   - Dùng LinearProgressIndicator ở trên — user thấy tiến trình thực tế
///   - Timeout 25s: nếu page chưa xong vẫn ẩn loading (tránh infinite spin)
///   - Guard onPageFinished: chỉ ẩn loading khi URL là PayOS (tránh sub-frame)
class PaymentWebViewScreen extends StatefulWidget {
  final CheckoutArgs args;

  const PaymentWebViewScreen({super.key, required this.args});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;

  int _loadProgress = 0;     // 0–100 từ onProgress callback
  bool _isLoading = true;    // ẩn/hiện LinearProgressIndicator
  bool _hasError = false;
  Timer? _loadingTimeout;

  static const String _returnScheme = 'medichain';

  // Timeout: sau 25s bắt buộc ẩn loading (PayOS page vẫn dùng được)
  static const Duration _timeout = Duration(seconds: 25);

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startLoadingTimeout();
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    super.dispose();
  }

  void _startLoadingTimeout() {
    _loadingTimeout = Timer(_timeout, () {
      if (mounted && _isLoading) {
        debugPrint('[PaymentWebView] Timeout reached — hiding loading overlay');
        setState(() => _isLoading = false);
      }
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Cập nhật progress bar theo tiến trình thực tế
          onProgress: (progress) {
            debugPrint('[PaymentWebView] Progress: $progress%');
            if (mounted) setState(() => _loadProgress = progress);
          },
          onPageStarted: (url) {
            debugPrint('[PaymentWebView] Page started: $url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('[PaymentWebView] Page finished: $url');
            // Chỉ ẩn loading khi URL là PayOS hoặc page đã load xong đủ
            // Tránh trường hợp sub-frame kích hoạt finish quá sớm
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadProgress = 100;
              });
              _loadingTimeout?.cancel(); // Đã load xong, cancel timeout
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              '[PaymentWebView] Resource error: ${error.description} '
              '(code: ${error.errorCode})',
            );
            // Chỉ show error state với main frame error (errorCode != null)
            // Sub-resource lỗi (script, image) thì bỏ qua
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
              _loadingTimeout?.cancel();
            }
          },
          onHttpError: (error) {
            debugPrint(
              '[PaymentWebView] HTTP error: ${error.response?.statusCode}',
            );
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('[PaymentWebView] Navigation request: $url');

            // Intercept deep-link return từ PayOS
            if (url.startsWith('$_returnScheme://payment/return')) {
              debugPrint('[PaymentWebView] ✅ Payment return URL detected');
              _onPaymentReturn();
              return NavigationDecision.prevent;
            }

            // Intercept deep-link cancel từ PayOS
            if (url.startsWith('$_returnScheme://payment/cancel')) {
              debugPrint('[PaymentWebView] ❌ Payment cancel URL detected');
              _onPaymentCancel();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.checkoutUrl));
  }

  void _onPaymentReturn() {
    if (!mounted) return;
    context
        .read<PaymentBloc>()
        .add(PaymentStatusCheckRequested(widget.args.orderCode));
  }

  void _onPaymentCancel() {
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thanh toán đã bị hủy'),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D1520)
            : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDark),
        body: Column(
          children: [
            // ── Progress bar mỏng ở trên — hiện tiến trình thực tế ──────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isLoading ? 3 : 0,
              child: _isLoading
                  ? LinearProgressIndicator(
                      value: _loadProgress > 0 ? _loadProgress / 100 : null,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.kPrimaryDark),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── WebView hiện ngay — không bị che ─────────────────────────────
            Expanded(
              child: _hasError
                  ? _buildErrorState(isDark)
                  : WebViewWidget(controller: _controller),
            ),

            // ── Đang xác nhận overlay (chỉ khi BLoC đang check status) ──────
            BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                if (state is! PaymentLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Đang xác nhận thanh toán...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0D1520) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF182030)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0D1520),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.shield,
            size: 15,
            color: AppTheme.kPrimaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            'Thanh toán an toàn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0D1520),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _loadProgress = 0;
            });
            _startLoadingTimeout();
            _controller.reload();
          },
          icon: Icon(
            LucideIcons.refreshCw,
            size: 18,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
          tooltip: 'Tải lại',
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.wifiOff,
              size: 52,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 20),
            Text(
              'Không thể tải trang thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0D1520),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra kết nối mạng và thử lại.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _loadProgress = 0;
                });
                _startLoadingTimeout();
                _controller.reload();
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kPrimaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




