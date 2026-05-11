import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

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
      backgroundColor: const Color(0xFF0F172A),
      // AppBar nằm trong build() để rebuild khi _selectedDate thay đổi
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PHI Audit Trail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('HIPAA § 164.312(b)', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
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
          child: Container(color: const Color(0xFF1E293B), height: 1),
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }
          if (state is AdminError) return _buildError(context, state.message);
          if (state is AccessLogsLoaded) return _buildContent(state.data);
          return const SizedBox.shrink();
        },
      ),
    );
  }


  Widget _buildContent(AccessLogData data) {
    // Phân loại entries từ raw log sang semantic events
    final events   = _toAuditEvents(data.entries);
    final filtered = _applyFilter(events);

    return Column(
      children: [
        // ── Summary banner (Epic-style: risk score) ────────────────────────
        _buildRiskBanner(data.stats, events),

        // ── Filter tabs ─────────────────────────────────────────
        _buildFilterRow(),

        // ── Search + Export (AWS CloudTrail pattern) ────────────────
        Row(children: [
          Expanded(child: _buildSearchBar()),
          if (data.entries.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.clipboardCopy, color: Color(0xFF94A3B8), size: 20),
              tooltip: 'Copy CSV vào clipboard',
              onPressed: () => _exportToCsv(data.entries),
            ),
        ]),

        // ── Audit event list ─────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => context.read<AdminBloc>().add(LoadAccessLogs()),
            color: const Color(0xFF6366F1),
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildEventCard(filtered[i]),
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
      return _ActionMeta('Xem hồ sơ bệnh án', LucideIcons.fileText, const Color(0xFF3B82F6));
    }
    if (path.contains('/records') && method == 'POST') {
      return _ActionMeta('Tạo hồ sơ bệnh án', LucideIcons.filePlus, const Color(0xFF10B981));
    }
    if (path.contains('/records') && (method == 'PATCH' || method == 'PUT')) {
      return _ActionMeta('Chỉnh sửa hồ sơ bệnh án', LucideIcons.fileEdit, const Color(0xFFF59E0B));
    }
    if (path.contains('/records') && method == 'DELETE') {
      return _ActionMeta('Xóa hồ sơ bệnh án', LucideIcons.fileX, const Color(0xFFEF4444));
    }
    if (path.contains('/medicines') || path.contains('/medicine')) {
      return _ActionMeta('Truy cập dữ liệu thuốc', LucideIcons.pill, const Color(0xFF8B5CF6));
    }
    if (path.contains('/appointments')) {
      return _ActionMeta('Truy cập lịch hẹn', LucideIcons.calendarCheck, const Color(0xFF0EA5E9));
    }
    if (path.contains('/conversations') || path.contains('/messages')) {
      return _ActionMeta('Truy cập cuộc hội thoại AI', LucideIcons.messageCircle, const Color(0xFF6366F1));
    }
    if (path.contains('/profile') || path.contains('/user')) {
      return _ActionMeta('Truy cập hồ sơ người dùng', LucideIcons.user, const Color(0xFF14B8A6));
    }
    if (path.contains('/admin')) {
      return _ActionMeta('Thao tác Admin', LucideIcons.shieldCheck, const Color(0xFFEC4899));
    }
    if (path.contains('/dashboard')) {
      return _ActionMeta('Xem tổng quan hệ thống', LucideIcons.layoutDashboard, const Color(0xFF94A3B8));
    }
    if (path.contains('/auth') || path.contains('/login')) {
      return _ActionMeta('Đăng nhập / Xác thực', LucideIcons.logIn, const Color(0xFF10B981));
    }
    return _ActionMeta('API Request', LucideIcons.activity, const Color(0xFF475569));
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

  // ── Risk Banner (inspired by Epic Systems audit summary) ────────────────────
  Widget _buildRiskBanner(AccessLogStats stats, List<_AuditEvent> events) {
    final criticalCount = events.where((e) => e.risk == _RiskLevel.critical).length;
    final highCount = events.where((e) => e.risk == _RiskLevel.high).length;
    final phiAccessCount = events.where((e) =>
      e.detail.contains('/records') || e.detail.contains('/medicines')
    ).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: criticalCount > 0 ? const Color(0xFF1C0A0A) : const Color(0xFF0F1F1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: criticalCount > 0 ? const Color(0xFF7F1D1D) : const Color(0xFF164E63),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              criticalCount > 0 ? LucideIcons.alertTriangle : LucideIcons.shieldCheck,
              color: criticalCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              criticalCount > 0 ? 'Cảnh báo bảo mật' : 'Trạng thái bình thường',
              style: TextStyle(
                color: criticalCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
                fontSize: 13, fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'Hôm nay',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _summaryChip('${stats.total}', 'Tổng request', const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _summaryChip('$phiAccessCount', 'Truy cập PHI', const Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            _summaryChip('$highCount', 'Rủi ro cao', const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            _summaryChip('$criticalCount', 'Nghiêm trọng', const Color(0xFFEF4444)),
          ]),
        ],
      ),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: _AuditFilter.values.map((f) {
        final selected = _filter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? f.color.withOpacity(0.15) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? f.color : const Color(0xFF334155)),
              ),
              child: Row(children: [
                Icon(f.icon, size: 13, color: selected ? f.color : const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(f.label, style: TextStyle(
                  color: selected ? f.color : const Color(0xFF64748B),
                  fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
              ]),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Tìm theo user ID, IP, hành động...',
          hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF475569)),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildEventCard(_AuditEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: event.risk == _RiskLevel.critical
            ? const Color(0xFF1C0A0A)
            : event.risk == _RiskLevel.high
                ? const Color(0xFF1C1107)
                : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: event.risk == _RiskLevel.critical
              ? const Color(0xFF7F1D1D).withOpacity(0.6)
              : event.risk == _RiskLevel.high
                  ? const Color(0xFF78350F).withOpacity(0.5)
                  : const Color(0xFF334155),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon hành động
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(event.icon, color: event.color, size: 17),
          ),
          const SizedBox(width: 10),

          // Nội dung chính
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Dòng 1: tên hành động + risk badge
              Row(children: [
                Expanded(
                  child: Text(
                    event.action,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (event.risk != _RiskLevel.normal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.risk.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(event.risk.label, style: TextStyle(color: event.risk.color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 3),

              // Dòng 2: User ID
              Row(children: [
                const Icon(LucideIcons.user, size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(event.userId, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ]),
              const SizedBox(height: 2),

              // Dòng 3: IP + raw path (collapsed)
              Row(children: [
                const Icon(LucideIcons.mapPin, size: 11, color: Color(0xFF475569)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${event.ip}  ·  ${event.detail}',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),

          // Thời gian + status + duration
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${event.status}',
              style: TextStyle(
                color: event.isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                fontSize: 13, fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(event.time, style: const TextStyle(color: Color(0xFF475569), fontSize: 9)),
            Text('${event.durationMs}ms', style: const TextStyle(color: Color(0xFF334155), fontSize: 9)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.shieldCheck, color: Color(0xFF334155), size: 48),
          const SizedBox(height: 12),
          const Text('Không có sự kiện nào', style: TextStyle(color: Color(0xFF64748B))),
          if (_search.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _search = ''),
              child: const Text('Xóa bộ lọc', style: TextStyle(color: Color(0xFF6366F1), fontSize: 13)),
            ),
          ],
        ]),
      );

  Widget _buildError(BuildContext context, String msg) => Center(
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
  normal(Color(0xFF475569), ''),
  medium(Color(0xFF3B82F6), 'MEDIUM'),
  high(Color(0xFFEA580C), 'HIGH'),     // Orange
  warning(Color(0xFFF59E0B), 'WARN'),  // Amber
  critical(Color(0xFFEF4444), 'CRITICAL');

  final Color color;
  final String label;
  const _RiskLevel(this.color, this.label);
}

enum _AuditFilter {
  all(Color(0xFF94A3B8), 'Tất cả', LucideIcons.list),
  phi(Color(0xFF8B5CF6), 'PHI Access', LucideIcons.fileText),
  errors(Color(0xFFEF4444), 'Lỗi', LucideIcons.alertTriangle),
  admin(Color(0xFFEC4899), 'Admin', LucideIcons.shieldCheck);

  final Color color;
  final String label;
  final IconData icon;
  const _AuditFilter(this.color, this.label, this.icon);
}
