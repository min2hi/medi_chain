import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

class CombosScreen extends StatelessWidget {
  const CombosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadCombos()),
      child: const _CombosView(),
    );
  }
}

class _CombosView extends StatelessWidget {
  const _CombosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: const Color(0xFFF59E0B),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          if (state is AdminError) return _buildError(context, state.message);
          if (state is CombosLoaded) return _buildList(context, state.combos);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Combo Rules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadCombos()),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B), height: 1)),
      );

  Widget _buildList(BuildContext context, List<ComboRuleModel> combos) {
    if (combos.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.zap, color: Color(0xFF334155), size: 56),
          const SizedBox(height: 16),
          const Text('Chưa có combo rule nào', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Thêm combo rule'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadCombos()),
      color: const Color(0xFFF59E0B),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: combos.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _buildCard(ctx, combos[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ComboRuleModel combo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: combo.isActive ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFF334155),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: combo.isActive ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFF334155).withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              combo.isActive ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                color: combo.isActive ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          if (!combo.isActive)
            TextButton(
              onPressed: () => context.read<AdminBloc>().add(ActivateCombo(combo.id)),
              child: const Text('Kích hoạt', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: combo.symptoms.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
            child: Text(s, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          )).toList(),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(LucideIcons.arrowRight, color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(combo.action, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
        if (combo.description != null) ...[
          const SizedBox(height: 6),
          Text(combo.description!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ]),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final symptomsCtrl = TextEditingController();
    final actionCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final bloc = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tạo Combo Rule', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Nhập các triệu chứng cách nhau bằng dấu phẩy', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 16),
          _buildField(symptomsCtrl, 'Triệu chứng * (VD: sốt, ho, khó thở)', LucideIcons.activity),
          const SizedBox(height: 12),
          _buildField(actionCtrl, 'Hành động * (VD: REFER_EMERGENCY)', LucideIcons.zap),
          const SizedBox(height: 12),
          _buildField(descCtrl, 'Mô tả (tuỳ chọn)', LucideIcons.fileText),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final symptoms = symptomsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                if (symptoms.isEmpty || actionCtrl.text.trim().isEmpty) return;
                bloc.add(CreateCombo(
                  symptoms,
                  actionCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Tạo Combo Rule', style: TextStyle(fontWeight: FontWeight.bold)),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
    ),
  );

  Widget _buildError(BuildContext context, String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 48),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.read<AdminBloc>().add(LoadCombos()), child: const Text('Thử lại')),
      ]),
    ),
  );
}
