import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';

// --- Events ---
abstract class ClinicPaymentEvent {}

class ClinicPaymentFetchRequested extends ClinicPaymentEvent {}

// --- States ---
abstract class ClinicPaymentState {}

class ClinicPaymentInitial extends ClinicPaymentState {}
class ClinicPaymentLoading extends ClinicPaymentState {}

class ClinicPaymentLoaded extends ClinicPaymentState {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> transactions;
  
  ClinicPaymentLoaded(this.overview, this.transactions);
}

class ClinicPaymentError extends ClinicPaymentState {
  final String message;
  ClinicPaymentError(this.message);
}

// --- Bloc ---
class ClinicPaymentBloc extends Bloc<ClinicPaymentEvent, ClinicPaymentState> {
  final ClinicRepository _repository;

  ClinicPaymentBloc(this._repository) : super(ClinicPaymentInitial()) {
    on<ClinicPaymentFetchRequested>(_onFetch);
  }

  Future<void> _onFetch(ClinicPaymentFetchRequested event, Emitter<ClinicPaymentState> emit) async {
    emit(ClinicPaymentLoading());
    
    // Fetch both in parallel
    final overviewFuture = _repository.getPaymentOverview();
    final transactionsFuture = _repository.getPaymentTransactions();
    
    final results = await Future.wait([overviewFuture, transactionsFuture]);
    
    final overviewRes = results[0];
    final transactionsRes = results[1] as dynamic; // casting issues without this
    
    if (overviewRes.success && transactionsRes.success) {
      emit(ClinicPaymentLoaded(
        overviewRes.data as Map<String, dynamic>,
        transactionsRes.data as List<Map<String, dynamic>>,
      ));
    } else {
      emit(ClinicPaymentError('Lỗi tải dữ liệu tài chính'));
    }
  }
}
