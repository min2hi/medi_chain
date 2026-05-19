import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/logic/appointment/appointment_bloc.dart';
import 'package:medi_chain_mobile/presentation/routes/payment_routes.dart';
import 'package:medi_chain_mobile/presentation/screens/appointment/patient_result_sheet.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';


class AppointmentListScreen extends StatefulWidget {
  final bool openAddDialog;
  const AppointmentListScreen({super.key, this.openAddDialog = false});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  // Khá»Ÿi táº¡o bloc trong state Ä‘á»ƒ trÃ¡nh bá»‹ recreate má»—i láº§n rebuild
  late final AppointmentBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<AppointmentBloc>()..add(AppointmentsFetchRequested());
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddDialog(context);
      });
    }
  }

  @override
  void dispose() {
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
                      color: const Color(0xFF0D9488),
                      onRefresh: () async => context
                          .read<AppointmentBloc>()
                          .add(AppointmentsFetchRequested()),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: state.appointments.length,
                        itemBuilder: (context, index) =>
                            _buildAppointmentCard(
                                context, state.appointments[index]),
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

  /// Gradient header â€” Ä‘á»“ng nháº¥t vá»›i Dashboard & Settings
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF134E4A)],
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
          GestureDetector(
            onTap: () => _showAddDialog(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                LucideIcons.plus, 
                size: 20, 
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Reference: ZocDoc, MyChart â€” minimal icon, no decorative circle, outlined CTA
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
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('appointments.add'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle,
                size: 48, color: Color(0xFFDC2626)),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context
                  .read<AppointmentBloc>()
                  .add(AppointmentsFetchRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text('appointments.retry'.tr()),
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
    final isUpcoming = !isCompleted && !isCancelled && date.isAfter(DateTime.now());
    final isPaid = appointment.paymentStatus == 'PAID';
    final isUnpaid = !isPaid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accentColor = isCompleted || isUpcoming
        ? const Color(0xFF0D9488)
        : const Color(0xFFCBD5E1);

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 5, color: accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Date badge
                          Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isUpcoming ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isUpcoming ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM', 'vi').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isUpcoming ? const Color(0xFF14B8A6) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isUpcoming
                                        ? Theme.of(context).textTheme.titleMedium?.color
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      size: 13,
                                      color: isUpcoming ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('HH:mm').format(date),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isUpcoming ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDFA),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.clipboardCheck, size: 9, color: Color(0xFF0D9488)),
                                      SizedBox(width: 3),
                                      Text(
                                        'CÃ³ káº¿t quáº£',
                                        style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isUpcoming ? const Color(0xFFF0FDFA) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isUpcoming ? 'appointments.upcoming'.tr() : 'appointments.past'.tr(),
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold,
                                      color: isUpcoming ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              if (isPaid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'âœ“ ÄÃ£ TT',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                )
                              else if (isUpcoming && isUnpaid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ChÆ°a TT',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUpcoming) ...[
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _confirmDelete(context, appointment.id),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Há»§y lá»‹ch',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    if (isUnpaid) ...[
                      const SizedBox(width: 8),
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
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Thanh toÃ¡n',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isCompleted) return card;
    return GestureDetector(
      onTap: () => showPatientResultSheet(context, appointment),
      child: card,
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final appointmentBloc = context.read<AppointmentBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'appointments.new_dialog_title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'appointments.reason_label'.tr(),
                    prefixIcon: Icon(LucideIcons.stethoscope,
                        size: 18, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF0D9488), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Date & time picker tile
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF0D9488),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context, // ignore: use_build_context_synchronously
                        initialTime:
                            TimeOfDay.fromDateTime(selectedDate),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF0D9488),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (time != null) {
                        setState(() => selectedDate = DateTime(
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
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            size: 18, color: Color(0xFF94A3B8)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('HH:mm - dd/MM/yyyy')
                                .format(selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 16, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                BlocConsumer<AppointmentBloc, AppointmentState>(
                  bloc: appointmentBloc,
                  listener: (context, state) {
                    if (state is AppointmentActionSuccess) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Color(0xFF0D9488),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state is AppointmentLoading
                          ? null
                          : () {
                              if (titleController.text.trim().isEmpty) {
                                return;
                              }
                              appointmentBloc.add(
                                AppointmentCreateRequested({
                                  'title': titleController.text.trim(),
                                  'date':
                                      selectedDate.toIso8601String(),
                                }),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is AppointmentLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'appointments.save'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'appointments.delete_title'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'appointments.delete_body'.tr(),
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'appointments.cancel'.tr(),
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
              backgroundColor: Color(0xFFEF4444),
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
}


