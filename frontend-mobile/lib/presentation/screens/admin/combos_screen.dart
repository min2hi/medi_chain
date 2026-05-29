import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

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
      backgroundColor: AdminColors.bg,
      appBar: AdminAppBar(
        title: 'Quy Tắc Tổ Hợp',
        showRefresh: true,
        onRefresh: () => context.read<AdminBloc>().add(LoadCombos()),
      ),
      // FAB — màu teal đồng bộ với primary app
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppTheme.kPrimaryDark,
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
        label: const Text(
          'Thêm Quy Tắc',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AdminColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
              backgroundColor: AdminColors.danger,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator(
              color: AppTheme.kPrimary, strokeWidth: 1.5,
            ));
          }
          if (state is AdminError) return _buildError(context, state.message);
          if (state is CombosLoaded) return _buildList(context, state.combos);
          return const Center(child: CircularProgressIndicator(
            color: AppTheme.kPrimary, strokeWidth: 1.5,
          ));
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ComboRuleModel> combos) {
    if (combos.isEmpty) {
      return const AdminEmptyState(
        icon: LucideIcons.zap,
        message: 'Chưa có quy tắc nào',
        description: 'Nhấn + để tạo quy tắc tổ hợp triệu chứng mới.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadCombos()),
      color: AppTheme.kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: combos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _buildCard(ctx, combos[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ComboRuleModel combo) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar — teal khi active, muted khi inactive
            Container(
              width: 3,
              color: combo.isActive
                  ? AppTheme.kPrimary
                  : AdminColors.textMuted.withValues(alpha: 0.25),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Header ──────────────────────────────────────────────────
                  Row(children: [
                    Icon(
                      LucideIcons.zap,
                      size: 12,
                      color: combo.isActive ? AppTheme.kPrimary : AdminColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      combo.isActive ? 'ĐANG HOẠT ĐỘNG' : 'ĐÃ TẮT',
                      style: TextStyle(
                        color: combo.isActive ? AppTheme.kPrimary : AdminColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    if (!combo.isActive)
                      GestureDetector(
                        onTap: () => context.read<AdminBloc>().add(ActivateCombo(combo.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.kPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Bật quy tắc',
                            style: TextStyle(
                              color: AppTheme.kPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),

                  // ── IF / THEN block ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // NẾU
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(
                          width: 32,
                          child: Text('NẾU', style: TextStyle(
                            color: AdminColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold,
                          )),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: combo.symptoms.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AdminColors.elevated,
                                border: Border.all(color: AdminColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s, style: const TextStyle(
                                color: AdminColors.textPrimary, fontSize: 12,
                              )),
                            )).toList(),
                          ),
                        ),
                      ]),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: AdminColors.border.withValues(alpha: 0.5), height: 1,
                        ),
                      ),

                      // THÌ
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(
                          width: 32,
                          child: Text('THÌ', style: TextStyle(
                            color: AdminColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold,
                          )),
                        ),
                        Expanded(
                          child: Text(
                            combo.action,
                            style: const TextStyle(
                              color: AdminColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),

                  // ── Description ──────────────────────────────────────────────
                  if (combo.description != null && combo.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      combo.description!,
                      style: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final symptomsCtrl = TextEditingController();
    final actionCtrl   = TextEditingController();
    final descCtrl     = TextEditingController();
    final bloc         = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AdminColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tạo Quy Tắc Tổ Hợp',
              style: TextStyle(
                color: AdminColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhập các triệu chứng cách nhau bằng dấu phẩy',
              style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
            ),
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
                  final symptoms = symptomsCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  if (symptoms.isEmpty || actionCtrl.text.trim().isEmpty) return;
                  bloc.add(CreateCombo(
                    symptoms,
                    actionCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tạo Quy Tắc', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AdminColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AdminColors.textMuted),
      prefixIcon: Icon(icon, color: AdminColors.textMuted, size: 18),
      filled: true,
      fillColor: AdminColors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.kPrimary, width: 1.5),
      ),
    ),
  );

  Widget _buildError(BuildContext context, String msg) => AdminErrorState(
    message: msg,
    onRetry: () => context.read<AdminBloc>().add(LoadCombos()),
  );
}
