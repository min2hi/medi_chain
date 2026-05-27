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
import 'package:medi_chain_mobile/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/admin_notifications_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/admin_payment_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/admin/clinic_system_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_appointments_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_checkin_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/clinic/clinic_patients_screen.dart';

/// ClinicShell — Staff portal shell (Doctor + Admin).
///
/// Role-based tabs — EXCLUSIVE:
///   ADMIN  → Tổng quan | Tài chính | Hệ thống | Thông báo
///   DOCTOR → Lịch hẹn  | Bệnh nhân | Scan      | Thông báo
///
/// BLoC pattern (giữ nguyên pattern gốc):
///   - Tất cả 3 BLoCs luôn được khởi tạo và provide — không conditional.
///   - isAdmin computed trong build() để select tabs, KHÔNG trong initState().
///   - MultiBlocProvider dùng inline list literal (không qua biến trung gian)
///     để Dart giữ đủ generic type info cho từng BlocProvider của T.
class ClinicShell extends StatefulWidget {
  const ClinicShell({super.key});

  @override
  State<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends State<ClinicShell> {
  int _currentIndex = 0;

  // Luôn late final — tất cả được khởi tạo trong initState bất kể role.
  // Doctor blocs được provide cho cả admin để context.read<> không fail
  // ở AdminNotificationsScreen (dùng NotificationBloc).
  late final NotificationBloc      _notificationBloc;
  late final ClinicAppointmentBloc _appointmentBloc;
  late final ClinicPatientBloc     _patientBloc;

  // Index tab Scan (chỉ có nghĩa khi là Doctor — camera lifecycle)
  static const int _scanTabIndex = 2;

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

  bool _isAdmin() {
    final authState = getIt<AuthBloc>().state;
    return authState is Authenticated &&
        authState.user.role?.toUpperCase() == 'ADMIN';
  }

  void _onTabTap(int index) {
    if (!_isAdmin()) {
      // Doctor: refresh bệnh nhân khi switch vào tab đó
      if (index == 1 && _currentIndex != 1) {
        _patientBloc.add(ClinicPatientsRefreshRequested());
      }
      // Doctor: refresh lịch hẹn khi quay lại từ scan (có thể vừa check-in)
      if (index == 0 && _currentIndex == _scanTabIndex) {
        _appointmentBloc.add(ClinicAppointmentsFetchRequested());
      }
    }
    setState(() => _currentIndex = index);
  }

  List<_Tab> get _adminTabs => [
    _Tab(icon: LucideIcons.layoutDashboard, label: 'Tổng quan', screen: const AdminDashboardScreen()),
    _Tab(icon: LucideIcons.wallet,          label: 'Tài chính',  screen: const AdminPaymentScreen()),
    _Tab(icon: LucideIcons.settings,        label: 'Hệ thống',   screen: const ClinicSystemScreen()),
    _Tab(icon: LucideIcons.bell,            label: 'Thông báo',  screen: const AdminNotificationsScreen()),
  ];

  List<_Tab> get _doctorTabs => [
    _Tab(icon: LucideIcons.calendar,  label: 'Lịch hẹn',  screen: const ClinicAppointmentsScreen()),
    _Tab(icon: LucideIcons.users,     label: 'Bệnh nhân', screen: const ClinicPatientsScreen()),
    _Tab(icon: LucideIcons.scanLine,  label: 'Scan',      screen: const ClinicCheckinScreen()),
    _Tab(icon: LucideIcons.bell,      label: 'Thông báo', screen: const AdminNotificationsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin     = _isAdmin();
    final tabs        = isAdmin ? _adminTabs : _doctorTabs;
    // Admin không có tab Scan → Offstage không cần quản lý cho admin
    final scanTabIdx  = isAdmin ? -1 : _scanTabIndex;

    // QUAN TRỌNG: Cung cấp tất cả BLoCs bằng inline list literal (không dùng
    // List<BlocProvider> variable). Lý do: khi lưu vào biến typed List<BlocProvider>,
    // Dart có thể mất generic type param của từng BlocProvider<T> khiến
    // MultiBlocProvider không build được Provider<ClinicAppointmentBloc> đúng type,
    // dẫn đến ProviderNotFoundError khi context.read<T>() trong child screens.
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
          scanTabIndex: scanTabIdx,
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
}

// ─── Tab model ────────────────────────────────────────────────────────────────
class _Tab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _Tab({required this.icon, required this.label, required this.screen});
}

// ─── Tab body — Camera-aware tab switcher ─────────────────────────────────────
/// scanTabIndex = -1 → không có tab scan (admin), Offstage không được tạo.
/// scanTabIndex >= 0 → tab đó dùng Offstage để giữ camera state trong memory.
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
        final isActive  = i == currentIndex;
        final isScanTab = scanTabIndex >= 0 && i == scanTabIndex;

        // Scan tab: Offstage — ẩn nhưng giữ camera controller sống
        if (isScanTab) {
          return Offstage(offstage: !isActive, child: tabs[i].screen);
        }

        // Các tab thường: chỉ build khi active
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
              final selected  = i == currentIndex;
              final tab       = tabs[i];
              final showBadge = i == unreadBadgeIndex && unreadCount > 0;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    splashColor:    AppTheme.kPrimary.withValues(alpha: 0.08),
                    highlightColor: AppTheme.kPrimary.withValues(alpha: 0.04),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top accent line — animated width
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          width: selected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        // Icon + notification badge
                        AnimatedScale(
                          scale: selected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                tab.icon,
                                size: 20,
                                color: selected
                                    ? AppTheme.kPrimary
                                    : AdminColors.textSecondary,
                              ),
                              if (showBadge)
                                Positioned(
                                  top: -4, right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.kError,
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
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppTheme.kPrimary
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
