import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

// Events
abstract class MedicineEvent {}

class MedicinesFetchRequested extends MedicineEvent {}

class MedicineDeleteRequested extends MedicineEvent {
  final String id;
  MedicineDeleteRequested(this.id);
}

class MedicineCreateRequested extends MedicineEvent {
  final Map<String, dynamic> data;
  MedicineCreateRequested(this.data);
}

class MedicineUpdateRequested extends MedicineEvent {
  final String id;
  final Map<String, dynamic> data;
  MedicineUpdateRequested(this.id, this.data);
}

// States
abstract class MedicineState {}

class MedicineInitial extends MedicineState {}

class MedicineLoading extends MedicineState {}

class MedicinesLoaded extends MedicineState {
  final List<MedicineModel> medicines;
  MedicinesLoaded(this.medicines);
}

class MedicineActionSuccess extends MedicineState {
  final String message;
  MedicineActionSuccess(this.message);
}

class MedicineError extends MedicineState {
  final String message;
  MedicineError(this.message);
}

class MedicineBloc extends Bloc<MedicineEvent, MedicineState> {
  final MedicalRepository _repository;

  MedicineBloc(this._repository) : super(MedicineInitial()) {
    on<MedicinesFetchRequested>(_onFetchRequested);
    on<MedicineDeleteRequested>(_onDeleteRequested);
    on<MedicineCreateRequested>(_onCreateRequested);
    on<MedicineUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onFetchRequested(
    MedicinesFetchRequested event,
    Emitter<MedicineState> emit,
  ) async {
    emit(MedicineLoading());
    final response = await _repository.getMedicines();

    if (response.success && response.data != null) {
      emit(MedicinesLoaded(response.data!));
    } else {
      emit(
        MedicineError(
          response.message ?? 'Đã xảy ra lỗi khi tải danh sách thuốc',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    MedicineDeleteRequested event,
    Emitter<MedicineState> emit,
  ) async {
    final success = await _repository.deleteMedicine(event.id);
    if (success) {
      add(MedicinesFetchRequested());
    }
  }

  Future<void> _onCreateRequested(
    MedicineCreateRequested event,
    Emitter<MedicineState> emit,
  ) async {
    emit(MedicineLoading());
    final success = await _repository.createMedicine(event.data);
    if (success) {
      emit(MedicineActionSuccess('Thêm thuốc thành công'));
      add(MedicinesFetchRequested());
    } else {
      emit(MedicineError('Lỗi khi thêm thuốc'));
    }
  }

  Future<void> _onUpdateRequested(
    MedicineUpdateRequested event,
    Emitter<MedicineState> emit,
  ) async {
    emit(MedicineLoading());
    final success = await _repository.updateMedicine(event.id, event.data);
    if (success) {
      emit(MedicineActionSuccess('Cập nhật thuốc thành công'));
      add(MedicinesFetchRequested());
    } else {
      emit(MedicineError('Lỗi khi cập nhật thuốc'));
    }
  }
}
