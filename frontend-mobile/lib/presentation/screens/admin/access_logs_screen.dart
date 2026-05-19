import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

// â”€â”€ PHI Audit Trail Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Theo HIPAA Â§ 164.312(b) â€” Audit Controls: "Implement hardware, software,
// and/or procedural mechanisms that record and examine activity in information
// systems that contain or use ePHI."
//
// Thay vÃ¬ chá»‰ hiá»ƒn thá»‹ raw HTTP log (method + path + IP), mÃ n hÃ¬nh nÃ y táº­p
// trung vÃ o cÃ¡c cÃ¢u há»i mÃ  auditor y táº¿ thá»±c sá»± cáº§n tráº£ lá»i:
//   "Ai xem há»“ sÆ¡ cá»§a bá»‡nh nhÃ¢n nÃ o, lÃºc máº¥y giá», vÃ  tá»« thiáº¿t bá»‹ nÃ o?"
//
// Tham kháº£o: Epic Systems Audit Log, Cerner Millennium Access Audit,
// NHS England Access Control Policy (2023).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AccessLogsScreen extends StatelessWidget {
  const AccessLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadAccessLogs()),
      child: const _AuditTrailView(),
    );
  }
}

class _AuditTrailView extends StatefulWidget {
  const _AuditTrailView();

  @override
  State<_AuditTrailView> createState() => _AuditTrailViewState();
}

class _AuditTrailViewState extends State<_AuditTrailView> {
  // Bá»™ lá»c: null = táº¥t cáº£
  _AuditFilter _filter = _AuditFilter.all;
  String   _search = '';
  DateTime _selectedDate = DateTime.now();  // Date picker state (Epic pattern)

  /// Má»Ÿ date picker vÃ  reload náº¿u user chá»n ngÃ y khÃ¡c.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || picked == _selectedDate) return;
    setState(() => _selectedDate = picked);
    // Reload data cho ngÃ y má»›i â€” format YYYY-MM-DD
    final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (mounted) context.read<AdminBloc>().add(LoadAccessLogs(date: dateStr));
  }

  /// Export entries hiá»‡n táº¡i sang CSV vÃ  copy vÃ o clipboard.
  /// Pattern: Robinhood transaction export â€” zero dependency, instant.
  void _exportToCsv(List<AccessLogEntry> entries) {
    final header = 'timestamp,userId,method,path,status,ip,durationMs';
    final rows = entries.map((e) =>
      '${e.timestamp},${e.userId},${e.method},"${e.path}",${e.status},${e.ip},${e.durationMs}'
    ).join('\n');
    final csv = '$header\n$rows';
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('âœ“ ÄÃ£ copy ${entries.length} dÃ²ng CSV vÃ o clipboard'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      // AppBar náº±m trong build() Ä‘á»ƒ rebuild khi _selectedDate thay Ä‘á»•i
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
          color: AdminColors.textSecondary,
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nháº­t KÃ½ Hoáº¡t Äá»™ng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Ai xem gÃ¬ Â· LÃºc nÃ o Â· Tá»« Ä‘Ã¢u', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Date Picker button â€” rebuild vá»›i date má»›i khi setState()
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(LucideIcons.calendar, color: Color(0xFF94A3B8), size: 15),
            label: Text(
              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
          // Refresh
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 18),
            onPressed: () => context.read<AdminBloc>().add(LoadAccessLogs()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AdminColors.border, height: 1),
        ),
      ),
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
            return const Center(child: CircularProgressIndicator(color: AdminColors.aiPrimary));
          }
          if (state is AdminError) return AdminErrorState(message: state.message, onRetry: () => context.read<AdminBloc>().add(LoadAccessLogs()));
          if (state is AccessLogsLoaded) return _buildContent(state.data);
          return const Center(child: CircularProgressIndicator(color: AdminColors.aiPrimary));
        },
      ),
    );
  }


  Widget _buildContent(AccessLogData data) {
    final events   = _toAuditEvents(data.entries);
    final filtered = _applyFilter(events);

    return Column(
      children: [
        // Summary bar â€” flat, khÃ´ng cÃ³ color box
        _buildSummaryBar(data.stats, events),
        
        // Filter tabs
        _buildFilterRow(),
        
        // Search + Export
        Row(children: [
          Expanded(child: _buildSearchBar()),
          if (data.entries.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.clipboardCopy, color: AdminColors.textMuted, size: 18),
              tooltip: 'Copy CSV vÃ o clipboard',
              onPressed: () => _exportToCsv(data.entries),
            ),
        ]),
        
        // Divider
        Container(height: 1, color: AdminColors.border),
        
        // Event list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => context.read<AdminBloc>().add(LoadAccessLogs()),
            color: AdminColors.aiPrimary,
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildEventRow(filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Convert raw HTTP logs â†’ semantic PHI events â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ÄÃ¢y lÃ  Ä‘iá»ƒm cá»‘t lÃµi: thay vÃ¬ "GET /records", ta hiá»ƒu lÃ 
  // "User u_133ae9e7 Ä‘Ã£ xem danh sÃ¡ch há»“ sÆ¡ bá»‡nh Ã¡n"
  List<_AuditEvent> _toAuditEvents(List<AccessLogEntry> entries) {
    return entries.map((e) {
      final action = _classifyAction(e.method, e.path);
      final risk = _assessRisk(e.method, e.path, e.status);
      final timePart = e.timestamp.length >= 19 ? e.timestamp.substring(11, 19) : e.timestamp;
      return _AuditEvent(
        userId: e.userId,
        ip: e.ip,
        time: timePart,
        action: action.label,
        detail: '${e.method} ${e.path}',
        icon: action.icon,
        color: action.color,
        risk: risk,
        status: e.status,
        durationMs: e.durationMs,
        isError: e.status >= 400,
      );
    }).toList();
  }

  _ActionMeta _classifyAction(String method, String path) {
    // PHI-sensitive endpoints â€” quan trá»ng nháº¥t
    if (path.contains('/records') && method == 'GET') {
      return const _ActionMeta('Xem há»“ sÆ¡ bá»‡nh Ã¡n', LucideIcons.fileText, AdminColors.aiPrimary);
    }
    if (path.contains('/records') && method == 'POST') {
      return const _ActionMeta('Táº¡o há»“ sÆ¡ bá»‡nh Ã¡n', LucideIcons.filePlus, AdminColors.success);
    }
    if (path.contains('/records') && (method == 'PATCH' || method == 'PUT')) {
      return const _ActionMeta('Chá»‰nh sá»­a há»“ sÆ¡ bá»‡nh Ã¡n', LucideIcons.fileEdit, AdminColors.warning);
    }
    if (path.contains('/records') && method == 'DELETE') {
      return const _ActionMeta('XÃ³a há»“ sÆ¡ bá»‡nh Ã¡n', LucideIcons.fileX, AdminColors.danger);
    }
    if (path.contains('/medicines') || path.contains('/medicine')) {
      return const _ActionMeta('Truy cáº­p dá»¯ liá»‡u thuá»‘c', LucideIcons.pill, AdminColors.purple);
    }
    if (path.contains('/appointments')) {
      return const _ActionMeta('Truy cáº­p lá»‹ch háº¹n', LucideIcons.calendarCheck, AdminColors.aiPrimary);
    }
    if (path.contains('/conversations') || path.contains('/messages')) {
      return const _ActionMeta('Truy cáº­p cuá»™c há»™i thoáº¡i AI', LucideIcons.messageCircle, AdminColors.purple);
    }
    if (path.contains('/profile') || path.contains('/user')) {
      return const _ActionMeta('Truy cáº­p há»“ sÆ¡ ngÆ°á»i dÃ¹ng', LucideIcons.user, AdminColors.success);
    }
    if (path.contains('/admin')) {
      return const _ActionMeta('Thao tÃ¡c Admin', LucideIcons.shieldCheck, AdminColors.purple);
    }
    if (path.contains('/dashboard')) {
      return const _ActionMeta('Xem tá»•ng quan há»‡ thá»‘ng', LucideIcons.layoutDashboard, AdminColors.textMuted);
    }
    if (path.contains('/auth') || path.contains('/login')) {
      return const _ActionMeta('ÄÄƒng nháº­p / XÃ¡c thá»±c', LucideIcons.logIn, AdminColors.success);
    }
    return const _ActionMeta('Truy cáº­p há»‡ thá»‘ng', LucideIcons.activity, AdminColors.textMuted);
  }

  _RiskLevel _assessRisk(String method, String path, int status) {
    if (status >= 500) return _RiskLevel.critical;
    if (status >= 400) return _RiskLevel.warning;
    if (method == 'DELETE' && path.contains('/records')) return _RiskLevel.high;
    if (method == 'DELETE') return _RiskLevel.medium;
    if ((method == 'POST' || method == 'PATCH') && path.contains('/records')) return _RiskLevel.medium;
    if (path.contains('/admin')) return _RiskLevel.medium;
    return _RiskLevel.normal;
  }

  List<_AuditEvent> _applyFilter(List<_AuditEvent> events) {
    var result = events;
    switch (_filter) {
      case _AuditFilter.phi:
        result = result.where((e) =>
          e.detail.contains('/records') ||
          e.detail.contains('/medicines') ||
          e.detail.contains('/appointments')
        ).toList();
        break;
      case _AuditFilter.errors:
        result = result.where((e) => e.isError).toList();
        break;
      case _AuditFilter.admin:
        result = result.where((e) => e.detail.contains('/admin') || e.color == const Color(0xFFEC4899)).toList();
        break;
      case _AuditFilter.all:
        break;
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((e) =>
        e.userId.toLowerCase().contains(q) ||
        e.action.toLowerCase().contains(q) ||
        e.ip.contains(q) ||
        e.detail.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  // Summary bar â€” Datadog style: flat row, khÃ´ng cÃ³ colored box container
  Widget _buildSummaryBar(AccessLogStats stats, List<_AuditEvent> events) {
    final criticalCount = events.where((e) => e.risk == _RiskLevel.critical).length;
    final highCount     = events.where((e) => e.risk == _RiskLevel.high).length;
    final phiCount      = events.where((e) =>
      e.detail.contains('/records') || e.detail.contains('/medicines')).length;

    final hasAlert = criticalCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
        color: hasAlert ? AdminColors.danger.withOpacity(0.04) : Colors.transparent,
      ),
      child: Row(children: [
        // Status indicator
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: hasAlert ? AdminColors.danger : AdminColors.success,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          hasAlert ? 'Cáº£nh bÃ¡o báº£o máº­t' : 'BÃ¬nh thÆ°á»ng',
          style: TextStyle(
            color: hasAlert ? AdminColors.danger : AdminColors.success,
            fontSize: 12, fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Compact metrics inline
        _inlineStat('${stats.total}', 'request'),
        _statSep(),
        _inlineStat('$phiCount',      'PHI',     highlight: phiCount > 0),
        _statSep(),
        _inlineStat('$highCount',     'rá»§i ro',  highlight: highCount > 0, color: AdminColors.warning),
        _statSep(),
        _inlineStat('$criticalCount', 'nghiÃªm',  highlight: criticalCount > 0, color: AdminColors.danger),
      ]),
    );
  }

  Widget _inlineStat(String value, String label, {bool highlight = false, Color? color}) {
    final c = highlight ? (color ?? AdminColors.danger) : AdminColors.textMuted;
    return RichText(text: TextSpan(children: [
      TextSpan(text: value, style: TextStyle(
        color: highlight ? c : AdminColors.textPrimary,
        fontSize: 12, fontWeight: FontWeight.w600,
      )),
      TextSpan(text: ' $label', style: TextStyle(
        color: AdminColors.textMuted, fontSize: 11,
      )),
    ]));
  }

  Widget _statSep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: const Text('Â·', style: TextStyle(color: AdminColors.textMuted, fontSize: 11)),
  );

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: _AuditFilter.values.map((f) {
        final selected = _filter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _filter = f); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? f.color.withOpacity(0.15) : AdminColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? f.color : AdminColors.border),
              ),
              child: Text(f.label, style: TextStyle(
                color: selected ? f.color : AdminColors.textMuted,
                fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              )),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: TextField(
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'TÃ¬m kiáº¿m hoáº¡t Ä‘á»™ng...',
          hintStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(LucideIcons.search, size: 15, color: AdminColors.textMuted),
          filled: true,
          fillColor: AdminColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AdminColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AdminColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.aiPrimary)),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  // Log row â€” Datadog/Splunk dense style: khÃ´ng cÃ³ card border, chá»‰ cÃ³ bottom divider
  // Icon box 36px + border radius â†’ replaced by colored left bar 3px (nhÆ° users_screen)
  Widget _buildEventRow(_AuditEvent event) {
    final isAlert = event.risk == _RiskLevel.critical || event.risk == _RiskLevel.high;
    final leftColor = event.isError
        ? AdminColors.danger
        : event.risk == _RiskLevel.high
            ? AdminColors.warning
            : event.color;

    return Container(
      decoration: BoxDecoration(
        color: isAlert ? leftColor.withOpacity(0.03) : Colors.transparent,
        border: Border(bottom: BorderSide(color: AdminColors.border.withOpacity(0.6), width: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Left color bar thay tháº¿ icon box
        Container(
          width: 3,
          height: 54,
          color: leftColor.withOpacity(0.5),
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              // Left: action + user + ip
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(event.action, style: const TextStyle(
                        color: AdminColors.textPrimary,
                        fontSize: 12, fontWeight: FontWeight.w500,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (event.risk != _RiskLevel.normal && event.risk != _RiskLevel.medium) ...[                        
                      const SizedBox(width: 6),
                      Text(event.risk.label, style: TextStyle(
                        color: event.risk.color, fontSize: 10, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    '${event.userId == 'anonymous' ? 'khÃ¡ch' : event.userId}  Â·  ${event.ip}',
                    style: const TextStyle(
                      color: AdminColors.textMuted, fontSize: 10,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              // Right: status dot + time
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: event.isError ? AdminColors.danger : AdminColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 5),
                Text(event.time, style: const TextStyle(
                  color: AdminColors.textMuted, fontSize: 10,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
              ]),
              const SizedBox(width: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(LucideIcons.shieldCheck, color: AdminColors.textMuted, size: 22),
      const SizedBox(height: 12),
      const Text('KhÃ´ng cÃ³ sá»± kiá»‡n nÃ o', style: TextStyle(
        color: AdminColors.textSecondary, fontSize: 13,
      )),
      if (_search.isNotEmpty) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _search = ''),
          child: const Text('XÃ³a bá»™ lá»c', style: TextStyle(
            color: AdminColors.aiPrimary, fontSize: 12,
          )),
        ),
      ],
    ]),
  );
}

// â”€â”€ Data models ná»™i bá»™ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AuditEvent {
  final String userId, ip, time, action, detail;
  final IconData icon;
  final Color color;
  final _RiskLevel risk;
  final int status, durationMs;
  final bool isError;

  const _AuditEvent({
    required this.userId, required this.ip, required this.time,
    required this.action, required this.detail, required this.icon,
    required this.color, required this.risk, required this.status,
    required this.durationMs, required this.isError,
  });
}

class _ActionMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _ActionMeta(this.label, this.icon, this.color);
}

enum _RiskLevel {
  normal(AdminColors.textMuted, ''),
  medium(AdminColors.aiPrimary, 'MEDIUM'),
  high(AdminColors.warning, 'HIGH'),
  warning(AdminColors.warning, 'WARN'),
  critical(AdminColors.danger, 'CRITICAL');

  final Color color;
  final String label;
  const _RiskLevel(this.color, this.label);
}

enum _AuditFilter {
  all(AdminColors.textMuted, 'Táº¥t cáº£', LucideIcons.list),
  phi(AdminColors.purple, 'Dá»¯ liá»‡u y táº¿', LucideIcons.fileText),
  errors(AdminColors.danger, 'CÃ³ lá»—i', LucideIcons.alertTriangle),
  admin(AdminColors.aiPrimary, 'Admin', LucideIcons.shieldCheck);

  final Color color;
  final String label;
  final IconData icon;
  const _AuditFilter(this.color, this.label, this.icon);
}
