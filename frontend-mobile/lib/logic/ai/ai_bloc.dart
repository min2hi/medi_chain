import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';

// Events
abstract class AIEvent {}

class ConsultRequested extends AIEvent {
  final String symptoms;
  final String? conversationId;
  ConsultRequested(this.symptoms, {this.conversationId});
}

class SessionResetRequested extends AIEvent {}

// States
abstract class AIState {}

class AIInitial extends AIState {}

class AILoading extends AIState {}

class ConsultSuccess extends AIState {
  final RecommendationData data;
  ConsultSuccess(this.data);
}

class AIError extends AIState {
  final String message;
  AIError(this.message);
}

class AIBloc extends Bloc<AIEvent, AIState> {
  final AIRepository _repository;

  AIBloc(this._repository) : super(AIInitial()) {
    on<ConsultRequested>(_onConsultRequested);
    on<SessionResetRequested>(_onResetRequested);
  }

  Future<void> _onConsultRequested(
    ConsultRequested event,
    Emitter<AIState> emit,
  ) async {
    emit(AILoading());
    final response = await _repository.consult(
      event.symptoms,
      conversationId: event.conversationId,
    );

    if (response.success && response.data != null) {
      emit(ConsultSuccess(response.data!));
    } else {
      emit(AIError(response.message ?? 'Đã xảy ra lỗi khi tư vấn AI'));
    }
  }

  void _onResetRequested(SessionResetRequested event, Emitter<AIState> emit) {
    emit(AIInitial());
  }
}
