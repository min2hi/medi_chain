import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/data/repositories/admin_repository.dart';

// Helper: expose lỗi thật ra UI thay vì message chung chung
String _errorMessage(Object err) {
  if (err is DioException) {
    final status = err.response?.statusCode;
    final body = err.response?.data?.toString() ?? '';
    debugPrint('[AdminBloc] DioException: type=${err.type} status=$status body=$body');
    if (status == 401) return 'Phiên đăng nhập hết hạn (401)';
    if (status == 403) return 'Không có quyền Admin (403)';
    if (status != null) return 'Lỗi server: $status';
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'Server cold start — thử lại sau 30 giây';
    }
    if (err.type == DioExceptionType.connectionError) {
      return 'Không kết nối được server';
    }
    return 'Lỗi mạng: ${err.message}';
  }
  debugPrint('[AdminBloc] Error: $err');
  return err.toString();
}

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AdminEvent {}

// Keywords
class LoadKeywords extends AdminEvent {}
class CreateKeyword extends AdminEvent {
  final String keyword;
  final String? category;
  final String? guideline;
  CreateKeyword(this.keyword, {this.category, this.guideline});
}
class ToggleKeyword extends AdminEvent {
  final String id;
  final bool activate;
  ToggleKeyword(this.id, {required this.activate});
}
class UpdateKeyword extends AdminEvent {
  final String id;
  final String keyword;
  final String? guideline;
  UpdateKeyword(this.id, {required this.keyword, this.guideline});
}

// Combos
class LoadCombos extends AdminEvent {}
class CreateCombo extends AdminEvent {
  final List<String> symptoms;
  final String action;
  final String? description;
  CreateCombo(this.symptoms, this.action, {this.description});
}
class ActivateCombo extends AdminEvent {
  final String id;
  ActivateCombo(this.id);
}

// Review Queue
class LoadPendingReview extends AdminEvent {}
class ApproveKeyword extends AdminEvent {
  final String id;
  ApproveKeyword(this.id);
}
class RejectKeyword extends AdminEvent {
  final String id;
  RejectKeyword(this.id);
}

// Users
class LoadUsers extends AdminEvent {}
class UpdateUserRole extends AdminEvent {
  final String userId;
  final String role;
  UpdateUserRole(this.userId, this.role);
}

// Telemetry
class LoadTelemetry extends AdminEvent {}
class InvalidateCache extends AdminEvent {}

// Access Logs
class LoadAccessLogs extends AdminEvent {
  final String? date; // YYYY-MM-DD, null = hôm nay
  LoadAccessLogs({this.date});
}

// Doctor Verification
class VerifyDoctorLicense extends AdminEvent {
  final String userId;
  VerifyDoctorLicense(this.userId);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AdminState {}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}
class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}

class KeywordsLoaded extends AdminState {
  final List<SafetyKeywordModel> keywords;
  KeywordsLoaded(this.keywords);
}

class CombosLoaded extends AdminState {
  final List<ComboRuleModel> combos;
  CombosLoaded(this.combos);
}

class PendingReviewLoaded extends AdminState {
  final List<PendingReviewModel> items;
  PendingReviewLoaded(this.items);
}

class UsersLoaded extends AdminState {
  final List<AdminUserModel> users;
  UsersLoaded(this.users);
}

class TelemetryLoaded extends AdminState {
  final CacheStatsModel stats;
  final List<AuditLogModel> logs;
  TelemetryLoaded(this.stats, this.logs);
}

class AccessLogsLoaded extends AdminState {
  final AccessLogData data;
  AccessLogsLoaded(this.data);
}

class AdminActionSuccess extends AdminState {
  final String message;
  AdminActionSuccess(this.message);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;

  AdminBloc(this._repo) : super(AdminInitial()) {
    on<LoadKeywords>(_onLoadKeywords);
    on<CreateKeyword>(_onCreateKeyword);
    on<ToggleKeyword>(_onToggleKeyword);
    on<UpdateKeyword>(_onUpdateKeyword);
    on<LoadCombos>(_onLoadCombos);
    on<CreateCombo>(_onCreateCombo);
    on<ActivateCombo>(_onActivateCombo);
    on<LoadPendingReview>(_onLoadPendingReview);
    on<ApproveKeyword>(_onApproveKeyword);
    on<RejectKeyword>(_onRejectKeyword);
    on<LoadUsers>(_onLoadUsers);
    on<UpdateUserRole>(_onUpdateUserRole);
    on<LoadTelemetry>(_onLoadTelemetry);
    on<InvalidateCache>(_onInvalidateCache);
    on<LoadAccessLogs>(_onLoadAccessLogs);
    on<VerifyDoctorLicense>(_onVerifyDoctorLicense);
  }

  Future<void> _onLoadKeywords(LoadKeywords e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final list = await _repo.getKeywords();
      emit(KeywordsLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onCreateKeyword(CreateKeyword e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      await _repo.createKeyword(keyword: e.keyword, category: e.category, guideline: e.guideline);
      emit(AdminActionSuccess('Da tao tu khoa thanh cong'));
      final list = await _repo.getKeywords();
      emit(KeywordsLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onToggleKeyword(ToggleKeyword e, Emitter<AdminState> emit) async {
    try {
      if (e.activate) {
        await _repo.activateKeyword(e.id);
      } else {
        await _repo.deactivateKeyword(e.id);
      }
      final list = await _repo.getKeywords();
      emit(KeywordsLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onUpdateKeyword(UpdateKeyword e, Emitter<AdminState> emit) async {
    try {
      await _repo.updateKeyword(e.id, keyword: e.keyword, guideline: e.guideline);
      emit(AdminActionSuccess('Da cap nhat tu khoa thanh cong'));
      final list = await _repo.getKeywords();
      emit(KeywordsLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onLoadCombos(LoadCombos e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final list = await _repo.getCombos();
      emit(CombosLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onCreateCombo(CreateCombo e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      await _repo.createCombo(symptoms: e.symptoms, action: e.action, description: e.description);
      emit(AdminActionSuccess('Da tao combo rule thanh cong'));
      final list = await _repo.getCombos();
      emit(CombosLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onActivateCombo(ActivateCombo e, Emitter<AdminState> emit) async {
    try {
      await _repo.activateCombo(e.id);
      final list = await _repo.getCombos();
      emit(CombosLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onLoadPendingReview(LoadPendingReview e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final list = await _repo.getPendingReview();
      emit(PendingReviewLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onApproveKeyword(ApproveKeyword e, Emitter<AdminState> emit) async {
    try {
      await _repo.approveKeyword(e.id);
      final list = await _repo.getPendingReview();
      emit(PendingReviewLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onRejectKeyword(RejectKeyword e, Emitter<AdminState> emit) async {
    try {
      await _repo.rejectKeyword(e.id);
      final list = await _repo.getPendingReview();
      emit(PendingReviewLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onLoadUsers(LoadUsers e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final list = await _repo.getUsers();
      emit(UsersLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onUpdateUserRole(UpdateUserRole e, Emitter<AdminState> emit) async {
    try {
      await _repo.updateUserRole(e.userId, e.role);
      final list = await _repo.getUsers();
      emit(UsersLoaded(list));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onLoadTelemetry(LoadTelemetry e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final results = await Future.wait([
        _repo.getCacheStats(),
        _repo.getAuditLog(),
      ]);
      emit(TelemetryLoaded(
        results[0] as CacheStatsModel,
        results[1] as List<AuditLogModel>,
      ));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onInvalidateCache(InvalidateCache e, Emitter<AdminState> emit) async {
    try {
      await _repo.invalidateCache();
      final results = await Future.wait([
        _repo.getCacheStats(),
        _repo.getAuditLog(),
      ]);
      emit(TelemetryLoaded(
        results[0] as CacheStatsModel,
        results[1] as List<AuditLogModel>,
      ));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onLoadAccessLogs(LoadAccessLogs e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final data = await _repo.getApiAccessLogs(date: e.date);
      emit(AccessLogsLoaded(data));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }

  Future<void> _onVerifyDoctorLicense(VerifyDoctorLicense e, Emitter<AdminState> emit) async {
    try {
      final msg = await _repo.verifyDoctorLicense(e.userId);
      emit(AdminActionSuccess(msg));
      // Reload user list để UI cập nhật badge
      final users = await _repo.getUsers();
      emit(UsersLoaded(users));
    } catch (err) {
      emit(AdminError(_errorMessage(err)));
    }
  }
}
