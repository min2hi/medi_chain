import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';
import 'package:medi_chain_mobile/logic/chat/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend(BuildContext blocContext) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    blocContext.read<ChatBloc>().add(ChatMessageSent(text));
    _controller.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // History bottom sheet
  // ──────────────────────────────────────────────

  void _showHistory(BuildContext blocContext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatHistorySheet(
        repository: getIt<AIRepository>(),
        onSelectConversation: (conv) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ConversationDetailScreen(
                conversation: conv,
                repository: getIt<AIRepository>(),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: Builder(
        builder: (blocContext) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'mediAI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.clock, size: 20),
                tooltip: 'Lịch sử trò chuyện',
                onPressed: () => _showHistory(blocContext),
              ),
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw, size: 20),
                onPressed: () =>
                    blocContext.read<ChatBloc>().add(ChatSessionReset()),
                tooltip: 'Cuộc trò chuyện mới',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is ChatLoaded || state is ChatError) {
                      _scrollToBottom();
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatInitial) return _buildWelcomeState();

                    final List<ChatMessage> messages = switch (state) {
                      ChatLoading() => state.messages,
                      ChatLoaded() => state.messages,
                      ChatError() => state.messages,
                      _ => [],
                    };

                    final isLoading = state is ChatLoading;

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isLoading && index == messages.length) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(messages[index]);
                      },
                    );
                  },
                ),
              ),
              // Error banner
              BlocBuilder<ChatBloc, ChatState>(
                builder: (ctx, state) {
                  if (state is ChatError) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle,
                              size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Builder(
                  builder: (bc) => _buildInputArea(bc)),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Welcome state
  // ──────────────────────────────────────────────

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDFA),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.messageSquare,
                size: 64, color: Color(0xFF14B8A6)),
          ),
          const SizedBox(height: 24),
          const Text(
            'mediAI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Text(
              'Trợ lý sức khỏe thông minh',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14B8A6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đặt câu hỏi về sức khỏe, triệu chứng, hoặc thuốc đang dùng. AI sẽ phân tích dựa trên hồ sơ của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _buildSuggestionChip('Thuốc tôi đang dùng có tương tác gì?'),
          _buildSuggestionChip('Tôi bị đau đầu và sốt nhẹ, nên làm gì?'),
          _buildSuggestionChip('Paracetamol uống liều bao nhiêu là an toàn?'),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Builder(
      builder: (blocContext) => GestureDetector(
        onTap: () {
          _controller.text = text;
          _onSend(blocContext);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.messageSquare,
                  size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF475569))),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Chat bubble
  // ──────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF14B8A6),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.stethoscope,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF14B8A6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      msg.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFF334155),
                        ),
                        code: const TextStyle(
                          backgroundColor: Color(0xFFF1F5F9),
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Typing indicator
  // ──────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF14B8A6),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.stethoscope,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Input area
  // ──────────────────────────────────────────────

  Widget _buildInputArea(BuildContext blocContext) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSend(blocContext),
                decoration: InputDecoration(
                  hintText: 'Hỏi về sức khỏe hoặc thuốc...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _onSend(blocContext),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.send,
                    size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Chat History Bottom Sheet
// ══════════════════════════════════════════════════════════════════════

class _ChatHistorySheet extends StatefulWidget {
  final AIRepository repository;
  final void Function(ConversationModel) onSelectConversation;

  const _ChatHistorySheet({
    required this.repository,
    required this.onSelectConversation,
  });

  @override
  State<_ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends State<_ChatHistorySheet> {
  late Future<ConversationListResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getConversations(type: 'CHAT');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.clock,
                        size: 18, color: Color(0xFF14B8A6)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Lịch sử trò chuyện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // List
            Expanded(
              child: FutureBuilder<ConversationListResponse>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data?.data ?? [];
                  if (list.isEmpty) {
                    return _buildEmpty(
                      icon: LucideIcons.messageSquare,
                      message: 'Chưa có cuộc trò chuyện nào',
                    );
                  }
                  return ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ConversationTile(
                      conv: list[i],
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelectConversation(list[i]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Conversation list tile
// ──────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        return DateFormat('HH:mm').format(dt);
      }
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(conv.lastMessageAt ?? conv.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDFA),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.messageSquare,
              size: 18, color: Color(0xFF14B8A6)),
        ),
        title: Text(
          conv.title?.isNotEmpty == true
              ? conv.title!
              : 'Cuộc trò chuyện',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          dateStr,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        trailing: const Icon(LucideIcons.chevronRight,
            size: 16, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Conversation Detail Screen (read-only view of a past conversation)
// ══════════════════════════════════════════════════════════════════════

class _ConversationDetailScreen extends StatelessWidget {
  final ConversationModel conversation;
  final AIRepository repository;

  const _ConversationDetailScreen({
    required this.conversation,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          conversation.title?.isNotEmpty == true
              ? conversation.title!
              : 'Chi tiết cuộc trò chuyện',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: FutureBuilder<MessageListResponse>(
        future: repository.getConversationMessages(conversation.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final messages = snap.data?.data ?? [];
          if (messages.isEmpty) {
            return const Center(
              child: Text('Không có tin nhắn nào',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final msg = messages[i];
              final isUser = msg.role == 'USER';
              return _HistoryMessageBubble(
                  content: msg.content, isUser: isUser);
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Read-only message bubble (history view)
// ──────────────────────────────────────────────

class _HistoryMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const _HistoryMessageBubble(
      {required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6), shape: BoxShape.circle),
              child: const Icon(LucideIcons.stethoscope,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF14B8A6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: isUser
                  ? Text(content,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5))
                  : MarkdownBody(
                      data: content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF334155)),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Typing dots animation
// ══════════════════════════════════════════════════════════════════════

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double t =
                (_controller.value - i * 0.15).clamp(0.0, 1.0);
            final double dy =
                -4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
