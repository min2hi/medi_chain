import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';

// --- Events ---
abstract class ClinicPaymentEvent {}

class ClinicPaymentFetchRequested extends ClinicPaymentEvent {}

class ClinicPaymentFeeUpdateRequested extends ClinicPaymentEvent {
  final int fee;
  ClinicPaymentFeeUpdateRequested(this.fee);
}

// --- States ---
abstract class ClinicPaymentState {}

class ClinicPaymentInitial extends ClinicPaymentState {}
class ClinicPaymentLoading extends ClinicPaymentState {}

class ClinicPaymentLoaded extends ClinicPaymentState {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> transactions;

  ClinicPaymentLoaded(this.overview, this.transactions);

  // Convenience getters
  int get consultationFee => (overview['consultationFee'] as num?)?.toInt() ?? 200000;
  int get todayCount => (overview['todayCount'] as num?)?.toInt() ?? 0;
  DateTime? get feeUpdatedAt {
    final raw = overview['feeUpdatedAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }
}

class ClinicPaymentError extends ClinicPaymentState {
  final String message;
  ClinicPaymentError(this.message);
}

class ClinicPaymentFeeUpdated extends ClinicPaymentState {}

// --- Bloc ---
class ClinicPaymentBloc extends Bloc<ClinicPaymentEvent, ClinicPaymentState> {
  final ClinicRepository _repository;

  ClinicPaymentBloc(this._repository) : super(ClinicPaymentInitial()) {
    on<ClinicPaymentFetchRequested>(_onFetch);
    on<ClinicPaymentFeeUpdateRequested>(_onUpdateFee);
  }

  Future<void> _onFetch(ClinicPaymentFetchRequested event, Emitter<ClinicPaymentState> emit) async {
    emit(ClinicPaymentLoading());

    try {
      // Fetch cả hai song song, chung 1 timeout 55s
      final results = await Future.wait([
        _repository.getPaymentOverview(),
        _repository.getPaymentTransactions(),
      ]).timeout(const Duration(seconds: 55));

      final overviewRes = results[0];
      final txRes = results[1];

      if (overviewRes.success && txRes.success) {
        emit(ClinicPaymentLoaded(
          overviewRes.data as Map<String, dynamic>,
          txRes.data as List<Map<String, dynamic>>,
        ));
      } else {
        emit(ClinicPaymentError(
          overviewRes.message ?? txRes.message ?? 'Lỗi tải dữ liệu tài chính',
        ));
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isNetwork = msg.contains('timeout') ||
          msg.contains('connection') ||
          msg.contains('socket');
      emit(ClinicPaymentError(
        isNetwork ? 'server_cold_start' : 'Lỗi kết nối',
      ));
    }
  }

  Future<void> _onUpdateFee(ClinicPaymentFeeUpdateRequested event, Emitter<ClinicPaymentState> emit) async {
    final res = await _repository.updateConsultationFee(event.fee);
    if (res.success) {
      emit(ClinicPaymentFeeUpdated());
      // Refresh overview với phí mới
      add(ClinicPaymentFetchRequested());
    } else {
      emit(ClinicPaymentError(res.message ?? 'Không thể cập nhật phí khám'));
    }
  }
}
