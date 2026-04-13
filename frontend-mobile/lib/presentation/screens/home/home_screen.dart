import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medical/records_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/medicine_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/appointment_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/chat_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/settings/settings_screen.dart';

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
    const ChatScreen(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
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
              icon: Icon(LucideIcons.sparkles, size: 22),
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
