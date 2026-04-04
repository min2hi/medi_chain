import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

// Events
abstract class MedicalEvent {}

class RecordsFetchRequested extends MedicalEvent {}

class RecordDeleteRequested extends MedicalEvent {
  final String id;
  RecordDeleteRequested(this.id);
}

class RecordCreateRequested extends MedicalEvent {
  final Map<String, dynamic> data;
  RecordCreateRequested(this.data);
}

class RecordUpdateRequested extends MedicalEvent {
  final String id;
  final Map<String, dynamic> data;
  RecordUpdateRequested(this.id, this.data);
}

// States
abstract class MedicalState {}

class MedicalInitial extends MedicalState {}

class MedicalLoading extends MedicalState {}

class RecordsLoaded extends MedicalState {
  final List<MedicalRecordModel> records;
  RecordsLoaded(this.records);
}

class MedicalActionSuccess extends MedicalState {
  final String message;
  MedicalActionSuccess(this.message);
}

class MedicalError extends MedicalState {
  final String message;
  MedicalError(this.message);
}

class MedicalBloc extends Bloc<MedicalEvent, MedicalState> {
  final MedicalRepository _repository;

  MedicalBloc(this._repository) : super(MedicalInitial()) {
    on<RecordsFetchRequested>(_onFetchRequested);
    on<RecordDeleteRequested>(_onDeleteRequested);
    on<RecordCreateRequested>(_onCreateRequested);
    on<RecordUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onFetchRequested(
    RecordsFetchRequested event,
    Emitter<MedicalState> emit,
  ) async {
    emit(MedicalLoading());
    final response = await _repository.getRecords();

    if (response.success && response.data != null) {
      emit(RecordsLoaded(response.data!));
    } else {
      emit(MedicalError(response.message ?? 'Đã xảy ra lỗi khi tải hồ sơ'));
    }
  }

  Future<void> _onDeleteRequested(
    RecordDeleteRequested event,
    Emitter<MedicalState> emit,
  ) async {
    final success = await _repository.deleteRecord(event.id);
    if (success) {
      add(RecordsFetchRequested());
    }
  }

  Future<void> _onCreateRequested(
    RecordCreateRequested event,
    Emitter<MedicalState> emit,
  ) async {
    emit(MedicalLoading());
    final success = await _repository.createRecord(event.data);
    if (success) {
      emit(MedicalActionSuccess('Thêm hồ sơ thành công'));
      add(RecordsFetchRequested());
    } else {
      emit(MedicalError('Lỗi khi thêm hồ sơ'));
    }
  }

  Future<void> _onUpdateRequested(
    RecordUpdateRequested event,
    Emitter<MedicalState> emit,
  ) async {
    emit(MedicalLoading());
    final success = await _repository.updateRecord(event.id, event.data);
    if (success) {
      emit(MedicalActionSuccess('Cập nhật hồ sơ thành công'));
      add(RecordsFetchRequested());
    } else {
      emit(MedicalError('Lỗi khi cập nhật hồ sơ'));
    }
  }
}
