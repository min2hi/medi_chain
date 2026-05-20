import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadKeywords()),
      child: const _KeywordsView(),
    );
  }
}

class _KeywordsView extends StatelessWidget {
  const _KeywordsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AdminAppBar(
        title: 'Từ Khóa An Toàn',
        showRefresh: true,
        onRefresh: () => context.read<AdminBloc>().add(LoadKeywords()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AdminColors.success,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AdminColors.success),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AdminColors.danger),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: AdminColors.success, strokeWidth: 1.5));
          if (state is AdminError) return AdminErrorState(message: state.message, onRetry: () => context.read<AdminBloc>().add(LoadKeywords()));
          if (state is KeywordsLoaded) return _buildList(context, state.keywords);
          return const Center(child: CircularProgressIndicator(color: AdminColors.success, strokeWidth: 1.5));
        },
      ),
    );
  }


  Widget _buildList(BuildContext context, List<SafetyKeywordModel> keywords) {
    if (keywords.isEmpty) {
      return const AdminEmptyState(
        icon: LucideIcons.book,
        message: 'Chưa có từ khóa nào',
        description: 'Nhấn nút + để thêm từ khóa mới.',
      );
    }
    final active   = keywords.where((k) => k.isActive).toList();
    final inactive = keywords.where((k) => !k.isActive).toList();
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadKeywords()),
      color: const Color(0xFF10B981),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isNotEmpty) ...[
            _buildSectionHeader('ĐANG HOẠT ĐỘNG (${active.length})', const Color(0xFF10B981)),
            const SizedBox(height: 8),
            ...active.map((k) => _KeywordCard(keyword: k, onEdit: () => _showEditDialog(context, k))),
          ],
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('ĐÃ TẮT (${inactive.length})', const Color(0xFF64748B)),
            const SizedBox(height: 8),
            ...inactive.map((k) => _KeywordCard(keyword: k, onEdit: () => _showEditDialog(context, k))),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );

  void _showEditDialog(BuildContext context, SafetyKeywordModel k) {
    final keywordCtrl  = TextEditingController(text: k.keyword);
    final guidelineCtrl = TextEditingController(text: k.guideline ?? '');
    final bloc = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.pencil, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            const Text('Chỉnh sửa từ khóa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          _buildField(keywordCtrl, 'Từ khóa *', LucideIcons.shield),
          const SizedBox(height: 12),
          _buildField(guidelineCtrl, 'Hướng dẫn lâm sàng (tuỳ chọn)', LucideIcons.fileText),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (keywordCtrl.text.trim().isEmpty) return;
                bloc.add(UpdateKeyword(k.id, keyword: keywordCtrl.text.trim(),
                    guideline: guidelineCtrl.text.trim().isEmpty ? null : guidelineCtrl.text.trim()));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final keywordCtrl  = TextEditingController();
    final categoryCtrl = TextEditingController();
    final guidelineCtrl = TextEditingController();
    final bloc = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Thêm từ khóa mới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildField(keywordCtrl, 'Từ khóa *', LucideIcons.shield),
          const SizedBox(height: 12),
          _buildField(categoryCtrl, 'Danh mục (tuỳ chọn)', LucideIcons.tag),
          const SizedBox(height: 12),
          _buildField(guidelineCtrl, 'Hướng dẫn (tuỳ chọn)', LucideIcons.fileText),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (keywordCtrl.text.trim().isEmpty) return;
                bloc.add(CreateKeyword(keywordCtrl.text.trim(),
                    category: categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                    guideline: guidelineCtrl.text.trim().isEmpty ? null : guidelineCtrl.text.trim()));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Tạo từ khóa', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      prefixIcon: Icon(icon, color: const Color(0xFF475569), size: 18),
      filled: true, fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
    ),
  );
}

// ─── Keyword Card — Stateful để optimistic toggle ────────────────────────────
// Pattern: Notion / Linear — cập nhật local state ngay lập tức,
// sync với server state khi BLoC emit KeywordsLoaded.

class _KeywordCard extends StatefulWidget {
  final SafetyKeywordModel keyword;
  final VoidCallback onEdit;
  const _KeywordCard({required this.keyword, required this.onEdit});

  @override
  State<_KeywordCard> createState() => _KeywordCardState();
}

class _KeywordCardState extends State<_KeywordCard> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = widget.keyword.isActive;
  }

  @override
  void didUpdateWidget(_KeywordCard old) {
    super.didUpdateWidget(old);
    // Sync với server state sau khi BLoC xác nhận
    _active = widget.keyword.isActive;
  }

  void _toggle(BuildContext context) {
    HapticFeedback.lightImpact();
    setState(() => _active = !_active);
    context.read<AdminBloc>().add(ToggleKeyword(widget.keyword.id, activate: _active));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _active ? const Color(0xFF10B981).withOpacity(0.45) : const Color(0xFF2D3748),
          width: _active ? 1.5 : 1.0,
        ),
        boxShadow: _active
            ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(children: [
        // Status dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 7, height: 7,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _active ? const Color(0xFF10B981) : const Color(0xFF475569),
          ),
        ),
        // Content
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // maxLines: 1 — Cerner pattern: keywords are short phrases.
            // LLM-detected keywords are full sentences → must truncate.
            Text(
              widget.keyword.keyword,
              style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.keyword.category != null)
              Text(
                widget.keyword.category!,
                style: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
              ),
            if (widget.keyword.guideline != null)
              Text(widget.keyword.guideline!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Edit
        IconButton(
          icon: const Icon(LucideIcons.pencil, size: 16, color: Color(0xFF475569)),
          tooltip: 'Chỉnh sửa',
          onPressed: widget.onEdit,
          splashRadius: 18,
        ),
        // Custom smooth toggle — không dùng Switch vì lag và mờ
        GestureDetector(
          onTap: () => _toggle(context),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: 46, height: 26,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: _active ? const Color(0xFF10B981) : const Color(0xFF334155),
              boxShadow: _active
                  ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.35), blurRadius: 8)]
                  : null,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _active ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
