import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/payment_models.dart';
import 'package:medi_chain_mobile/data/repositories/payment_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class PaymentEvent {}

/// Khởi tạo màn hình: lấy phí khám
class PaymentFeeRequested extends PaymentEvent {
  final String appointmentId;
  final String appointmentTitle;
  final String appointmentDate;
  PaymentFeeRequested({
    required this.appointmentId,
    required this.appointmentTitle,
    required this.appointmentDate,
  });
}

/// User nhấn "Thanh toán" → tạo đơn
class PaymentOrderCreateRequested extends PaymentEvent {
  final String appointmentId;
  PaymentOrderCreateRequested(this.appointmentId);
}

/// App quay về từ PayOS → kiểm tra kết quả
class PaymentStatusCheckRequested extends PaymentEvent {
  final String orderCode;
  PaymentStatusCheckRequested(this.orderCode);
}

/// Load lịch sử thanh toán
class PaymentHistoryRequested extends PaymentEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}
class PaymentLoading extends PaymentState {}

/// Màn hình Payment đã load phí + thông tin lịch hẹn
class PaymentFeeLoaded extends PaymentState {
  final int fee;
  final String appointmentId;
  final String appointmentTitle;
  final String appointmentDate;
  PaymentFeeLoaded({
    required this.fee,
    required this.appointmentId,
    required this.appointmentTitle,
    required this.appointmentDate,
  });
}

/// Đơn đã tạo → có checkout URL để mở WebView
class PaymentOrderCreated extends PaymentState {
  final String checkoutUrl;
  final String orderCode;
  PaymentOrderCreated({required this.checkoutUrl, required this.orderCode});
}

/// Thanh toán thành công
class PaymentSuccess extends PaymentState {
  final String orderCode;
  PaymentSuccess(this.orderCode);
}

/// Thanh toán thất bại hoặc bị hủy
class PaymentFailed extends PaymentState {
  final String message;
  PaymentFailed(this.message);
}

/// Lịch sử thanh toán
class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentTransactionModel> transactions;
  PaymentHistoryLoaded(this.transactions);
}

class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;

  PaymentBloc(this._repository) : super(PaymentInitial()) {
    on<PaymentFeeRequested>(_onFeeRequested);
    on<PaymentOrderCreateRequested>(_onCreateOrder);
    on<PaymentStatusCheckRequested>(_onStatusCheck);
    on<PaymentHistoryRequested>(_onHistoryRequested);
  }

  Future<void> _onFeeRequested(
    PaymentFeeRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final fee = await _repository.getConsultationFee();
      emit(PaymentFeeLoaded(
        fee: fee,
        appointmentId: event.appointmentId,
        appointmentTitle: event.appointmentTitle,
        appointmentDate: event.appointmentDate,
      ));
    } catch (e) {
      emit(PaymentError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onCreateOrder(
    PaymentOrderCreateRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final order = await _repository.createOrder(event.appointmentId);
      emit(PaymentOrderCreated(
        checkoutUrl: order.checkoutUrl,
        orderCode: order.orderCode,
      ));
    } catch (e) {
      emit(PaymentError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onStatusCheck(
    PaymentStatusCheckRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final status = await _repository.checkOrderStatus(event.orderCode);
      if (status == 'PAID') {
        emit(PaymentSuccess(event.orderCode));
      } else {
        emit(PaymentFailed('Thanh toán chưa hoàn tất. Trạng thái: $status'));
      }
    } catch (e) {
      emit(PaymentFailed(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onHistoryRequested(
    PaymentHistoryRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final history = await _repository.getHistory();
      emit(PaymentHistoryLoaded(history));
    } catch (e) {
      emit(PaymentError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
