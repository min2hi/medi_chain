import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/repositories/sharing_repository.dart';

// ═══════════════════════════════
// Events
// ═══════════════════════════════

abstract class SharingEvent {}

class SharingLoadRequested extends SharingEvent {}

class SharingCreateRequested extends SharingEvent {
  final String email;
  final String type; // 'VIEW' or 'MANAGE'
  final String? expiresAt;
  SharingCreateRequested({
    required this.email,
    required this.type,
    this.expiresAt,
  });
}

class SharingRevokeRequested extends SharingEvent {
  final String sharingId;
  SharingRevokeRequested(this.sharingId);
}

// ═══════════════════════════════
// States
// ═══════════════════════════════

abstract class SharingState {}

class SharingInitial extends SharingState {}

class SharingLoading extends SharingState {}

class SharingLoaded extends SharingState {
  final List<SharingModel> mySharings;
  final List<SharingModel> sharedWithMe;
  SharingLoaded({required this.mySharings, required this.sharedWithMe});
}

class SharingActionSuccess extends SharingState {
  final String message;
  final List<SharingModel> mySharings;
  final List<SharingModel> sharedWithMe;
  SharingActionSuccess({
    required this.message,
    required this.mySharings,
    required this.sharedWithMe,
  });
}

class SharingError extends SharingState {
  final String message;
  SharingError(this.message);
}

// ═══════════════════════════════
// Bloc
// ═══════════════════════════════

class SharingBloc extends Bloc<SharingEvent, SharingState> {
  final SharingRepository _repository;
  List<SharingModel> _mySharings = [];
  List<SharingModel> _sharedWithMe = [];

  SharingBloc(this._repository) : super(SharingInitial()) {
    on<SharingLoadRequested>(_onLoad);
    on<SharingCreateRequested>(_onCreate);
    on<SharingRevokeRequested>(_onRevoke);
  }

  Future<void> _onLoad(
    SharingLoadRequested event,
    Emitter<SharingState> emit,
  ) async {
    emit(SharingLoading());
    final results = await Future.wait([
      _repository.getMySharings(),
      _repository.getSharedWithMe(),
    ]);
    final myRes = results[0];
    final recvRes = results[1];

    if (myRes.success && recvRes.success) {
      _mySharings = myRes.data ?? [];
      _sharedWithMe = recvRes.data ?? [];
      emit(SharingLoaded(mySharings: _mySharings, sharedWithMe: _sharedWithMe));
    } else {
      emit(SharingError(myRes.message ?? recvRes.message ?? 'Không thể tải dữ liệu chia sẻ'));
    }
  }

  Future<void> _onCreate(
    SharingCreateRequested event,
    Emitter<SharingState> emit,
  ) async {
    emit(SharingLoading());
    final result = await _repository.createSharing(
      email: event.email,
      type: event.type,
      expiresAt: event.expiresAt,
    );

    if (result.success && result.data != null) {
      _mySharings = [result.data!, ..._mySharings];
      emit(SharingActionSuccess(
        message: 'Chia sẻ thành công!',
        mySharings: _mySharings,
        sharedWithMe: _sharedWithMe,
      ));
    } else {
      emit(SharingError(result.message ?? 'Không thể chia sẻ. Kiểm tra email người nhận.'));
    }
  }

  Future<void> _onRevoke(
    SharingRevokeRequested event,
    Emitter<SharingState> emit,
  ) async {
    final result = await _repository.revokeSharing(event.sharingId);

    if (result['success'] == true) {
      _mySharings.removeWhere((s) => s.id == event.sharingId);
      emit(SharingActionSuccess(
        message: 'Đã thu hồi quyền truy cập.',
        mySharings: List.from(_mySharings),
        sharedWithMe: _sharedWithMe,
      ));
    } else {
      emit(SharingError(result['message'] ?? 'Không thể thu hồi quyền truy cập.'));
    }
  }
}
