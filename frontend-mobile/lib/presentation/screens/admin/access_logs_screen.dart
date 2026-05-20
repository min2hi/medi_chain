import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

// ── PHI Audit Trail Screen ────────────────────────────────────────────────────
// Theo HIPAA § 164.312(b) — Audit Controls: "Implement hardware, software,
// and/or procedural mechanisms that record and examine activity in information
// systems that contain or use ePHI."
//
// Thay vì chỉ hiển thị raw HTTP log (method + path + IP), màn hình này tập
// trung vào các câu hỏi mà auditor y tế thực sự cần trả lời:
//   "Ai xem hồ sơ của bệnh nhân nào, lúc mấy giờ, và từ thiết bị nào?"
//
// Tham khảo: Epic Systems Audit Log, Cerner Millennium Access Audit,
// NHS England Access Control Policy (2023).
// ─────────────────────────────────────────────────────────────────────────────

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
  // Bộ lọc: null = tất cả
  _AuditFilter _filter = _AuditFilter.all;
  String   _search = '';
  DateTime _selectedDate = DateTime.now();  // Date picker state (Epic pattern)

  /// Mở date picker và reload nếu user chọn ngày khác.
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
    // Reload data cho ngày mới — format YYYY-MM-DD
    final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (mounted) context.read<AdminBloc>().add(LoadAccessLogs(date: dateStr));
  }

  /// Export entries hiện tại sang CSV và copy vào clipboard.
  /// Pattern: Robinhood transaction export — zero dependency, instant.
  void _exportToCsv(List<AccessLogEntry> entries) {
    final header = 'timestamp,userId,method,path,status,ip,durationMs';
    final rows = entries.map((e) =>
      '${e.timestamp},${e.userId},${e.method},"${e.path}",${e.status},${e.ip},${e.durationMs}'
    ).join('\n');
    final csv = '$header\n$rows';
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Đã copy ${entries.length} dòng CSV vào clipboard'),
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
      // AppBar nằm trong build() để rebuild khi _selectedDate thay đổi
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
            Text('Nhật Ký Hoạt Động', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Ai xem gì · Lúc nào · Từ đâu', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Date Picker button — rebuild với date mới khi setState()
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
        // Summary bar — flat, không có color box
        _buildSummaryBar(data.stats, events),
        
        // Filter tabs
        _buildFilterRow(),
        
        // Search + Export
        Row(children: [
          Expanded(child: _buildSearchBar()),
          if (data.entries.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.clipboardCopy, color: AdminColors.textMuted, size: 18),
              tooltip: 'Copy CSV vào clipboard',
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

  // ── Convert raw HTTP logs → semantic PHI events ────────────────────────────
  // Đây là điểm cốt lõi: thay vì "GET /records", ta hiểu là
  // "User u_133ae9e7 đã xem danh sách hồ sơ bệnh án"
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
    // PHI-sensitive endpoints — quan trọng nhất
    if (path.contains('/records') && method == 'GET') {
      return const _ActionMeta('Xem hồ sơ bệnh án', LucideIcons.fileText, AdminColors.aiPrimary);
    }
    if (path.contains('/records') && method == 'POST') {
      return const _ActionMeta('Tạo hồ sơ bệnh án', LucideIcons.filePlus, AdminColors.success);
    }
    if (path.contains('/records') && (method == 'PATCH' || method == 'PUT')) {
      return const _ActionMeta('Chỉnh sửa hồ sơ bệnh án', LucideIcons.fileEdit, AdminColors.warning);
    }
    if (path.contains('/records') && method == 'DELETE') {
      return const _ActionMeta('Xóa hồ sơ bệnh án', LucideIcons.fileX, AdminColors.danger);
    }
    if (path.contains('/medicines') || path.contains('/medicine')) {
      return const _ActionMeta('Truy cập dữ liệu thuốc', LucideIcons.pill, AdminColors.purple);
    }
    if (path.contains('/appointments')) {
      return const _ActionMeta('Truy cập lịch hẹn', LucideIcons.calendarCheck, AdminColors.aiPrimary);
    }
    if (path.contains('/conversations') || path.contains('/messages')) {
      return const _ActionMeta('Truy cập cuộc hội thoại AI', LucideIcons.messageCircle, AdminColors.purple);
    }
    if (path.contains('/profile') || path.contains('/user')) {
      return const _ActionMeta('Truy cập hồ sơ người dùng', LucideIcons.user, AdminColors.success);
    }
    if (path.contains('/admin')) {
      return const _ActionMeta('Thao tác Admin', LucideIcons.shieldCheck, AdminColors.purple);
    }
    if (path.contains('/dashboard')) {
      return const _ActionMeta('Xem tổng quan hệ thống', LucideIcons.layoutDashboard, AdminColors.textMuted);
    }
    if (path.contains('/auth') || path.contains('/login')) {
      return const _ActionMeta('Đăng nhập / Xác thực', LucideIcons.logIn, AdminColors.success);
    }
    return const _ActionMeta('Truy cập hệ thống', LucideIcons.activity, AdminColors.textMuted);
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

  // Summary bar — Datadog style: flat row, không có colored box container
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
          hasAlert ? 'Cảnh báo bảo mật' : 'Bình thường',
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
        _inlineStat('$highCount',     'rủi ro',  highlight: highCount > 0, color: AdminColors.warning),
        _statSep(),
        _inlineStat('$criticalCount', 'nghiêm',  highlight: criticalCount > 0, color: AdminColors.danger),
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
    child: const Text('·', style: TextStyle(color: AdminColors.textMuted, fontSize: 11)),
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
          hintText: 'Tìm kiếm hoạt động...',
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

  // Log row — Datadog/Splunk dense style: không có card border, chỉ có bottom divider
  // Icon box 36px + border radius → replaced by colored left bar 3px (như users_screen)
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
        // Left color bar thay thế icon box
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
                    '${event.userId == 'anonymous' ? 'khách' : event.userId}  ·  ${event.ip}',
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
      const Text('Không có sự kiện nào', style: TextStyle(
        color: AdminColors.textSecondary, fontSize: 13,
      )),
      if (_search.isNotEmpty) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _search = ''),
          child: const Text('Xóa bộ lọc', style: TextStyle(
            color: AdminColors.aiPrimary, fontSize: 12,
          )),
        ),
      ],
    ]),
  );
}

// ── Data models nội bộ ────────────────────────────────────────────────────────

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
  all(AdminColors.textMuted, 'Tất cả', LucideIcons.list),
  phi(AdminColors.purple, 'Dữ liệu y tế', LucideIcons.fileText),
  errors(AdminColors.danger, 'Có lỗi', LucideIcons.alertTriangle),
  admin(AdminColors.aiPrimary, 'Admin', LucideIcons.shieldCheck);

  final Color color;
  final String label;
  final IconData icon;
  const _AuditFilter(this.color, this.label, this.icon);
}
