import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

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
      backgroundColor: AdminColors.bg,
      appBar: AdminAppBar(
        title: 'GiÃ¡m SÃ¡t Há»‡ Thá»‘ng',
        showRefresh: true,
        onRefresh: () => context.read<AdminBloc>().add(LoadTelemetry()),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                backgroundColor: AdminColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is TelemetryLoaded) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: AdminColors.purple));
          if (state is AdminError) return AdminErrorState(message: state.message, onRetry: () => context.read<AdminBloc>().add(LoadTelemetry()));
          if (state is TelemetryLoaded) return _buildContent(context, state.stats, state.logs);
          return const Center(child: CircularProgressIndicator(color: AdminColors.purple));
        },
      ),
    );
  }



  Widget _buildContent(BuildContext context, CacheStatsModel stats, List<AuditLogModel> logs) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadTelemetry()),
      color: AdminColors.purple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // â”€â”€ Cache Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _buildSectionTitle('CACHE & Há»† THá»NG', LucideIcons.database),
          const SizedBox(height: 12),
          _buildCacheCard(context, stats),
          const SizedBox(height: 24),
          // â”€â”€ Audit Log â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _buildSectionTitle('AUDIT LOG', LucideIcons.clipboardList),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('ChÆ°a cÃ³ hÃ nh Ä‘á»™ng nÃ o Ä‘Æ°á»£c ghi láº¡i', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else
            ...logs.map((log) => _buildLogItem(log)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(title, style: const TextStyle(
      color: AdminColors.textMuted, fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 1.2,
    )),
  );

  Widget _buildCacheCard(BuildContext context, CacheStatsModel stats) {
    final hitRateStr = stats.hitRate != null
        ? '${(stats.hitRate! * 100).toStringAsFixed(1)}%'
        : 'N/A';
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(children: [
        // Metrics flat table â€” Datadog/Grafana style
        _metricRow('Tá»« khÃ³a an toÃ n',  '${stats.keywordCount}',  AdminColors.success),
        Container(height: 1, color: AdminColors.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
        _metricRow('Combo Rules',       '${stats.comboCount}',    AdminColors.warning),
        Container(height: 1, color: AdminColors.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
        _metricRow('Cache Hit Rate',    hitRateStr,               AdminColors.aiPrimary),
        // Divider + reload row
        Container(height: 1, color: AdminColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            const Icon(LucideIcons.clock, color: AdminColors.textMuted, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stats.lastInvalidated != null
                    ? 'Reload láº§n cuá»‘i: ${_formatDate(stats.lastInvalidated!)}'
                    : 'ChÆ°a reload cache',
                style: const TextStyle(color: AdminColors.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: () => _confirmInvalidate(context),
                icon: const Icon(LucideIcons.rotateCcw, size: 12),
                label: const Text('Reload', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _metricRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(
        color: AdminColors.textSecondary, fontSize: 13,
      ))),
      Text(value, style: TextStyle(
        color: valueColor, fontSize: 13, fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      )),
    ]),
  );

  Widget _buildLogItem(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.border, width: 0.5)),
      ),
      child: Row(children: [
        // Dot chá»‰ thá»‹ â€” khÃ´ng cÃ³ circle container
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: const BoxDecoration(
            color: AdminColors.purple, shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_formatAction(log.action), style: const TextStyle(
              color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 2),
            Row(children: [
              if (log.adminEmail != null) ...[          
                Text('${log.adminEmail}', style: const TextStyle(
                  color: AdminColors.textMuted, fontSize: 11,
                )),
                const Text(' Â· ', style: TextStyle(color: AdminColors.textMuted, fontSize: 11)),
              ],
              Text(_formatDate(log.timestamp), style: const TextStyle(
                color: AdminColors.textMuted, fontSize: 11,
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _confirmInvalidate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.overlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reload Cache', style: TextStyle(color: AdminColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        content: const Text(
          'Force reload toÃ n bá»™ safety keywords vÃ  combo rules tá»« database?',
          style: TextStyle(color: AdminColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Há»§y', style: TextStyle(color: AdminColors.textMuted, fontSize: 13))),
          TextButton(
            onPressed: () { Navigator.pop(context); context.read<AdminBloc>().add(InvalidateCache()); },
            child: const Text('Reload', style: TextStyle(color: AdminColors.purple, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vá»«a xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phÃºt trÆ°á»›c';
    if (diff.inDays < 1) return '${diff.inHours} giá» trÆ°á»›c';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}
