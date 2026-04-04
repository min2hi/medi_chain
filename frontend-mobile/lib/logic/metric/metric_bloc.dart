import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

// Events
abstract class MetricEvent {}

class MetricsFetchRequested extends MetricEvent {
  final int? limit;
  MetricsFetchRequested({this.limit});
}

class MetricCreateRequested extends MetricEvent {
  final Map<String, dynamic> data;
  MetricCreateRequested(this.data);
}

// States
abstract class MetricState {}

class MetricInitial extends MetricState {}

class MetricLoading extends MetricState {}

class MetricsLoaded extends MetricState {
  final List<HealthMetricModel> metrics;
  MetricsLoaded(this.metrics);
}

class MetricActionSuccess extends MetricState {
  final String message;
  MetricActionSuccess(this.message);
}

class MetricError extends MetricState {
  final String message;
  MetricError(this.message);
}

class MetricBloc extends Bloc<MetricEvent, MetricState> {
  final MedicalRepository _repository;

  MetricBloc(this._repository) : super(MetricInitial()) {
    on<MetricsFetchRequested>(_onFetchRequested);
    on<MetricCreateRequested>(_onCreateRequested);
  }

  Future<void> _onFetchRequested(
    MetricsFetchRequested event,
    Emitter<MetricState> emit,
  ) async {
    emit(MetricLoading());
    final response = await _repository.getMetrics(limit: event.limit);

    if (response.success && response.data != null) {
      emit(MetricsLoaded(response.data!));
    } else {
      emit(
        MetricError(
          response.message ?? 'Đã xảy ra lỗi khi tải chỉ số sức khỏe',
        ),
      );
    }
  }

  Future<void> _onCreateRequested(
    MetricCreateRequested event,
    Emitter<MetricState> emit,
  ) async {
    emit(MetricLoading());
    final success = await _repository.createMetric(event.data);
    if (success) {
      emit(MetricActionSuccess('Thêm chỉ số thành công'));
      add(MetricsFetchRequested());
    } else {
      emit(MetricError('Lỗi khi thêm chỉ số'));
    }
  }
}
