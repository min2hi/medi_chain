import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medical/records_list_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/medicine/medicine_list_screen.dart';
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
    const ChatScreen(),       // ← Thay bằng ChatScreen (dùng /ai/chat)
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF14B8A6),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home, size: 24),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.fileText, size: 24),
            label: 'Hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.pill, size: 24),
            label: 'Thuốc',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.sparkles, size: 24),
            label: 'mediAI',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings, size: 24),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
