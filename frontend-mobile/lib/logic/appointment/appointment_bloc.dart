import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/services/appointment_reminder_service.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

// Events
abstract class AppointmentEvent {}

class AppointmentsFetchRequested extends AppointmentEvent {}

class AppointmentDeleteRequested extends AppointmentEvent {
  final String id;
  AppointmentDeleteRequested(this.id);
}

class AppointmentCreateRequested extends AppointmentEvent {
  final Map<String, dynamic> data;
  AppointmentCreateRequested(this.data);
}

// States
abstract class AppointmentState {}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentsLoaded extends AppointmentState {
  final List<AppointmentModel> appointments;
  AppointmentsLoaded(this.appointments);
}

class AppointmentActionSuccess extends AppointmentState {
  final String message;
  AppointmentActionSuccess(this.message);
}

class AppointmentError extends AppointmentState {
  final String message;
  AppointmentError(this.message);
}

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final MedicalRepository _repository;
  final _reminder = AppointmentReminderService.instance;

  AppointmentBloc(this._repository) : super(AppointmentInitial()) {
    on<AppointmentsFetchRequested>(_onFetchRequested);
    on<AppointmentDeleteRequested>(_onDeleteRequested);
    on<AppointmentCreateRequested>(_onCreateRequested);
  }

  Future<void> _onFetchRequested(
    AppointmentsFetchRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final response = await _repository.getAppointments()
          .timeout(const Duration(seconds: 55));
      if (response.success && response.data != null) {
        final appointments = response.data!;
        emit(AppointmentsLoaded(appointments));
        // Auto-schedule reminders cho lịch CONFIRMED sắp tới
        _scheduleUpcomingReminders(appointments);
      } else {
        emit(AppointmentError(
          response.message ?? 'Đã xảy ra lỗi khi tải lịch hẹn',
        ));
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isNetwork = msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('socket');
      emit(AppointmentError(
        isNetwork ? 'server_cold_start' : e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onDeleteRequested(
    AppointmentDeleteRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    // Hủy reminder trước khi xóa
    await _reminder.cancelReminders(event.id);
    final success = await _repository.deleteAppointment(event.id);
    if (success) {
      add(AppointmentsFetchRequested());
    }
  }

  Future<void> _onCreateRequested(
    AppointmentCreateRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final success = await _repository.createAppointment(event.data);
      if (success) {
        emit(AppointmentActionSuccess('Thêm lịch hẹn thành công'));
        add(AppointmentsFetchRequested());
      } else {
        emit(AppointmentError('Lỗi khi thêm lịch hẹn'));
      }
    } catch (e) {
      emit(AppointmentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Schedule reminders cho các lịch CONFIRMED, trong tương lai
  void _scheduleUpcomingReminders(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    for (final apt in appointments) {
      if (apt.status != 'CONFIRMED') continue;
      final date = DateTime.tryParse(apt.date);
      if (date == null || date.isBefore(now)) continue;
      // Fire-and-forget: không await để không block UI
      _reminder.scheduleReminders(
        appointmentId: apt.id,
        title: apt.title,
        date: apt.date,
      );
    }
  }
}
