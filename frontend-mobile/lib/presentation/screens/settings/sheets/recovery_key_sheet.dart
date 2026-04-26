import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';

// ─── Color tokens ─────────────────────────────
const _kPrimary = Color(0xFF0D9488);

class RecoveryKeySheet extends StatefulWidget {
  const RecoveryKeySheet({super.key});

  @override
  State<RecoveryKeySheet> createState() => _RecoveryKeySheetState();
}

class _RecoveryKeySheetState extends State<RecoveryKeySheet> {
  final _pwdCtrl = TextEditingController();
  bool _showPwd = false, _loading = false;
  String _error = '', _recoveryKey = '';
  bool _copied = false;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _reveal() async {
    if (_pwdCtrl.text.isEmpty) return setState(() => _error = 'Nhập mật khẩu để xác minh');
    setState(() { _loading = true; _error = ''; });
    final result = await getIt<AuthRepository>().revealRecoveryKey(_pwdCtrl.text);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _recoveryKey = result['data']['recoveryKey'] as String? ?? '');
    } else {
      setState(() => _error = result['message'] ?? 'Mật khẩu không đúng');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Recovery Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_recoveryKey.isEmpty) ...[
            const SizedBox(height: 4),
            const Text('Nhập mật khẩu để xem khoá khôi phục', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            const Text('Mật khẩu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            TextField(
              controller: _pwdCtrl,
              obscureText: !_showPwd,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5)),
                suffixIcon: IconButton(
                  icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _showPwd = !_showPwd),
                ),
              ),
            ),
            if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Hủy'),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: _loading ? null : _reveal,
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, disabledBackgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Xem khoá', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Khoá khôi phục của bạn:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text(_recoveryKey, style: const TextStyle(fontSize: 13, height: 1.6, fontFamily: 'monospace')),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Lưu khoá này ở nơi an toàn. Không chia sẻ với bất kỳ ai.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _recoveryKey));
                setState(() => _copied = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) setState(() => _copied = false);
              },
              icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
              label: Text(_copied ? 'Đã sao chép!' : 'Sao chép khoá'),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Đóng'),
            )),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
