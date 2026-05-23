import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';

// ══════════════════════════════════════════════════════════════
// HtCheckinSheet — Weekly check-in bottom sheet
// Không bắt buộc — 10 giây — 4 lựa chọn cảm giác sức khỏe
// ══════════════════════════════════════════════════════════════

class HtCheckinSheet extends StatefulWidget {
  const HtCheckinSheet({super.key});

  @override
  State<HtCheckinSheet> createState() => _HtCheckinSheetState();
}

class _HtCheckinSheetState extends State<HtCheckinSheet> {
  String? _selected;

  static const _options = [
    ('good',   '😊', 'Rất khỏe',     Color(0xFF10B981)),
    ('normal', '😐', 'Bình thường',  Color(0xFF3B82F6)),
    ('tired',  '😔', 'Mệt mỏi',      Color(0xFFF59E0B)),
    ('bad',    '😫', 'Không khỏe',   Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(isDark),
          const SizedBox(height: 24),
          _buildTitle(isDark),
          const SizedBox(height: 24),
          _buildGrid(isDark),
          const SizedBox(height: 20),
          _buildSubmitButton(isDark),
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Column(
      children: [
        Text('Tuần qua bạn cảm thấy thế nào?',
          style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          )),
        const SizedBox(height: 6),
        Text('AI sẽ học từ phản hồi của bạn để hiểu baseline tốt hơn',
          style: TextStyle(fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _options.map((opt) {
        final (value, emoji, label, color) = opt;
        return _OptionCell(
          value: value, emoji: emoji, label: label, color: color,
          isSelected: _selected == value,
          isDark: isDark,
          onTap: () => setState(() => _selected = value),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _selected == null
            ? null
            : () {
                context.read<HealthTwinBloc>().add(
                    HealthTwinCheckinSubmitted(_selected!));
                Navigator.pop(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14B8A6),
          disabledBackgroundColor: isDark
              ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          _selected == null ? 'Chọn một lựa chọn' : 'Ghi nhận',
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: _selected == null
                ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Bỏ qua — không bắt buộc',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    );
  }
}

// ── Option Cell ───────────────────────────────────────────────

class _OptionCell extends StatelessWidget {
  final String value;
  final String emoji;
  final String label;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionCell({
    required this.value, required this.emoji,
    required this.label, required this.color,
    required this.isSelected, required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: isSelected ? color
                    : isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Checkin Entry Prompt (dùng trong screen chính) ────────────

class HtCheckinPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const HtCheckinPrompt({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.clipboardList,
                    size: 18, color: Color(0xFF14B8A6)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tuần này bạn thế nào?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('Check-in tuần · Không bắt buộc · 10 giây',
                      style: TextStyle(fontSize: 12,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16,
                  color: isDark
                      ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}
