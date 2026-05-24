import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';

// ══════════════════════════════════════════════════════════════
// HtCheckinSheet — Weekly check-in bottom sheet
// Không bắt buộc — 10 giây — 4 lựa chọn cảm giác sức khỏe
// ══════════════════════════════════════════════════════════════

// Dark mode color constants (mirror AppTheme.darkTheme local consts)
const _darkSurface = Color(0xFF1E293B);
const _darkBorder  = Color(0xFF334155);

class HtCheckinSheet extends StatefulWidget {
  const HtCheckinSheet({super.key});

  @override
  State<HtCheckinSheet> createState() => _HtCheckinSheetState();
}

class _HtCheckinSheetState extends State<HtCheckinSheet> {
  String? _selected;

  static const _options = [
    ('good',   '😊', 'Rất khỏe',    AdminColors.success),
    ('normal', '😐', 'Bình thường', AppTheme.kAccent),
    ('tired',  '😔', 'Mệt mỏi',     AdminColors.warning),
    ('bad',    '😫', 'Không khỏe',  AdminColors.danger),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
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

  Widget _buildHandle() {
    return Container(
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: AppTheme.kBorder,
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
            color: isDark ? Colors.white : AppTheme.kTextPrimary,
          )),
        const SizedBox(height: 6),
        Text('AI sẽ học từ phản hồi của bạn để hiểu baseline tốt hơn',
          style: TextStyle(fontSize: 13, color: AppTheme.kTextMuted),
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
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selected = value);
          },
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
          backgroundColor: AppTheme.kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? _darkSurface : AppTheme.kBorder,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          _selected == null ? 'Chọn một lựa chọn' : 'Ghi nhận',
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: _selected == null
                ? (isDark ? AppTheme.kTextSecondary : AppTheme.kTextMuted)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Bỏ qua — không bắt buộc',
          style: TextStyle(fontSize: 13, color: AppTheme.kTextMuted)),
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
              ? color.withValues(alpha: 0.1)
              : isDark ? _darkSurface : AppTheme.kBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : isDark ? _darkBorder : AppTheme.kBorder,
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
            color: isDark ? _darkSurface : AppTheme.kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.kPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.clipboardList,
                    size: 18, color: AppTheme.kPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tuần này bạn thế nào?',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.kTextPrimary,
                      )),
                    const SizedBox(height: 2),
                    Text('Check-in tuần · Không bắt buộc · 10 giây',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kTextMuted,
                      )),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16,
                  color: isDark ? _darkBorder : const Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}
