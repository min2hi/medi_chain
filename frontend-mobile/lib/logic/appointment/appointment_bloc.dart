import 'package:flutter_bloc/flutter_bloc.dart';
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
    final response = await _repository.getAppointments();

    if (response.success && response.data != null) {
      emit(AppointmentsLoaded(response.data!));
    } else {
      emit(
        AppointmentError(response.message ?? 'Đã xảy ra lỗi khi tải lịch hẹn'),
      );
    }
  }

  Future<void> _onDeleteRequested(
    AppointmentDeleteRequested event,
    Emitter<AppointmentState> emit,
  ) async {
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
    final success = await _repository.createAppointment(event.data);
    if (success) {
      emit(AppointmentActionSuccess('Thêm lịch hẹn thành công'));
      add(AppointmentsFetchRequested());
    } else {
      emit(AppointmentError('Lỗi khi thêm lịch hẹn'));
    }
  }
}
