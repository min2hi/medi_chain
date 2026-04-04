import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';

// ═══════════════════════════════
// Events
// ═══════════════════════════════

abstract class ChatEvent {}

/// Gửi 1 tin nhắn lên /ai/chat
class ChatMessageSent extends ChatEvent {
  final String message;
  ChatMessageSent(this.message);
}

/// Reset cuộc trò chuyện, tạo conversation mới
class ChatSessionReset extends ChatEvent {}

// ═══════════════════════════════
// States
// ═══════════════════════════════

abstract class ChatState {}

class ChatInitial extends ChatState {}

/// Đang có request đang chờ (typing indicator)
class ChatLoading extends ChatState {
  final List<ChatMessage> messages;
  ChatLoading(this.messages);
}

/// Danh sách messages hiện tại (includes last reply)
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  final List<ChatMessage> messages;
  ChatError(this.message, this.messages);
}

// ═══════════════════════════════
// Bloc
// ═══════════════════════════════

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AIRepository _repository;
  String? _conversationId;
  final List<ChatMessage> _messages = [];

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<ChatMessageSent>(_onMessageSent);
    on<ChatSessionReset>(_onReset);
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'USER',
      content: event.message,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    emit(ChatLoading(List.from(_messages)));

    final result = await _repository.chat(
      event.message,
      conversationId: _conversationId,
    );

    if (result.success && result.data != null) {
      _conversationId = result.data!.conversationId;
      final aiMsg = ChatMessage(
        id: result.data!.message.id ?? DateTime.now().toString(),
        role: 'ASSISTANT',
        content: result.data!.message.content,
        createdAt: DateTime.tryParse(result.data!.message.createdAt ?? '') ??
            DateTime.now(),
      );
      _messages.add(aiMsg);
      emit(ChatLoaded(List.from(_messages)));
    } else {
      emit(ChatError(
        result.message ?? 'Không thể kết nối đến AI. Vui lòng thử lại.',
        List.from(_messages),
      ));
    }
  }

  void _onReset(ChatSessionReset event, Emitter<ChatState> emit) {
    _messages.clear();
    _conversationId = null;
    emit(ChatInitial());
  }
}
