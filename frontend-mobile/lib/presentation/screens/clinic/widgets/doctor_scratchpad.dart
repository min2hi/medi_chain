import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorScratchpad extends StatefulWidget {
  const DoctorScratchpad({super.key});

  @override
  State<DoctorScratchpad> createState() => _DoctorScratchpadState();
}

class _DoctorScratchpadState extends State<DoctorScratchpad> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  String _saveStatus = 'Đã lưu'; // 'Đã lưu' | 'Đang lưu...'
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('doctor_scratchpad_notes') ?? '';
      _controller.text = saved;
    } catch (_) {
      // Fail silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotes(String val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('doctor_scratchpad_notes', val);
      if (mounted) {
        setState(() {
          _saveStatus = 'Đã lưu';
        });
      }
    } catch (_) {
      // Fail silently
    }
  }

  void _onTextChanged(String val) {
    if (mounted) {
      setState(() {
        _saveStatus = 'Đang lưu...';
      });
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _saveNotes(val);
    });
  }

  void _clearNotes() {
    _controller.clear();
    _onTextChanged('');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.fileEdit,
                  size: 13,
                  color: AppTheme.kTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'SỔ TAY GHI CHÚ NHANH',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  _saveStatus,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: _saveStatus == 'Đang lưu...'
                        ? AppTheme.kWarning
                        : AppTheme.kSuccess,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.kSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppTheme.kBorder),
              boxShadow: AppShadow.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Notepad border indicator (amber color)
                    Container(
                      width: 4,
                      color: const Color(0xFFF59E0B), // Warm Amber
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                              Text(
                                'Ghi chú cá nhân lâm sàng',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.kTextPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (_controller.text.isNotEmpty)
                                GestureDetector(
                                  onTap: _clearNotes,
                                  child: Text(
                                    'Xóa',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.kDanger,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _controller,
                            onChanged: _onTextChanged,
                            maxLines: 4,
                            minLines: 2,
                            keyboardType: TextInputType.multiline,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.kTextSecondary,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập ghi chú nhanh tại đây (ví dụ: dị ứng, ca hội chẩn, lưu ý thuốc)...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.kTextMuted,
                                fontStyle: FontStyle.italic,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
