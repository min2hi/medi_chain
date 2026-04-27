import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadPendingReview()),
      child: const _ReviewQueueView(),
    );
  }
}

class _ReviewQueueView extends StatelessWidget {
  const _ReviewQueueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context),
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
          // Chỉ show SnackBar khi đang xem dữ liệu (tránh hiện cả SnackBar + Center error)
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
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          if (state is AdminError) return _buildError(context, state.message);
          if (state is PendingReviewLoaded) return _buildList(context, state.items);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadPendingReview()),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B), height: 1)),
      );

  Widget _buildList(BuildContext context, List<PendingReviewModel> items) {
    if (items.isEmpty) return _buildEmpty('Không có từ khóa chờ duyệt', LucideIcons.checkCircle2);
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadPendingReview()),
      color: const Color(0xFF3B82F6),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildCard(context, items[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PendingReviewModel item) {
    final confidence = item.confidence != null ? '${(item.confidence! * 100).toStringAsFixed(0)}%' : 'N/A';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: const Text('PENDING', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Text(_timeAgo(item.discoveredAt), style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
            const Spacer(),
            Text('AI: $confidence', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(item.keyword, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          if (item.source != null) ...[
            const SizedBox(height: 4),
            Text('Nguồn: ${item.source}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirm(context, 'Reject từ khóa "${item.keyword}"?', () {
                  context.read<AdminBloc>().add(RejectKeyword(item.id));
                }),
                icon: const Icon(LucideIcons.x, size: 16),
                label: const Text('Từ chối'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirm(context, 'Approve từ khóa "${item.keyword}"?', () {
                  context.read<AdminBloc>().add(ApproveKeyword(item.id));
                }),
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Duyệt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'vừa phát hiện';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildEmpty(String msg, IconData icon) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: const Color(0xFF334155), size: 56),
      const SizedBox(height: 16),
      Text(msg, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
    ]),
  );

  Widget _buildError(BuildContext context, String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 48),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.read<AdminBloc>().add(LoadPendingReview()), child: const Text('Thử lại')),
      ]),
    ),
  );
}
