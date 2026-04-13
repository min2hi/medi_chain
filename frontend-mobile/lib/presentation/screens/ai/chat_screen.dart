import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';
import 'package:medi_chain_mobile/logic/chat/chat_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';

// ─────────────────────────────────────────────────────
// Design tokens — đồng nhất với web /tu-van
// ─────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D9488);
const _kSurface = Colors.white;
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);
const _kTextPrimary = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF64748B);
const _kTextMuted = Color(0xFF94A3B8);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _inputFocused = false;

  // Welcome screen floating animation
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

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
    _focusNode.unfocus();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _floatController.dispose();
    super.dispose();
  }

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
          backgroundColor: _kBg,
          appBar: _buildAppBar(blocContext),
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
                        vertical: 16,
                      ),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isLoading && index == messages.length) {
                          return _buildTypingIndicator();
                        }
                        final msg = messages[index];
                        final prevMsg =
                            index > 0 ? messages[index - 1] : null;
                        final nextMsg = index < messages.length - 1
                            ? messages[index + 1]
                            : null;
                        final isSameRoleAsPrev =
                            prevMsg?.isUser == msg.isUser;
                        final isLastInGroup =
                            nextMsg == null || nextMsg.isUser != msg.isUser;

                        return _buildMessageBubble(
                          msg,
                          isSameRoleAsPrev: isSameRoleAsPrev,
                          isLastInGroup: isLastInGroup,
                        );
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
                          horizontal: 16, vertical: 4),
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

              Builder(builder: (bc) => _buildInputArea(bc)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // AppBar — đồng nhất với web header
  // ─────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext blocContext) {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      titleSpacing: 14,
      title: Row(
        children: [
          // "M" gradient avatar — giống web
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'M',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              // Green online dot
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kSurface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bác sĩ Medi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Trực tuyến 24/7',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.clock, size: 20),
          color: _kTextMuted,
          tooltip: 'Lịch sử trò chuyện',
          onPressed: () => _showHistory(blocContext),
        ),
        IconButton(
          icon: const Icon(LucideIcons.edit2, size: 20),
          color: _kTextMuted,
          onPressed: () =>
              blocContext.read<ChatBloc>().add(ChatSessionReset()),
          tooltip: 'Cuộc trò chuyện mới',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Welcome state — đồng nhất với web
  // ─────────────────────────────────────────────────────

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          // Animated "M" logo — giống web floating animation
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            ),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'M',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
                letterSpacing: -0.6,
              ),
              children: [
                TextSpan(text: 'Chào mừng đến với '),
                TextSpan(
                  text: 'Medi',
                  style: TextStyle(color: _kPrimary),
                ),
                TextSpan(text: ' ✨'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mình là bác sĩ ảo hỗ trợ tư vấn sức khỏe 24/7.\nHỏi bất cứ điều gì về sức khỏe, thuốc hoặc triệu chứng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: _kTextSecondary,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 32),

          // Divider label "Gợi ý cho bạn"
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, _kBorder],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'GỢI Ý CHO BẠN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kTextMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kBorder, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSuggestionChip('Thuốc tôi đang dùng có tương tác gì không?'),
          _buildSuggestionChip('Tôi bị đau đầu và sốt nhẹ, nên làm gì?'),
          _buildSuggestionChip('Paracetamol uống liều bao nhiêu là an toàn?'),
          _buildSuggestionChip('Phân tích sức khỏe của tôi dựa trên hồ sơ'),

          const SizedBox(height: 24),
          // Security note — giống web
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck,
                  size: 13, color: _kTextMuted.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'Mọi thông tin trò chuyện đều được bảo mật',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _kTextMuted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kTextPrimary,
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 15, color: _kTextMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Message bubble — với grouping + timestamp
  // ─────────────────────────────────────────────────────

  Widget _buildMessageBubble(
    ChatMessage msg, {
    required bool isSameRoleAsPrev,
    required bool isLastInGroup,
  }) {
    final isUser = msg.isUser;
    final topPadding = isSameRoleAsPrev ? 3.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 2 : 0, top: topPadding),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // AI avatar — ẩn nếu same role as prev (message grouping)
              if (!isUser) ...[
                SizedBox(
                  width: 32,
                  height: 32,
                  child: isSameRoleAsPrev
                      ? const SizedBox() // ẩn avatar nếu cùng nhóm
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'M',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],

              // Bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? _kPrimary : _kSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(
                          isUser ? 20 : (isSameRoleAsPrev ? 5 : 5)),
                      bottomRight: Radius.circular(
                          isUser ? (isSameRoleAsPrev ? 5 : 5) : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: _kBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _kPrimary.withValues(alpha: 0.20)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
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
                              height: 1.65,
                              color: Color(0xFF334155),
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _kTextPrimary,
                            ),
                            code: const TextStyle(
                              backgroundColor: Color(0xFFF1F5F9),
                              fontSize: 13,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              border: Border(
                                left: BorderSide(
                                    color: _kPrimary, width: 3),
                              ),
                            ),
                            h2: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kTextPrimary,
                            ),
                          ),
                        ),
                ),
              ),

              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // Timestamp — chỉ hiện cuối mỗi group
          if (isLastInGroup) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 44,
                right: isUser ? 8 : 0,
              ),
              child: Text(
                _formatTime(msg.createdAt.toIso8601String()),
                style: TextStyle(
                  fontSize: 10.5,
                  color: _kTextMuted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ─────────────────────────────────────────────────────
  // Typing indicator
  // ─────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'M',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
              ),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Input area — với focus ring + send disabled state
  // ─────────────────────────────────────────────────────

  Widget _buildInputArea(BuildContext blocContext) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input wrapper — border thay đổi khi focus
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _inputFocused ? _kSurface : _kBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _inputFocused ? _kPrimary : _kBorder,
                  width: _inputFocused ? 2 : 1.5,
                ),
                boxShadow: _inputFocused
                    ? [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.12),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _onSend(blocContext),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Nhắn tin cho Medi...',
                        hintStyle: TextStyle(color: _kTextMuted, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(18, 12, 8, 12),
                        filled: false,
                      ),
                      style: const TextStyle(
                          fontSize: 15, color: _kTextPrimary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: _buildSendButton(blocContext),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Footer note — giống web
            Text(
              'Medi có thể trả lời chưa chính xác. Hỏi ý kiến bác sĩ khi cần.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: _kTextMuted.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext blocContext) {
    final hasText = _controller.text.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: hasText ? _kPrimary : _kBorder,
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasText
            ? [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasText ? () => _onSend(blocContext) : null,
          child: const Center(
            child: Icon(LucideIcons.send, size: 18, color: Colors.white),
          ),
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
          color: _kBg,
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(LucideIcons.clock,
                        size: 17, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Lịch sử trò chuyện',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // List
            Expanded(
              child: FutureBuilder<ConversationListResponse>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    // Skeleton shimmer thay CircularProgressIndicator
                    return const AppSkeletonChatHistory();
                  }
                  final list = snap.data?.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.messageSquare,
                              size: 48,
                              color: _kTextMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(
                                color: _kTextMuted, fontSize: 14),
                          ),
                        ],
                      ),
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
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'M',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white),
          ),
        ),
        title: Text(
          conv.title?.isNotEmpty == true ? conv.title! : 'Cuộc trò chuyện',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _kTextPrimary,
          ),
        ),
        subtitle: Text(
          dateStr,
          style: const TextStyle(fontSize: 12, color: _kTextMuted),
        ),
        trailing:
            const Icon(LucideIcons.chevronRight, size: 16, color: _kTextMuted),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Conversation Detail Screen
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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          conversation.title?.isNotEmpty == true
              ? conversation.title!
              : 'Chi tiết cuộc trò chuyện',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 17, color: _kTextPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: FutureBuilder<MessageListResponse>(
        future: repository.getConversationMessages(conversation.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppSkeletonList(count: 5);
          }
          final messages = snap.data?.data ?? [];
          if (messages.isEmpty) {
            return const Center(
              child: Text('Không có tin nhắn nào',
                  style: TextStyle(color: _kTextMuted)),
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
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'M',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? _kPrimary : _kSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 20),
                ),
                border: isUser ? null : Border.all(color: _kBorder, width: 1.5),
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
                          color: Colors.white, fontSize: 15, height: 1.5))
                  : MarkdownBody(
                      data: content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            fontSize: 15,
                            height: 1.65,
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
// Typing dots animation — teal dots giống web
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
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.18).clamp(0.0, 1.0);
            final dy = -5.0 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: _kPrimary,
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
