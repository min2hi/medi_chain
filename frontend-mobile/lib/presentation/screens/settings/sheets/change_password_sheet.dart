import 'package:flutter/material.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';

// ─── Color tokens ─────────────────────────────
const _kPrimary = Color(0xFF0D9488);

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  bool _loading = false;
  String _error = '';
  bool _success = false;

  @override
  void dispose() {
    _current.dispose();
    _newPwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _strength {
    final p = _newPwd.text;
    if (p.isEmpty) return '';
    if (p.length < 8) return 'Yếu';
    final hasNum = RegExp(r'\d').hasMatch(p);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    if (p.length >= 12 && hasNum && hasSpecial) return 'Mạnh';
    if (hasNum || hasSpecial) return 'Trung bình';
    return 'Yếu';
  }

  Color get _strengthColor => switch (_strength) {
        'Mạnh' => const Color(0xFF10B981),
        'Trung bình' => const Color(0xFFF59E0B),
        _ => const Color(0xFFEF4444),
      };

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_current.text.isEmpty || _newPwd.text.isEmpty || _confirm.text.isEmpty) {
      return setState(() => _error = 'Vui lòng nhập đầy đủ thông tin');
    }
    if (_newPwd.text.length < 8) {
      return setState(() => _error = 'Mật khẩu mới phải từ 8 ký tự');
    }
    if (_newPwd.text != _confirm.text) {
      return setState(() => _error = 'Xác nhận mật khẩu không khớp');
    }
    setState(() => _loading = true);
    final result = await getIt<AuthRepository>().changePassword(
      _current.text,
      _newPwd.text,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _error = result['message'] ?? 'Đã xảy ra lỗi';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tối thiểu 8 ký tự, nên dùng số và ký tự đặc biệt', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          if (_success) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 10),
                Text('Đổi mật khẩu thành công!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
              ]),
            ),
          ] else ...[
            _pwdField('Mật khẩu hiện tại', _current, _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
            const SizedBox(height: 12),
            _pwdField('Mật khẩu mới', _newPwd, _showNew, () => setState(() => _showNew = !_showNew), onChanged: (_) => setState(() {})),
            if (_newPwd.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                ...List.generate(3, (i) => Expanded(child: Container(
                  height: 4, margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i < (_strength == 'Yếu' ? 1 : _strength == 'Trung bình' ? 2 : 3) ? _strengthColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ))),
                const SizedBox(width: 4),
                Text(_strength, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _strengthColor)),
              ]),
            ],
            const SizedBox(height: 12),
            _pwdField('Xác nhận mật khẩu mới', _confirm, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Hủy'),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, disabledBackgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _pwdField(String label, TextEditingController ctrl, bool show, VoidCallback toggle, {Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: !show,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5)),
          suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF94A3B8)), onPressed: toggle),
        ),
      ),
    ]);
  }
}
