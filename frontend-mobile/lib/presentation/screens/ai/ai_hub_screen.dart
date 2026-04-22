import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/chat_screen.dart';
import 'package:medi_chain_mobile/presentation/screens/ai/consultation_screen.dart';

// ─── Design tokens — đồng nhất với toàn bộ app ────────────────────────────────
const _kPrimary     = Color(0xFF0D9488);
const _kBg          = Color(0xFFF8FAFC);
const _kSurface     = Colors.white;
const _kBorder      = Color(0xFFE2E8F0);
const _kTextPrimary = Color(0xFF0F172A);
const _kTextMuted   = Color(0xFF94A3B8);

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _AiOptionCard(
                    title: 'Bác sĩ Medi Chat',
                    subtitle: 'Hỏi đáp nhanh về sức khỏe, thuốc, triệu chứng. '
                        'Lưu lịch sử — tiếp tục mọi lúc.',
                    icon: LucideIcons.messageCircle,
                    tag: 'Trực tuyến 24/7',
                    tagColor: const Color(0xFF22C55E),
                    onTap: () => _openChat(context),
                  ),
                  const SizedBox(height: 16),
                  _AiOptionCard(
                    title: 'Tư vấn Chuyên sâu',
                    subtitle: 'Phân tích triệu chứng, gợi ý thuốc phù hợp '
                        'dựa trên hồ sơ sức khỏe của bạn.',
                    icon: LucideIcons.stethoscope,
                    tag: 'Dựa trên hồ sơ',
                    tagColor: const Color(0xFF3B82F6),
                    onTap: () => _openConsultation(context),
                  ),
                  const SizedBox(height: 32),
                  _buildDisclaimer(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sliver header với branding nhỏ gọn ──────────────────────────────────────
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medi avatar — branding nhất quán với ChatScreen
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'M',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mediAI',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Hỗ trợ y tế thông minh',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _kTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Divider
            Container(height: 1, color: _kBorder),
          ],
        ),
      ),
    );
  }

  // ─── Disclaimer ──────────────────────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.shieldCheck, size: 13, color: _kTextMuted),
        const SizedBox(width: 6),
        Text(
          'Chỉ mang tính chất tham khảo — không thay thế bác sĩ',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: _kTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _openConsultation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConsultationScreen()),
    );
  }
}

// ─── Option Card — dùng cho cả 2 lựa chọn ────────────────────────────────────
class _AiOptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final Color tagColor;
  final VoidCallback onTap;

  const _AiOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    required this.tagColor,
    required this.onTap,
  });

  @override
  State<_AiOptionCard> createState() => _AiOptionCardState();
}

class _AiOptionCardState extends State<_AiOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.tag,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.tagColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: _kTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}
