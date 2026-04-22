import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/ai_hub_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medical/records_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/medicine_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/appointment_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/settings_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const RecordsListScreen(),
    const MedicineListScreen(),
    const AppointmentListScreen(),
    const AiHubScreen(),   // AI Hub — entry point cho Chat + Tư vấn
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D9488),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 22),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.fileText, size: 22),
              label: 'Hồ sơ',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.pill, size: 22),
              label: 'Thuốc',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendarCheck, size: 22),
              label: 'Lịch hẹn',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bot, size: 22),
              label: 'mediAI',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings, size: 22),
              label: 'Cài đặt',
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
            // Header skeleton
            Container(
              height: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title
                  _skeletonBox(width: 120, height: 16, radius: 8),
                  const SizedBox(height: 16),
                  // Quick action row
                  Row(
                    children: List.generate(4, (i) => Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                      child: _skeletonBox(width: 80, height: 88, radius: 16),
                    )),
                  ),
                  const SizedBox(height: 24),
                  // Health card
                  _skeletonBox(width: double.infinity, height: 110, radius: 16),
                  const SizedBox(height: 16),
                  // Today card
                  _skeletonBox(width: double.infinity, height: 130, radius: 16),
                  const SizedBox(height: 16),
                  // Activity card
                  _skeletonBox(width: double.infinity, height: 100, radius: 16),
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
