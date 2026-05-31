import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/payment_overview_tab.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/widgets/payment_transactions_tab.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tài Chính',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AdminColors.textPrimary,
              height: 1.1,
            ),
          ),
          BlocBuilder<ClinicPaymentBloc, ClinicPaymentState>(
            builder: (context, state) {
              if (state is ClinicPaymentLoaded) {
                final fee = state.consultationFee;
                final rawParts = fee.toString().split('').reversed.toList();
                final feeStr = List.generate(
                  rawParts.length,
                  (i) => (i > 0 && i % 3 == 0) ? '${rawParts[i]}.' : rawParts[i],
                ).reversed.join();

                return ScaleOnTap(
                  onTap: () => _showFeeDialog(context, fee),
                  scaleDownFactor: 0.96,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_outlined, size: 12, color: AppTheme.kPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Phí: $feeStrđ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  void _showFeeDialog(BuildContext context, int currentFee) {
    final ctrl = TextEditingController(text: currentFee.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cập nhật phí khám',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AdminColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            suffixText: 'VND',
            suffixStyle: GoogleFonts.inter(color: AdminColors.textSecondary),
            filled: true,
            fillColor: AdminColors.elevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.kPrimary),
            ),
          ),
        ),
        actions: [
          ScaleOnTap(
            onTap: () => Navigator.pop(ctx),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('Hủy', style: GoogleFonts.inter(color: AdminColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          ScaleOnTap(
            onTap: () {
              final fee = int.tryParse(ctrl.text.replaceAll('.', ''));
              if (fee != null && fee > 0) {
                context.read<ClinicPaymentBloc>().add(ClinicPaymentFeeUpdateRequested(fee));
              }
              Navigator.pop(ctx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Lưu', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
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
