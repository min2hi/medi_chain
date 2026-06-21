import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/ai_hub_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medical/records_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/medicine_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/appointment_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/settings_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  final bool openAddDialog;
  const HomeScreen(
      {super.key, this.initialTab = 0, this.openAddDialog = false});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  // Notifier để trigger từ bên ngoài mà không cần GlobalKey
  final _openDialogNotifier = ValueNotifier<int>(0);
  final _refreshNotifier = ValueNotifier<int>(0);
  late final List<Widget> _screens;

  /// Public method to programmatically change tabs and fire the dialog trigger.
  void setTabAndOpenDialog(int index) {
    setState(() => _selectedIndex = index);
    _fireOpenDialog();
    if (index == 3) {
      _fireRefresh();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _screens = [
      const DashboardScreen(),
      const RecordsListScreen(),
      const MedicineListScreen(),
      AppointmentListScreen(
        openDialogTrigger: _openDialogNotifier,
        refreshTrigger: _refreshNotifier,
      ),
      const AiHubScreen(),
      const SettingsScreen(),
    ];
    // Deep link hoặc launch lần đầu với openAddDialog
    if (widget.openAddDialog && widget.initialTab == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fireOpenDialog();
          _fireRefresh();
        }
      });
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() => _selectedIndex = widget.initialTab);
      if (widget.initialTab == 3) {
        _fireRefresh();
      }
    }
    // Mỗi lần Quick Action "Đặt lịch" trigger context.go('/') với openAddDialog
    if (widget.openAddDialog && !oldWidget.openAddDialog) {
      setState(() => _selectedIndex = 3);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fireOpenDialog();
          _fireRefresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _openDialogNotifier.dispose();
    _refreshNotifier.dispose();
    super.dispose();
  }

  void _fireOpenDialog() {
    // Tăng counter → AppointmentListScreen lắng nghe và mở dialog
    _openDialogNotifier.value++;
  }

  void _fireRefresh() {
    _refreshNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A3A50)
                    : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // BUG-07 FIX: chỉ refresh khi chuyển sang tab khác,
            // không refresh khi đang ở tab 3 rồi tap lại
            final wasOnAppointments = _selectedIndex == 3;
            setState(() => _selectedIndex = index);
            if (index == 3 && !wasOnAppointments) {
              _fireRefresh();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppTheme.kPrimary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.home, size: 22),
              label: 'nav.home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.fileText, size: 22),
              label: 'nav.records'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.pill, size: 22),
              label: 'nav.medicine'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.calendarCheck, size: 22),
              label: 'nav.appointments'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.bot, size: 22),
              label: 'nav.ai'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.settings, size: 22),
              label: 'nav.settings'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer Skeleton dùng chung cho Dashboard loading ────────────────────────
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      period: const Duration(milliseconds: 1200),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, color: Colors.white),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: 120, height: 16, radius: 8),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(
                        4,
                        (i) => Padding(
                              padding:
                                  EdgeInsets.only(right: i < 3 ? 12 : 0),
                              child: _skeletonBox(
                                  width: 80, height: 88, radius: 16),
                            )),
                  ),
                  const SizedBox(height: 24),
                  _skeletonBox(
                      width: double.infinity, height: 110, radius: 16),
                  const SizedBox(height: 16),
                  _skeletonBox(
                      width: double.infinity, height: 130, radius: 16),
                  const SizedBox(height: 16),
                  _skeletonBox(
                      width: double.infinity, height: 100, radius: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
