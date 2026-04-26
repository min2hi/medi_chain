import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadTelemetry()),
      child: const _TelemetryView(),
    );
  }
}

class _TelemetryView extends StatelessWidget {
  const _TelemetryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFDC2626)),
            );
          }
          if (state is TelemetryLoaded) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
          if (state is AdminError) return _buildError(context, state.message);
          if (state is TelemetryLoaded) return _buildContent(context, state.stats, state.logs);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Telemetry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadTelemetry()),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B), height: 1)),
      );

  Widget _buildContent(BuildContext context, CacheStatsModel stats, List<AuditLogModel> logs) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadTelemetry()),
      color: const Color(0xFF8B5CF6),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cache Stats ──────────────────────────────────────────────────────
          _buildSectionTitle('CACHE & HỆ THỐNG', LucideIcons.database),
          const SizedBox(height: 12),
          _buildCacheCard(context, stats),
          const SizedBox(height: 24),
          // ── Audit Log ───────────────────────────────────────────────────────
          _buildSectionTitle('AUDIT LOG', LucideIcons.clipboardList),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('Chưa có hành động nào được ghi lại', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else
            ...logs.map((log) => _buildLogItem(log)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, color: const Color(0xFF8B5CF6), size: 16),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
  ]);

  Widget _buildCacheCard(BuildContext context, CacheStatsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(children: [
        Row(children: [
          _buildMetricBox('Từ khóa\nan toàn', '${stats.keywordCount}', const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildMetricBox('Combo\nRules', '${stats.comboCount}', const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _buildMetricBox('Cache\nHit Rate',
            stats.hitRate != null ? '${(stats.hitRate! * 100).toStringAsFixed(0)}%' : 'N/A',
            const Color(0xFF8B5CF6)),
        ]),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF334155)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(LucideIcons.clock, color: Color(0xFF64748B), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stats.lastInvalidated != null
                  ? 'Cache reload lần cuối: ${_formatDate(stats.lastInvalidated!)}'
                  : 'Chưa reload cache',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmInvalidate(context),
            icon: const Icon(LucideIcons.rotateCcw, size: 14),
            label: const Text('Reload Cache', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _buildLogItem(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(LucideIcons.shield, color: Color(0xFF8B5CF6), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_formatAction(log.action), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            if (log.adminEmail != null)
              Text('bởi ${log.adminEmail}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            const SizedBox(height: 4),
            Text(_formatDate(log.timestamp), style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  void _confirmInvalidate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Reload Cache', style: TextStyle(color: Colors.white)),
        content: const Text('Force reload toàn bộ safety keywords và combo rules từ database?', style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.read<AdminBloc>().add(InvalidateCache()); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  Widget _buildError(BuildContext context, String msg) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: Color(0xFF94A3B8))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => context.read<AdminBloc>().add(LoadTelemetry()), child: const Text('Thử lại')),
    ]),
  );
}
