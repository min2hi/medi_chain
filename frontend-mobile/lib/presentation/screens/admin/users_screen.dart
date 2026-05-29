import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_app_bar.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_badge.dart';
import 'package:medi_chain_mobile/presentation/widgets/admin/admin_empty_state.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminBloc>()..add(LoadUsers()),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  // Icon duy nhất cho mỗi role — không dùng rainbow màu
  static const _roleIcons = {
    'ADMIN':  Icons.shield_rounded,
    'DOCTOR': Icons.medical_services_rounded,
    'USER':   Icons.people_rounded,
  };

  static const _roleLabels = {
    'ADMIN':  'Quản trị',
    'DOCTOR': 'Bác sĩ',
    'USER':   'Bệnh nhân',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AdminAppBar(
        title: 'Quản lý người dùng',
        showRefresh: true,
        onRefresh: () => context.read<AdminBloc>().add(LoadUsers()),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
              backgroundColor: AdminColors.danger,
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AdminColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimary, strokeWidth: 1.5));
          if (state is AdminError)  return AdminErrorState(message: state.message, onRetry: () => context.read<AdminBloc>().add(LoadUsers()));
          if (state is UsersLoaded) return _buildList(context, state.users);
          return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimary, strokeWidth: 1.5));
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AdminUserModel> users) {
    if (users.isEmpty) {
      return const AdminEmptyState(icon: LucideIcons.users, message: 'Không có người dùng nào');
    }
    final byRole = <String, List<AdminUserModel>>{};
    for (final u in users) {
      byRole.putIfAbsent(u.role, () => []).add(u);
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadUsers()),
      color: AppTheme.kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsRow(users),
          const SizedBox(height: 20),
          for (final role in ['ADMIN', 'DOCTOR', 'USER'])
            if (byRole[role] != null) ...[
              _buildRoleHeader(role, byRole[role]!.length),
              const SizedBox(height: 8),
              ...byRole[role]!.map((u) => _buildUserCard(context, u)),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<AdminUserModel> users) {
    final a = users.where((u) => u.role == 'ADMIN').length;
    final d = users.where((u) => u.role == 'DOCTOR').length;
    final p = users.where((u) => u.role == 'USER').length;
    return Row(
      children: [
        _MiniStat(label: 'Admin', value: '$a', color: AdminColors.roleAdmin),
        const SizedBox(width: 6),
        Container(width: 1, height: 14, color: AdminColors.border),
        const SizedBox(width: 6),
        _MiniStat(label: 'Bác sĩ', value: '$d', color: AdminColors.roleDoctor),
        const SizedBox(width: 6),
        Container(width: 1, height: 14, color: AdminColors.border),
        const SizedBox(width: 6),
        _MiniStat(label: 'Bệnh nhân', value: '$p', color: AdminColors.rolePatient),
      ],
    );
  }

  Widget _buildRoleHeader(String role, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(
        _roleIcons[role] ?? Icons.people_rounded,
        size: 13,
        color: AdminColors.textMuted,
      ),
      const SizedBox(width: 6),
      Text(
        '${_roleLabels[role]?.toUpperCase()} ($count)',
        style: const TextStyle(
          color: AdminColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ]),
  );

  Widget _buildUserCard(BuildContext context, AdminUserModel user) {
    final isDoctor = user.role == 'DOCTOR';
    final isUser   = user.role == 'USER';
    // Role accent color theo AdminColors system
    final Color roleAccent;
    if (user.role == 'ADMIN')  roleAccent = AdminColors.roleAdmin;
    else if (isDoctor)         roleAccent = AdminColors.roleDoctor;
    else                       roleAccent = AdminColors.rolePatient;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar = role color (Epic Systems pattern)
            Container(width: 3, color: roleAccent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: GoogleFonts.inter(
                                  color: AdminColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                user.email,
                                style: GoogleFonts.inter(
                                  color: AdminColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ADMIN: badge tĩnh, không cho đổi role qua UI
                        if (user.role == 'ADMIN')
                          _RoleStaticBadge(
                            label: 'Admin',
                            color: AdminColors.roleAdmin,
                          )
                        else
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            AdminBadge(
                              label: _roleLabels[user.role] ?? user.role,
                              type: isDoctor ? AdminBadgeType.doctor : AdminBadgeType.patient,
                            ),
                            const SizedBox(width: 8),
                            _RoleToggleButton(user: user, isDoctor: isDoctor, isUser: isUser),
                          ]),
                      ],
                    ),
                    // Doctor credential row — chỉ hiện khi là DOCTOR
                    if (isDoctor) ..._buildDoctorCredentials(context, user),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDoctorCredentials(BuildContext context, AdminUserModel user) {
    final verified = user.licenseVerified;
    final verifiedColor = AdminColors.success;
    final pendingColor  = AdminColors.warning;
    final activeColor   = verified ? verifiedColor : pendingColor;
    return [
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activeColor.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(
            verified ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            size: 14,
            color: activeColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                user.licenseNumber?.isNotEmpty == true
                    ? 'CC: ${user.licenseNumber}'
                    : 'Chưa nhập số chứng chỉ',
                style: GoogleFonts.inter(
                  color: verified ? AdminColors.textPrimary : AdminColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (user.specialty?.isNotEmpty == true) ...[  
                const SizedBox(height: 1),
                Text(
                  user.specialty!,
                  style: GoogleFonts.inter(
                    color: AdminColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ]),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _confirmVerify(context, user),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: activeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  verified ? 'Đã xác nhận' : 'Xác nhận',
                  style: GoogleFonts.inter(
                    color: activeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    ];
  }

  void _confirmVerify(BuildContext context, AdminUserModel user) {
    final isVerified = user.licenseVerified;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.overlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          isVerified ? 'Hủy xác nhận?' : 'Xác nhận chứng chỉ?',
          style: GoogleFonts.inter(
            color: AdminColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          isVerified
              ? 'Hủy xác thực chứng chỉ của bác sĩ "${user.name}"?'
              : 'Xác nhận chứng chỉ hành nghề của "${user.name}"?',
          style: GoogleFonts.inter(
            color: AdminColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: AdminColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(VerifyDoctorLicense(user.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: isVerified ? AdminColors.danger : AdminColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isVerified ? 'Hủy xác nhận' : 'Xác nhận',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nút phân quyền / thu hồi quyền Bác sĩ ────────────────────────────────────
// Widget riêng để giữ BuildContext qua showDialog
class _RoleToggleButton extends StatelessWidget {
  const _RoleToggleButton({
    required this.user,
    required this.isDoctor,
    required this.isUser,
  });

  final AdminUserModel user;
  final bool isDoctor;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (!isDoctor && !isUser) return const SizedBox.shrink();

    final promoteToDoctor = isUser; // true = gán bác sĩ, false = thu hồi
    final buttonColor = promoteToDoctor
        ? const Color(0xFF3B82F6)  // xanh dương
        : const Color(0xFFF59E0B); // vàng

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showConfirmDialog(context, promoteToDoctor),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: buttonColor.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              promoteToDoctor ? LucideIcons.stethoscope : LucideIcons.userMinus,
              size: 11,
              color: buttonColor,
            ),
            const SizedBox(width: 4),
            Text(
              promoteToDoctor ? 'Gán Bác sĩ' : 'Thu hồi',
              style: TextStyle(color: buttonColor, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, bool promoteToDoctor) {
    final bloc        = context.read<AdminBloc>();
    final newRole     = promoteToDoctor ? 'DOCTOR' : 'USER';
    final title       = promoteToDoctor ? 'Gán quyền Bác sĩ?' : 'Thu hồi quyền Bác sĩ?';
    final body        = promoteToDoctor
        ? 'Tài khoản "${user.name}" sẽ được phân quyền DOCTOR.\nLần đăng nhập tiếp theo sẽ vào thẳng trang Bác sĩ.'
        : 'Thu hồi quyền Bác sĩ của "${user.name}"?\nTài khoản sẽ trở về vai trò Bệnh nhân.';
    final confirmText  = promoteToDoctor ? 'Gán Bác sĩ' : 'Thu hồi';
    final confirmColor = promoteToDoctor ? AdminColors.roleDoctor : AdminColors.danger;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.overlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: AdminColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          body,
          style: GoogleFonts.inter(
            color: AdminColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: AdminColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(UpdateUserRole(user.id, newRole));
            },
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              confirmText,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini stat chip (dùng trong stats row) ─────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AdminColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─── Static role badge (Admin — không cho đổi role) ───────────────────────────
class _RoleStaticBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleStaticBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
