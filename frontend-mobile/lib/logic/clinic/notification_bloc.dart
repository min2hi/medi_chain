import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // APPOINTMENT | MEDICINE | SYSTEM
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'SYSTEM',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class NotificationEvent {}

class NotificationFetchRequested extends NotificationEvent {}
class NotificationMarkAllReadRequested extends NotificationEvent {}

// ─── States ──────────────────────────────────────────────────────────────────
abstract class NotificationState {}

class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;
  NotificationLoaded(this.items, this.unreadCount);
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ClinicRepository _repository;

  NotificationBloc(this._repository) : super(NotificationInitial()) {
    on<NotificationFetchRequested>(_onFetch);
    on<NotificationMarkAllReadRequested>(_onMarkAllRead);
  }

  Future<void> _onFetch(NotificationFetchRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final response = await _repository.getNotifications()
          .timeout(const Duration(seconds: 15));
      if (response.success && response.data != null) {
        final rawList = response.data!['notifications'] as List<dynamic>? ?? [];
        final items = rawList
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final unread = response.data!['unreadCount'] as int? ?? 0;
        emit(NotificationLoaded(items, unread));
      } else {
        emit(NotificationError(response.message ?? 'Không thể tải thông báo'));
      }
    } catch (e) {
      emit(NotificationError('Lỗi kết nối'));
    }
  }

  Future<void> _onMarkAllRead(NotificationMarkAllReadRequested event, Emitter<NotificationState> emit) async {
    final prev = state;
    // Optimistic: đánh dấu tất cả đã đọc trong UI ngay
    if (prev is NotificationLoaded) {
      final updated = prev.items.map((n) => NotificationItem(
        id: n.id, title: n.title, message: n.message,
        type: n.type, isRead: true, createdAt: n.createdAt,
      )).toList();
      emit(NotificationLoaded(updated, 0));
    }
    await _repository.markAllNotificationsRead();
  }

  int get unreadCount => state is NotificationLoaded ? (state as NotificationLoaded).unreadCount : 0;
}
