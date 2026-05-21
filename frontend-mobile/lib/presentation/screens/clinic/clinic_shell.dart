import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_patient_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_appointments_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_patients_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_checkin_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/admin_notifications_screen.dart';
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
  late final NotificationBloc _notificationBloc;
  // Lift BLoCs lên shell để 2 tab chia sẻ cùng state — giải quyết desync
  late final ClinicAppointmentBloc _appointmentBloc;
  late final ClinicPatientBloc _patientBloc;

  // Index của tab Bệnh Nhân (để trigger sync khi switch)
  static const int _patientTabIndex = 1;
  // Index của tab Scan — camera lifecycle tự quản lý trong ClinicCheckinScreen
  static const int _scanTabIndex    = 2;

  @override
  void initState() {
    super.initState();
    _notificationBloc = getIt<NotificationBloc>()
      ..add(NotificationFetchRequested());
    _appointmentBloc = getIt<ClinicAppointmentBloc>()
      ..add(ClinicAppointmentsFetchRequested());
    _patientBloc = getIt<ClinicPatientBloc>()
      ..add(ClinicPatientsFetchRequested());
  }

  @override
  void dispose() {
    _appointmentBloc.close();
    _patientBloc.close();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _patientTabIndex && _currentIndex != _patientTabIndex) {
      _patientBloc.add(ClinicPatientsRefreshRequested());
    }
    // Appointments refresh khi quay lại tab 0 từ scan (có thể vừa check-in xong)
    if (index == 0 && _currentIndex == _scanTabIndex) {
      _appointmentBloc.add(ClinicAppointmentsFetchRequested());
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthBloc>().state;
    final isAdmin = authState is Authenticated &&
        authState.user.role?.toUpperCase() == 'ADMIN';

    final tabs = _tabs(isAdmin);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _notificationBloc),
        BlocProvider.value(value: _appointmentBloc),
        BlocProvider.value(value: _patientBloc),
      ],
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        body: _TabBody(
          currentIndex: _currentIndex,
          tabs: tabs,
          scanTabIndex: _scanTabIndex,
        ),
        bottomNavigationBar: BlocBuilder<NotificationBloc, NotificationState>(
          bloc: _notificationBloc,
          builder: (context, state) {
            final unread = state is NotificationLoaded ? state.unreadCount : 0;
            return _BottomNav(
              tabs: tabs,
              currentIndex: _currentIndex,
              unreadBadgeIndex: tabs.indexWhere((t) => t.label == 'Thông báo'),
              unreadCount: unread,
              onTap: _onTabTap,
            );
          },
        ),
      ),
    );
  }

  List<_Tab> _tabs(bool isAdmin) => [
        _Tab(
          icon: LucideIcons.calendar,
          label: 'Lịch hẹn',
          screen: const ClinicAppointmentsScreen(),
        ),
        _Tab(
          icon: LucideIcons.users,
          label: 'Bệnh nhân',
          screen: const ClinicPatientsScreen(),
        ),
        _Tab(
          icon: LucideIcons.scanLine,
          label: 'Scan',
          screen: const ClinicCheckinScreen(),
        ),
        _Tab(
          icon: LucideIcons.bell,
          label: 'Thông báo',
          // Admin/Doctor dùng screen hệ thống riêng — không lẫn với patient flow
          screen: const AdminNotificationsScreen(),
        ),
        if (isAdmin)
          _Tab(
            icon: LucideIcons.wallet,
            label: 'Tài chính',
            screen: const AdminPaymentScreen(),
          ),
        if (isAdmin)
          _Tab(
            icon: LucideIcons.settings,
            label: 'Hệ thống',
            screen: const ClinicSystemScreen(),
          ),
      ];
}

class _Tab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _Tab({required this.icon, required this.label, required this.screen});
}

// ─── Tab body — Camera-aware tab switcher ─────────────────────────────────────
// IndexedStack bình thường cho tất cả tab.
// Tab Scan (camera) dùng Offstage để ẩn khi không active
// nhưng vẫn giữ state (controller) trong memory.
// WidgetsBindingObserver trong ClinicCheckinScreen sẽ tự stop/start camera.
class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.currentIndex,
    required this.tabs,
    required this.scanTabIndex,
  });

  final int currentIndex;
  final List<_Tab> tabs;
  final int scanTabIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(tabs.length, (i) {
        final isActive = i == currentIndex;
        final isScanTab = i == scanTabIndex;

        // Scan tab: Offstage (hidden but kept alive) để quản lý lifecycle camera
        if (isScanTab) {
          return Offstage(
            offstage: !isActive,
            child: tabs[i].screen,
          );
        }

        // Các tab thường: chỉ build khi active (tiết kiệm memory)
        if (!isActive) return const SizedBox.shrink();
        return tabs[i].screen;
      }),
    );
  }
}

// ─── Bottom nav — Doximity style với notification badge ───────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.unreadBadgeIndex,
    required this.unreadCount,
  });
  final List<_Tab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadBadgeIndex;
  final int unreadCount;

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
              final showBadge = i == unreadBadgeIndex && unreadCount > 0;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top accent line
                      Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        width: 24,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      // Icon + badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            tab.icon,
                            size: 20,
                            color: selected ? AppTheme.kPrimary : AdminColors.textSecondary,
                          ),
                          if (showBadge)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
