import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Bác sĩ hoàn thành khám và lưu ghi chú lâm sàng
class ClinicAppointmentCompleteRequested extends ClinicAppointmentEvent {
  final String id;
  final String? doctorNotes;
  ClinicAppointmentCompleteRequested(this.id, {this.doctorNotes});
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
    final response = await _repository.getAppointments(filter: 'ALL')
        .timeout(const Duration(seconds: 15), onTimeout: () =>
          throw Exception('Máy chủ không phản hồi. Vui lòng thử lại.'));
    if (response.success && response.data != null) {
      emit(ClinicAppointmentsLoaded(response.data!, _lastFilter));
    } else {
      emit(ClinicAppointmentError(response.message ?? 'Lỗi khi tải lịch hẹn'));
    }
  }

  Future<void> _onRefresh(ClinicAppointmentsRefreshRequested event, Emitter<ClinicAppointmentState> emit) async {
    final prev = state;
    if (prev is ClinicAppointmentsLoaded) {
      emit(ClinicAppointmentsLoaded(prev.appointments, _lastFilter, isRefreshing: true));
    }
    try {
      final response = await _repository.getAppointments(filter: 'ALL')
          .timeout(const Duration(seconds: 15));
      if (response.success && response.data != null) {
        emit(ClinicAppointmentsLoaded(response.data!, _lastFilter));
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
    final response = await _repository.completeAppointment(event.id, doctorNotes: event.doctorNotes);
    if (response.success) {
      emit(ClinicAppointmentActionSuccess('Đã hoàn thành khám'));
    } else {
      emit(ClinicAppointmentError(response.message ?? 'Lỗi khi hoàn thành khám'));
    }
    add(ClinicAppointmentsRefreshRequested());
  }
}
