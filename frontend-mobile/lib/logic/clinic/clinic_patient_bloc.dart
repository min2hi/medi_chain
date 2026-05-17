import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';

// --- Events ---
abstract class ClinicPatientEvent {}

class ClinicPatientsFetchRequested extends ClinicPatientEvent {}

class ClinicPatientsSearchChanged extends ClinicPatientEvent {
  final String query;
  ClinicPatientsSearchChanged(this.query);
}

// --- States ---
abstract class ClinicPatientState {}

class ClinicPatientInitial extends ClinicPatientState {}
class ClinicPatientLoading extends ClinicPatientState {}

class ClinicPatientsLoaded extends ClinicPatientState {
  final List<Map<String, dynamic>> patients;
  final String searchQuery;
  
  List<Map<String, dynamic>> get filteredPatients {
    if (searchQuery.isEmpty) return patients;
    final q = searchQuery.toLowerCase();
    return patients.where((p) {
      final name = (p['name'] as String?)?.toLowerCase() ?? '';
      final phone = (p['phone'] as String?) ?? '';
      return name.contains(q) || phone.contains(q);
    }).toList();
  }
  
  ClinicPatientsLoaded(this.patients, {this.searchQuery = ''});
}

class ClinicPatientError extends ClinicPatientState {
  final String message;
  ClinicPatientError(this.message);
}

// --- Bloc ---
class ClinicPatientBloc extends Bloc<ClinicPatientEvent, ClinicPatientState> {
  final ClinicRepository _repository;

  ClinicPatientBloc(this._repository) : super(ClinicPatientInitial()) {
    on<ClinicPatientsFetchRequested>(_onFetch);
    on<ClinicPatientsSearchChanged>(_onSearch);
  }

  Future<void> _onFetch(ClinicPatientsFetchRequested event, Emitter<ClinicPatientState> emit) async {
    emit(ClinicPatientLoading());
    final response = await _repository.getPatients();
    if (response.success && response.data != null) {
      emit(ClinicPatientsLoaded(response.data!));
    } else {
      emit(ClinicPatientError(response.message ?? 'Lỗi khi tải bệnh nhân'));
    }
  }

  void _onSearch(ClinicPatientsSearchChanged event, Emitter<ClinicPatientState> emit) {
    final currentState = state;
    if (currentState is ClinicPatientsLoaded) {
      emit(ClinicPatientsLoaded(currentState.patients, searchQuery: event.query));
    }
  }
}
