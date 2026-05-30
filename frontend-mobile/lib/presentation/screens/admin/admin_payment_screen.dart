import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/payment_overview_tab.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/payment_transactions_tab.dart';

/// AdminPaymentScreen — redesigned.
/// Stripe Dashboard / Linear style: number-first, no gradient cards.
class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ClinicPaymentBloc>()..add(ClinicPaymentFetchRequested()),
      child: BlocListener<ClinicPaymentBloc, ClinicPaymentState>(
        listener: (context, state) {
          if (state is ClinicPaymentFeeUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã cập nhật phí khám', style: GoogleFonts.inter()),
                backgroundColor: AdminColors.success,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AdminColors.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      PaymentOverviewTab(),
                      PaymentTransactionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Text(
        'Tài Chính',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: _PillIndicatorPay(),
        dividerColor: Colors.transparent,
        labelColor: AppTheme.kPrimary,
        unselectedLabelColor: AdminColors.textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        labelPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: const [Tab(text: 'Tổng quan'), Tab(text: 'Giao dịch')],
      ),
    );
  }
}

// ─── Pill indicator ───────────────────────────────────────────────────────────
class _PillIndicatorPay extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _PillPayPainter();
}

class _PillPayPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final h = (cfg.size?.height ?? 36) * 0.72;
    final w = (cfg.size?.width ?? 100) - 16;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx + 8,
        offset.dy + ((cfg.size?.height ?? 36) - h) / 2,
        w,
        h,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppTheme.kPrimary.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppTheme.kPrimary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }
}
