import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

class AccessLogsScreen extends StatelessWidget {
  const AccessLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadAccessLogs()),
      child: const _AccessLogsView(),
    );
  }
}

class _AccessLogsView extends StatelessWidget {
  const _AccessLogsView();

  // Màu theo HTTP method
  static const _methodColors = {
    'GET':    Color(0xFF3B82F6),
    'POST':   Color(0xFF10B981),
    'PATCH':  Color(0xFFF59E0B),
    'PUT':    Color(0xFFF59E0B),
    'DELETE': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)));
          }
          if (state is AdminError) return _buildError(context, state.message);
          if (state is AccessLogsLoaded) return _buildContent(context, state.data);
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
        title: const Text('Access Logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadAccessLogs()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1E293B), height: 1),
        ),
      );

  Widget _buildContent(BuildContext context, AccessLogData data) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadAccessLogs()),
      color: const Color(0xFFEC4899),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header: ngày + tổng ──────────────────────────────────────────
          Row(children: [
            const Icon(LucideIcons.calendar, color: Color(0xFF64748B), size: 14),
            const SizedBox(width: 6),
            Text(data.date, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${data.stats.total} requests',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Stats row ─────────────────────────────────────────────────────
          _buildStatsRow(data.stats),
          const SizedBox(height: 20),

          // ── Log entries ───────────────────────────────────────────────────
          if (data.entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(children: [
                  const Icon(LucideIcons.fileX, color: Color(0xFF334155), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Không có log cho ngày ${data.date}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ]),
              ),
            )
          else
            ...data.entries.map((e) => _buildLogRow(e)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AccessLogStats s) {
    return Row(children: [
      _statChip(label: 'Total',  value: '${s.total}',      color: const Color(0xFF3B82F6)),
      const SizedBox(width: 8),
      _statChip(label: '4xx',   value: '${s.errors4xx}',  color: const Color(0xFFF59E0B)),
      const SizedBox(width: 8),
      _statChip(label: '5xx',   value: '${s.errors5xx}',  color: const Color(0xFFEF4444)),
      const SizedBox(width: 8),
      _statChip(label: 'Avg',   value: '${s.avgMs}ms',    color: const Color(0xFF10B981)),
    ]);
  }

  Widget _statChip({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildLogRow(AccessLogEntry e) {
    final methodColor = _methodColors[e.method] ?? const Color(0xFF94A3B8);
    final isError = e.status >= 400;
    final statusColor = e.status >= 500
        ? const Color(0xFFEF4444)
        : e.status >= 400
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    // Chỉ lấy giờ:phút:giây từ ISO timestamp
    final timePart = e.timestamp.length >= 19
        ? e.timestamp.substring(11, 19) // HH:mm:ss
        : e.timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFF1C1017) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFF7F1D1D).withOpacity(0.5) : const Color(0xFF334155),
        ),
      ),
      child: Row(children: [
        // Method badge
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            e.method,
            textAlign: TextAlign.center,
            style: TextStyle(color: methodColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),

        // Path + user
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              e.path,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${e.userId}  ·  ${e.ip}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        const SizedBox(width: 8),

        // Status + time + duration
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${e.status}',
            style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(timePart, style: const TextStyle(color: Color(0xFF475569), fontSize: 9)),
          Text('${e.durationMs}ms', style: const TextStyle(color: Color(0xFF475569), fontSize: 9)),
        ]),
      ]),
    );
  }

  Widget _buildError(BuildContext context, String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AdminBloc>().add(LoadAccessLogs()),
              child: const Text('Thử lại'),
            ),
          ]),
        ),
      );
}
