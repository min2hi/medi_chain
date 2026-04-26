import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF10B981)),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFDC2626)),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          if (state is AdminError) return _buildError(context, state.message);
          if (state is KeywordsLoaded) return _buildList(context, state.keywords);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Safety Keywords', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadKeywords()),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B), height: 1)),
      );

  Widget _buildList(BuildContext context, List<SafetyKeywordModel> keywords) {
    if (keywords.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.book, color: Color(0xFF334155), size: 56),
          const SizedBox(height: 16),
          const Text('Chưa có từ khóa nào', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Thêm từ khóa'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    final active = keywords.where((k) => k.isActive).toList();
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
            ...active.map((k) => _buildKeywordCard(context, k)),
          ],
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('ĐÃ TẮT (${inactive.length})', const Color(0xFF64748B)),
            const SizedBox(height: 8),
            ...inactive.map((k) => _buildKeywordCard(context, k)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );

  Widget _buildKeywordCard(BuildContext context, SafetyKeywordModel k) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: k.isActive ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF334155)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k.keyword, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            if (k.category != null)
              Text(k.category!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ]),
        ),
        Switch(
          value: k.isActive,
          onChanged: (val) => context.read<AdminBloc>().add(ToggleKeyword(k.id, activate: val)),
          activeColor: const Color(0xFF10B981),
          inactiveThumbColor: const Color(0xFF475569),
          inactiveTrackColor: const Color(0xFF1E293B),
        ),
      ]),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final keywordCtrl = TextEditingController();
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
                bloc.add(CreateKeyword(
                  keywordCtrl.text.trim(),
                  category: categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                  guideline: guidelineCtrl.text.trim().isEmpty ? null : guidelineCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
    ),
  );

  Widget _buildError(BuildContext context, String msg) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: Color(0xFF94A3B8))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => context.read<AdminBloc>().add(LoadKeywords()), child: const Text('Thử lại')),
    ]),
  );
}
