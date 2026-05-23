import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/health_twin_models.dart';
import 'package:medi_chain_mobile/data/repositories/health_twin_repository.dart';

// ══════════════════════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════════════════════

abstract class HealthTwinEvent {}

class HealthTwinFetchRequested extends HealthTwinEvent {}

class HealthTwinCheckinSubmitted extends HealthTwinEvent {
  /// 'good' | 'normal' | 'tired' | 'bad'
  final String feeling;
  HealthTwinCheckinSubmitted(this.feeling);
}

class HealthTwinAnomalyDismissed extends HealthTwinEvent {
  final String anomalyId;
  HealthTwinAnomalyDismissed(this.anomalyId);
}

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class HealthTwinState {}

class HealthTwinInitial extends HealthTwinState {}

class HealthTwinLoading extends HealthTwinState {}

class HealthTwinLoaded extends HealthTwinState {
  final HealthTwinStatus status;
  final List<HealthTimelineMonth> timeline;
  HealthTwinLoaded({required this.status, required this.timeline});
}

class HealthTwinCheckinSuccess extends HealthTwinState {}

class HealthTwinError extends HealthTwinState {
  final String message;
  HealthTwinError(this.message);
}

// ══════════════════════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════════════════════

class HealthTwinBloc extends Bloc<HealthTwinEvent, HealthTwinState> {
  final HealthTwinRepository _repository;

  HealthTwinBloc(this._repository) : super(HealthTwinInitial()) {
    on<HealthTwinFetchRequested>(_onFetch);
    on<HealthTwinCheckinSubmitted>(_onCheckin);
    on<HealthTwinAnomalyDismissed>(_onDismiss);
  }

  Future<void> _onFetch(
    HealthTwinFetchRequested event,
    Emitter<HealthTwinState> emit,
  ) async {
    emit(HealthTwinLoading());

    // Load status và timeline song song
    final results = await Future.wait([
      _repository.getStatus(),
      _repository.getTimeline(),
    ]);

    final statusRes = results[0] as HealthTwinStatusResponse;
    final timelineRes = results[1] as HealthTimelineResponse;

    if (statusRes.success) {
      emit(HealthTwinLoaded(
        status: statusRes.data ?? HealthTwinStatus.empty(),
        timeline: timelineRes.data ?? [],
      ));
    } else {
      emit(HealthTwinError(statusRes.message ?? 'Lỗi tải dữ liệu'));
    }
  }

  Future<void> _onCheckin(
    HealthTwinCheckinSubmitted event,
    Emitter<HealthTwinState> emit,
  ) async {
    await _repository.submitCheckin(event.feeling);
    emit(HealthTwinCheckinSuccess());
    // Reload sau checkin để cập nhật timeline
    add(HealthTwinFetchRequested());
  }

  Future<void> _onDismiss(
    HealthTwinAnomalyDismissed event,
    Emitter<HealthTwinState> emit,
  ) async {
    await _repository.dismissAnomaly(event.anomalyId);
    add(HealthTwinFetchRequested());
  }
}
