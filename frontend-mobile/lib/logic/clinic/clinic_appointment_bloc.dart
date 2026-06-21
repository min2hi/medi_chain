import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/core/services/appointment_reminder_service.dart';
import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';

// --- Events ---
abstract class ClinicAppointmentEvent {}

class ClinicAppointmentsFetchRequested extends ClinicAppointmentEvent {
  final String filter;
  ClinicAppointmentsFetchRequested({this.filter = 'ALL'});
}

/// Pull-to-refresh: không emit Loading, chỉ silently reload
class ClinicAppointmentsRefreshRequested extends ClinicAppointmentEvent {}

class ClinicAppointmentStatusUpdateRequested extends ClinicAppointmentEvent {
  final String id;
  final String status;
  ClinicAppointmentStatusUpdateRequested(this.id, this.status);
}

/// Bác sĩ hoàn thành khám và lưu ghi chú lâm sàng cùng đơn thuốc
class ClinicAppointmentCompleteRequested extends ClinicAppointmentEvent {
  final String id;
  final String? doctorNotes;
  final List<Map<String, dynamic>>? medications;
  ClinicAppointmentCompleteRequested(this.id, {this.doctorNotes, this.medications});
}

// --- States ---
abstract class ClinicAppointmentState {}

class ClinicAppointmentInitial extends ClinicAppointmentState {}
class ClinicAppointmentLoading extends ClinicAppointmentState {}

class ClinicAppointmentsLoaded extends ClinicAppointmentState {
  final List<Map<String, dynamic>> appointments;
  final String filter;
  final bool isRefreshing;
  ClinicAppointmentsLoaded(this.appointments, this.filter, {this.isRefreshing = false});
}

class ClinicAppointmentError extends ClinicAppointmentState {
  final String message;
  ClinicAppointmentError(this.message);
}

class ClinicAppointmentActionSuccess extends ClinicAppointmentState {
  final String message;
  ClinicAppointmentActionSuccess(this.message);
}

// --- Bloc ---
class ClinicAppointmentBloc extends Bloc<ClinicAppointmentEvent, ClinicAppointmentState> {
  final ClinicRepository _repository;
  String _lastFilter = 'ALL';

  ClinicAppointmentBloc(this._repository) : super(ClinicAppointmentInitial()) {
    on<ClinicAppointmentsFetchRequested>(_onFetch);
    on<ClinicAppointmentsRefreshRequested>(_onRefresh);
    on<ClinicAppointmentStatusUpdateRequested>(_onUpdateStatus);
    on<ClinicAppointmentCompleteRequested>(_onComplete);
  }

  Future<void> _onFetch(ClinicAppointmentsFetchRequested event, Emitter<ClinicAppointmentState> emit) async {
    _lastFilter = event.filter;
    emit(ClinicAppointmentLoading());
    try {
      final response = await _repository.getAppointments(filter: 'ALL')
          .timeout(const Duration(seconds: 55));
      if (response.success && response.data != null) {
        emit(ClinicAppointmentsLoaded(response.data!, _lastFilter));
        _scheduleUpcomingReminders(response.data!);
      } else {
        emit(ClinicAppointmentError(response.message ?? 'Lỗi khi tải lịch hẹn'));
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isNetwork = msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('socket');
      emit(ClinicAppointmentError(
        isNetwork ? 'server_cold_start' : e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefresh(ClinicAppointmentsRefreshRequested event, Emitter<ClinicAppointmentState> emit) async {
    final prev = state;
    if (prev is ClinicAppointmentsLoaded) {
      emit(ClinicAppointmentsLoaded(prev.appointments, _lastFilter, isRefreshing: true));
    }
    try {
      final response = await _repository.getAppointments(filter: 'ALL')
          .timeout(const Duration(seconds: 55));
      if (response.success && response.data != null) {
        emit(ClinicAppointmentsLoaded(response.data!, _lastFilter));
        _scheduleUpcomingReminders(response.data!);
      } else {
        emit(ClinicAppointmentError(response.message ?? 'Lỗi tải lịch hẹn'));
      }
    } catch (e) {
      emit(ClinicAppointmentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateStatus(
      ClinicAppointmentStatusUpdateRequested event, Emitter<ClinicAppointmentState> emit) async {
    final prev = state;
    if (prev is ClinicAppointmentsLoaded) {
      final optimistic = prev.appointments.map((a) {
        if (a['id'] == event.id) return {...a, 'status': event.status};
        return a;
      }).toList();
      emit(ClinicAppointmentsLoaded(optimistic, _lastFilter));
    }
    final response = await _repository.updateAppointmentStatus(event.id, event.status);
    if (response.success) {
      if (event.status != 'CONFIRMED') {
        AppointmentReminderService.instance.cancelReminders(event.id);
      }
      emit(ClinicAppointmentActionSuccess(
        event.status == 'CONFIRMED' ? 'Đã xác nhận lịch hẹn' : 'Đã hủy lịch hẹn',
      ));
    } else {
      emit(ClinicAppointmentError(response.message ?? 'Lỗi khi cập nhật'));
    }
    add(ClinicAppointmentsRefreshRequested());
  }

  Future<void> _onComplete(
      ClinicAppointmentCompleteRequested event, Emitter<ClinicAppointmentState> emit) async {
    // Optimistic update: đổi status → COMPLETED ngay trong list
    final prev = state;
    if (prev is ClinicAppointmentsLoaded) {
      final optimistic = prev.appointments.map((a) {
        if (a['id'] == event.id) {
          return {
            ...a,
            'status': 'COMPLETED',
            if (event.doctorNotes != null) 'doctorNotes': event.doctorNotes,
          };
        }
        return a;
      }).toList();
      emit(ClinicAppointmentsLoaded(optimistic, _lastFilter));
    }
    final response = await _repository.completeAppointment(
      event.id,
      doctorNotes: event.doctorNotes,
      medications: event.medications,
    );
    if (response.success) {
      AppointmentReminderService.instance.cancelReminders(event.id);
      emit(ClinicAppointmentActionSuccess('Đã hoàn thành khám'));
    } else {
      emit(ClinicAppointmentError(response.message ?? 'Lỗi khi hoàn thành khám'));
    }
    add(ClinicAppointmentsRefreshRequested());
  }

  void _scheduleUpcomingReminders(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    final reminder = AppointmentReminderService.instance;
    for (final apt in appointments) {
      final status = apt['status'] as String? ?? '';
      if (status != 'CONFIRMED') continue;

      final dateStr = apt['date'] as String? ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null || date.isBefore(now)) continue;

      final patientName = apt['user']?['name'] as String?;

      reminder.scheduleReminders(
        appointmentId: apt['id'] as String? ?? '',
        title: apt['title'] as String? ?? '',
        date: dateStr,
        isDoctor: true,
        patientName: patientName,
      );
    }
  }
}
