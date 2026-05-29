import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';
import 'package:medi_chain_mobile/logic/appointment/appointment_bloc.dart';
import 'package:medi_chain_mobile/presentation/routes/payment_routes.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/appointment_qr_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/patient_result_sheet.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/staggered_list_item.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/status_badge.dart';

class AppointmentListScreen extends StatefulWidget {
  /// Khi notifier tăng giá trị → mở dialog tạo lịch mới.
  /// Dùng ValueNotifier[int] thay vì bool để trigger được nhiều lần,
  /// kể cả khi screen đã mount trong IndexedStack.
  final ValueNotifier<int>? openDialogTrigger;

  const AppointmentListScreen({super.key, this.openDialogTrigger});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  late final AppointmentBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<AppointmentBloc>()..add(AppointmentsFetchRequested());
    widget.openDialogTrigger?.addListener(_onDialogTrigger);
  }

  void _onDialogTrigger() {
    if (mounted) _showAddDialog(context);
  }

  @override
  void dispose() {
    widget.openDialogTrigger?.removeListener(_onDialogTrigger);
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        body: Column(
          children: [
            Builder(builder: (innerCtx) => _buildHeader(innerCtx)),
            Expanded(
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  if (state is AppointmentLoading ||
                      state is AppointmentInitial) {
                    return const AppSkeletonList(count: 4);
                  }
                  if (state is AppointmentError) {
                    return _buildErrorState(context, state.message);
                  }
                  if (state is AppointmentsLoaded) {
                    if (state.appointments.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return RefreshIndicator(
                      color: AppTheme.kPrimaryDark,
                      onRefresh: () async => context
                          .read<AppointmentBloc>()
                          .add(AppointmentsFetchRequested()),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: state.appointments.length,
                        itemBuilder: (context, index) => StaggeredListItem(
                          index: index,
                          child: _buildAppointmentCard(
                              context, state.appointments[index]),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.kPrimaryDark, Color(0xFF134E4A)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'appointments.title'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'appointments.subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showAddDialog(context),
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.white.withOpacity(0.2),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(LucideIcons.plus, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendarCheck,
              size: 36,
              color: isDark ? const Color(0xFF2D4A6A) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 20),
            Text(
              'appointments.empty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'appointments.empty_sub'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('appointments.add'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.kPrimaryDark,
                side: const BorderSide(color: AppTheme.kPrimaryDark, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final isColdStart = message == 'server_cold_start';
    final displayMsg = isColdStart
        ? 'Backend đang khởi động\n(Render free tier ~30s). Vui lòng thử lại.'
        : message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isColdStart ? LucideIcons.serverCrash : LucideIcons.alertCircle,
              size: 48,
              color: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              displayMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context
                    .read<AppointmentBloc>()
                    .add(AppointmentsFetchRequested()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'appointments.retry'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context, AppointmentModel appointment) {
    final date = DateTime.parse(appointment.date);
    final status = appointment.status ?? '';
    final isCompleted = status == 'COMPLETED';
    final isCancelled = status == 'CANCELLED';
    final isUpcoming =
        !isCompleted && !isCancelled && date.isAfter(DateTime.now());
    final isPaid = appointment.paymentStatus == 'PAID';
    final isVoided =
        appointment.paymentStatus == 'FAILED' && isCancelled;
    final isUnpaid = !isPaid && !isVoided;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color accent = isCompleted
        ? AppTheme.kPrimary
        : isCancelled
            ? AppTheme.kTextSecondary
            : AppTheme.kPrimaryDark;

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182030) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFEDF2F7),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCancelled
                      ? [const Color(0xFF475569), const Color(0xFF2A3A50)]
                      : [AppTheme.kPrimaryDark, const Color(0xFF14B8A6)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('dd').format(date),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isCancelled
                                ? const Color(0xFF64748B)
                                : accent,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM', 'vi').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: isDark
                        ? const Color(0xFF2A3A50)
                        : const Color(0xFFEDF2F7),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                appointment.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isCancelled
                                      ? (isDark
                                          ? const Color(0xFF475569)
                                          : const Color(0xFF94A3B8))
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0D1520)),
                                  decoration: isCancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: const Color(0xFF64748B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(
                                isDark, status, isCancelled, isCompleted, isUpcoming),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isPaid)
                          _buildMiniChip(
                            '✓ Đã thanh toán',
                            const Color(0xFF10B981),
                            isDark
                                ? const Color(0xFF0D2B1E)
                                : const Color(0xFFF0FDF4),
                          )
                        else if (isUpcoming && isUnpaid)
                          _buildMiniChip(
                            '● Chưa thanh toán',
                            const Color(0xFFD97706),
                            isDark
                                ? const Color(0xFF2A1C05)
                                : const Color(0xFFFFFBEB),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isCancelled) ..._buildTimeline(status, isDark),
            if (isUpcoming) ...[
              Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF2A3A50)
                    : const Color(0xFFEDF2F7),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildActionIcon(
                      icon: LucideIcons.qrCode,
                      onTap: () => showAppointmentQR(context, appointment),
                      isDark: isDark,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _confirmDelete(context, appointment.id),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      child: const Text('Hủy lịch'),
                    ),
                    if (isUnpaid) ...[
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          PaymentRoutes.openPayment(
                            context,
                            PaymentArgs(
                              appointmentId: appointment.id,
                              appointmentTitle: appointment.title,
                              appointmentDate: appointment.date,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kPrimaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Thanh toán'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (isCancelled) ...[
              Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF2A3A50)
                    : const Color(0xFFEDF2F7),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _confirmDelete(context, appointment.id),
                      icon: const Icon(LucideIcons.trash2, size: 13),
                      label: const Text('Xóa'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isCompleted) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPatientResultSheet(context, appointment),
        borderRadius: BorderRadius.circular(14),
        splashColor: AppTheme.kPrimaryDark.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: card,
      ),
    );
  }

  Widget _buildStatusBadge(
    bool isDark,
    String status,
    bool isCancelled,
    bool isCompleted,
    bool isUpcoming,
  ) {
    if (isCancelled) {
      return const StatusBadge(
          label: 'Đã hủy', variant: BadgeVariant.neutral, small: true);
    }
    if (isCompleted) {
      return const StatusBadge(
          label: 'Có kết quả', variant: BadgeVariant.success, small: true);
    }
    if (status == 'CONFIRMED') {
      return const StatusBadge(
          label: 'Xác nhận', variant: BadgeVariant.info, small: true);
    }
    if (isUpcoming) {
      return const StatusBadge(
          label: 'Chờ duyệt', variant: BadgeVariant.warning, small: true);
    }
    return const StatusBadge(
        label: 'Đã qua', variant: BadgeVariant.neutral, small: true);
  }

  Widget _buildMiniChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.kPrimaryDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: AppTheme.kPrimaryDark),
        ),
      ),
    );
  }

  List<Widget> _buildTimeline(String status, bool isDark) {
    return [
      Divider(
        height: 1,
        color: isDark ? const Color(0xFF2A3A50) : const Color(0xFFF1F5F9),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: _AppointmentTimeline(status: status, isDark: isDark),
      ),
    ];
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final appointmentBloc = context.read<AppointmentBloc>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF182030) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
    final textColor =
        isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary;
    final mutedColor =
        isDark ? const Color(0xFF8A9BB5) : AppTheme.kTextMuted;

    // Doctor list state
    final medicalRepo = getIt<MedicalRepository>();
    List<Map<String, dynamic>>? doctorsList;
    Map<String, dynamic>? selectedDoctor;
    bool isLoadingDoctors = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            if (doctorsList == null && isLoadingDoctors) {
              medicalRepo.getDoctors().then((list) {
                setModalState(() {
                  doctorsList = list;
                  isLoadingDoctors = false;
                });
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 12,
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.kPrimary.withValues(alpha: 0.12)
                            : AppTheme.kPrimaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.calendarPlus,
                          size: 17, color: AppTheme.kPrimaryDark),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'appointments.new_dialog_title'.tr(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Điền đầy đủ thông tin lịch hẹn',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _FormLabel(label: 'Bác sĩ khám', isDark: isDark),
                const SizedBox(height: 6),
                InkWell(
                  onTap: isLoadingDoctors
                      ? null
                      : () {
                          _showDoctorPicker(ctx, doctorsList ?? [], isDark, (doc) {
                            setModalState(() {
                              selectedDoctor = doc;
                            });
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2C3D)
                          : const Color(0xFFF8FAFC),
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.user,
                            size: 17, color: AppTheme.kPrimaryDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isLoadingDoctors
                                ? 'Đang tải danh sách bác sĩ...'
                                : (selectedDoctor != null
                                    ? '${selectedDoctor!['name']} ${selectedDoctor!['profile']?['specialty'] != null ? '(${selectedDoctor!['profile']['specialty']})' : ''}'
                                    : 'Chọn bác sĩ từ hệ thống'),
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedDoctor != null
                                  ? textColor
                                  : mutedColor,
                              fontWeight: selectedDoctor != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isLoadingDoctors)
                          const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.kPrimaryDark,
                            ),
                          )
                        else
                          Icon(LucideIcons.chevronDown,
                              size: 15, color: mutedColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FormLabel(label: 'Lý do khám', isDark: isDark),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'VD: Khám tổng quát, nhức đầu, tái khám...',
                    hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                    prefixIcon: Icon(LucideIcons.stethoscope,
                        size: 17, color: mutedColor),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E2C3D)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.kPrimaryDark, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                  ),
                ),
                const SizedBox(height: 14),
                _FormLabel(label: 'Ngày & giờ hẹn', isDark: isDark),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppTheme.kPrimaryDark),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      // ignore: use_build_context_synchronously
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                        builder: (c, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: AppTheme.kPrimaryDark),
                          ),
                          child: child!,
                        ),
                      );
                      if (time != null) {
                        setModalState(() => selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ));
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2C3D)
                          : const Color(0xFFF8FAFC),
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            size: 17, color: AppTheme.kPrimaryDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, dd/MM/yyyy — HH:mm', 'vi')
                                .format(selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 15, color: mutedColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FormLabel(
                    label: 'Ghi chú (không bắt buộc)', isDark: isDark),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Triệu chứng, yêu cầu đặc biệt...',
                    hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 44),
                      child: Icon(LucideIcons.fileText,
                          size: 17, color: mutedColor),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E2C3D)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.kPrimaryDark, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                  ),
                ),
                const SizedBox(height: 20),
                BlocConsumer<AppointmentBloc, AppointmentState>(
                  bloc: appointmentBloc,
                  listener: (context, state) {
                    if (state is AppointmentActionSuccess) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppTheme.kPrimaryDark,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } else if (state is AppointmentError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppTheme.kDanger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state is AppointmentLoading
                          ? null
                          : () {
                              if (selectedDoctor == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Vui lòng chọn bác sĩ khám'),
                                    backgroundColor: AppTheme.kWarning,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Vui lòng nhập lý do khám'),
                                    backgroundColor: AppTheme.kWarning,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              final data = <String, dynamic>{
                                'title': 'Khám với ${selectedDoctor!['name']} — ${titleCtrl.text.trim()}',
                                'date': selectedDate.toIso8601String(),
                                'doctorId': selectedDoctor!['id'],
                              };
                              if (notesCtrl.text.trim().isNotEmpty) {
                                data['notes'] = notesCtrl.text.trim();
                              }
                              appointmentBloc
                                  .add(AppointmentCreateRequested(data));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kPrimaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state is AppointmentLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'appointments.save'.tr(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    ),
  );
}

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'appointments.delete_title'.tr(),
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'appointments.delete_body'.tr(),
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'appointments.cancel'.tr(),
              style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AppointmentBloc>()
                  .add(AppointmentDeleteRequested(id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('appointments.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDoctorPicker(
    BuildContext context,
    List<Map<String, dynamic>> doctors,
    bool isDark,
    Function(Map<String, dynamic>) onSelected,
  ) {
    final surfaceColor = isDark ? const Color(0xFF182030) : Colors.white;
    final textColor = isDark ? const Color(0xFFECF0F6) : AppTheme.kTextPrimary;
    final mutedColor = isDark ? const Color(0xFF8A9BB5) : AppTheme.kTextMuted;
    final borderColor = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chọn bác sĩ khám',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            if (doctors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Không có bác sĩ nào hoạt động trong hệ thống.',
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: doctors.length,
                  separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                  itemBuilder: (c, idx) {
                    final doc = doctors[idx];
                    final profile = doc['profile'] as Map<String, dynamic>?;
                    final specialty = profile?['specialty'] as String? ?? 'Bác sĩ chuyên khoa';
                    final isVerified = profile?['licenseVerified'] as bool? ?? false;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.kPrimaryLight,
                        backgroundImage: doc['image'] != null
                            ? NetworkImage(doc['image'])
                            : null,
                        child: doc['image'] == null
                            ? Icon(LucideIcons.user, color: AppTheme.kPrimaryDark, size: 18)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            doc['name'] ?? 'Bác sĩ vô danh',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        specialty,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                      trailing: Icon(LucideIcons.chevronRight, size: 16, color: mutedColor),
                      onTap: () {
                        onSelected(doc);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Appointment Status Timeline ───────────────────────────────────────────────
class _AppointmentTimeline extends StatelessWidget {
  const _AppointmentTimeline(
      {required this.status, required this.isDark});
  final String status;
  final bool isDark;

  static const _steps = [
    _TimelineStep('Đặt lịch', LucideIcons.calendarCheck, 'PENDING'),
    _TimelineStep('Xác nhận', LucideIcons.shieldCheck, 'CONFIRMED'),
    _TimelineStep('Khám', LucideIcons.stethoscope, 'IN_PROGRESS'),
    _TimelineStep('Xong', LucideIcons.checkCircle, 'COMPLETED'),
  ];

  int _activeIndex() {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'COMPLETED':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex();
    final muted =
        isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E8F0);
    final mutedText =
        isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final filled = (i ~/ 2) < active;
            return Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 18),
                color: filled ? AppTheme.kPrimaryDark : muted,
              ),
            );
          }
          final idx = i ~/ 2;
          final step = _steps[idx];
          final isDone = idx < active;
          final isCurrent = idx == active;
          final nodeColor =
              (isDone || isCurrent) ? AppTheme.kPrimaryDark : muted;
          final iconColor =
              (isDone || isCurrent) ? Colors.white : mutedText;
          final nodeFill = (isDone || isCurrent)
              ? AppTheme.kPrimaryDark
              : Colors.transparent;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nodeFill,
                  border: Border.all(color: nodeColor, width: 1.5),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(LucideIcons.check,
                          size: 12, color: Colors.white)
                      : Icon(step.icon, size: 12, color: iconColor),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: (isDone || isCurrent)
                      ? AppTheme.kPrimaryDark
                      : mutedText,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final String statusKey;
  const _TimelineStep(this.label, this.icon, this.statusKey);
}

// ── Form label helper ─────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FormLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: isDark
            ? const Color(0xFF8A9BB5)
            : AppTheme.kTextSecondary,
      ),
    );
  }
}
