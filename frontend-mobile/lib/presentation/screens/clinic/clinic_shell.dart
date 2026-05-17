import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_appointments_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_patients_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/admin_payment_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/clinic_system_screen.dart';

/// ClinicShell — Shell dành riêng cho DOCTOR / ADMIN.
/// Pattern: Practo Ray / Epic MyChart Practice — role-aware bottom navigation.
/// DOCTOR thấy: Lịch hẹn + Bệnh nhân
/// ADMIN thấy: Lịch hẹn + Bệnh nhân + Tài chính + Hệ thống
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
    final role = authState is Authenticated
        ? (authState.user.role?.toUpperCase() ?? '')
        : '';
    final isAdmin = role == 'ADMIN';

    final tabs = _buildTabs(isAdmin);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: _ClinicBottomNav(
        tabs: tabs,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  List<_ClinicTab> _buildTabs(bool isAdmin) {
    return [
      _ClinicTab(
        icon: Icons.calendar_month_rounded,
        label: 'Lịch hẹn',
        screen: const ClinicAppointmentsScreen(),
      ),
      _ClinicTab(
        icon: Icons.people_alt_rounded,
        label: 'Bệnh nhân',
        screen: const ClinicPatientsScreen(),
      ),
      if (isAdmin)
        _ClinicTab(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Tài chính',
          screen: const AdminPaymentScreen(),
        ),
      if (isAdmin)
        _ClinicTab(
          icon: Icons.settings_rounded,
          label: 'Hệ thống',
          screen: const ClinicSystemScreen(),
        ),
    ];
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────
class _ClinicTab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _ClinicTab({required this.icon, required this.label, required this.screen});
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _ClinicBottomNav extends StatelessWidget {
  const _ClinicBottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_ClinicTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AdminColors.aiPrimary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            tab.icon,
                            size: 22,
                            color: isSelected
                                ? AdminColors.aiPrimary
                                : AdminColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AdminColors.aiPrimary
                                : AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
