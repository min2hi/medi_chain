import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/dashboard_models.dart';
import 'package:medi_chain_mobile/data/repositories/user_repository.dart';

// Events
abstract class DashboardEvent {}

class DashboardFetchRequested extends DashboardEvent {}

class DashboardRefreshRequested extends DashboardEvent {}

// States
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final UserRepository _userRepository;

  DashboardBloc(this._userRepository) : super(DashboardInitial()) {
    on<DashboardFetchRequested>(_onFetchRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onFetchRequested(
    DashboardFetchRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final response = await _userRepository.getDashboard();

    if (response.success && response.data != null) {
      emit(DashboardLoaded(response.data!));
    } else {
      emit(DashboardError(response.message ?? 'Đã xảy ra lỗi khi tải dữ liệu'));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final response = await _userRepository.getDashboard();

    if (response.success && response.data != null) {
      emit(DashboardLoaded(response.data!));
    }
  }
}
