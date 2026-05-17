import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';

// --- Events ---
abstract class ClinicAppointmentEvent {}

class ClinicAppointmentsFetchRequested extends ClinicAppointmentEvent {
  final String filter;
  ClinicAppointmentsFetchRequested({this.filter = 'ALL'});
}

class ClinicAppointmentStatusUpdateRequested extends ClinicAppointmentEvent {
  final String id;
  final String status;
  ClinicAppointmentStatusUpdateRequested(this.id, this.status);
}

// --- States ---
abstract class ClinicAppointmentState {}

class ClinicAppointmentInitial extends ClinicAppointmentState {}
class ClinicAppointmentLoading extends ClinicAppointmentState {}

class ClinicAppointmentsLoaded extends ClinicAppointmentState {
  final List<Map<String, dynamic>> appointments;
  final String filter;
  ClinicAppointmentsLoaded(this.appointments, this.filter);
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

  ClinicAppointmentBloc(this._repository) : super(ClinicAppointmentInitial()) {
    on<ClinicAppointmentsFetchRequested>(_onFetch);
    on<ClinicAppointmentStatusUpdateRequested>(_onUpdateStatus);
  }

  Future<void> _onFetch(ClinicAppointmentsFetchRequested event, Emitter<ClinicAppointmentState> emit) async {
    emit(ClinicAppointmentLoading());
    final response = await _repository.getAppointments(filter: event.filter);
    if (response.success && response.data != null) {
      emit(ClinicAppointmentsLoaded(response.data!, event.filter));
    } else {
      emit(ClinicAppointmentError(response.message ?? 'Lỗi khi tải lịch hẹn'));
    }
  }

  Future<void> _onUpdateStatus(ClinicAppointmentStatusUpdateRequested event, Emitter<ClinicAppointmentState> emit) async {
    final currentState = state;
    final String currentFilter = currentState is ClinicAppointmentsLoaded ? currentState.filter : 'ALL';
    
    emit(ClinicAppointmentLoading());
    final response = await _repository.updateAppointmentStatus(event.id, event.status);
    
    if (response.success) {
      emit(ClinicAppointmentActionSuccess('Cập nhật trạng thái thành công'));
    } else {
      emit(ClinicAppointmentError(response.message ?? 'Lỗi khi cập nhật trạng thái'));
    }
    
    // Always refresh list
    add(ClinicAppointmentsFetchRequested(filter: currentFilter));
  }
}
