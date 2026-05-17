import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_appointments_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_patients_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/admin_payment_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/clinic_system_screen.dart';

/// ClinicShell — Staff portal shell.
/// Bottom nav inspired by Doximity / Zocdoc Practice.
class ClinicShell extends StatefulWidget {
  const ClinicShell({super.key});

  @override
  State<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends State<ClinicShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final isAdmin = authState is Authenticated &&
        authState.user.role?.toUpperCase() == 'ADMIN';

    final tabs = _tabs(isAdmin);
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  List<_Tab> _tabs(bool isAdmin) => [
        _Tab(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Lịch hẹn', screen: const ClinicAppointmentsScreen()),
        _Tab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Bệnh nhân', screen: const ClinicPatientsScreen()),
        if (isAdmin) _Tab(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Tài chính', screen: const AdminPaymentScreen()),
        if (isAdmin) _Tab(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Hệ thống', screen: const ClinicSystemScreen()),
      ];
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  const _Tab({required this.icon, required this.activeIcon, required this.label, required this.screen});
}

// ─── Bottom nav — Doximity style ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tabs, required this.currentIndex, required this.onTap});
  final List<_Tab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top accent line for selected
                      Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        width: 24,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Icon(
                        selected ? tab.activeIcon : tab.icon,
                        size: 20,
                        color: selected ? AppTheme.kPrimary : AdminColors.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppTheme.kPrimary : AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
