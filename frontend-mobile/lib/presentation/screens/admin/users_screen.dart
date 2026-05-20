import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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


  static const _roleColors = {
    'ADMIN': Color(0xFFEC4899),
    'DOCTOR': Color(0xFF3B82F6),
    'USER': Color(0xFF10B981),
  };

  static const _roleLabels = {
    'ADMIN': 'Admin',
    'DOCTOR': 'Bác sĩ',
    'USER': 'Bệnh nhân',
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                backgroundColor: AdminColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AdminColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: AdminColors.roleAdmin));
          if (state is AdminError) return AdminErrorState(message: state.message, onRetry: () => context.read<AdminBloc>().add(LoadUsers()));
          if (state is UsersLoaded) return _buildList(context, state.users);
          return const Center(child: CircularProgressIndicator(color: AdminColors.roleAdmin));
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AdminUserModel> users) {
    if (users.isEmpty) {
      return const AdminEmptyState(
        icon: LucideIcons.users,
        message: 'Không có người dùng nào',
      );
    }
    final byRole = <String, List<AdminUserModel>>{};
    for (final u in users) {
      byRole.putIfAbsent(u.role, () => []).add(u);
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(LoadUsers()),
      color: const Color(0xFFEC4899),
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
    // Inline summary — Linear style, không dùng colored boxes
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$a admin  ·  $d bác sĩ  ·  $p bệnh nhân',
        style: const TextStyle(
          color: AdminColors.textMuted, fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRoleHeader(String role, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: _roleColors[role], shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(
        '${_roleLabels[role]?.toUpperCase()} ($count)',
        style: TextStyle(color: _roleColors[role], fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
      ),
    ]),
  );

  Widget _buildUserCard(BuildContext context, AdminUserModel user) {
    final color   = _roleColors[user.role] ?? AdminColors.textMuted;
    final isDoctor = user.role == 'DOCTOR';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Left: colored bar thay cho CircleAvatar
          Container(
            width: 3, height: 38,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(user.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ]),
          ),
          // ADMIN: không cho đổi role qua UI (hiện badge tĩnh)
          if (user.role == 'ADMIN')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.4)),
              ),
              child: const Text('Admin', style: TextStyle(color: Color(0xFFEC4899), fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            AdminBadge(
              label: _roleLabels[user.role] ?? user.role,
              type: user.role == 'DOCTOR'
                  ? AdminBadgeType.doctor
                  : AdminBadgeType.patient,
            ),
        ]),
        // Doctor credential row — chỉ hiện khi là DOCTOR
        if (isDoctor) ..._buildDoctorCredentials(context, user),
      ]),
    );
  }

  List<Widget> _buildDoctorCredentials(BuildContext context, AdminUserModel user) {
    final verified = user.licenseVerified;
    return [
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: verified ? const Color(0xFF052E16) : const Color(0xFF1C1917),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: verified ? const Color(0xFF16A34A).withOpacity(0.4) : const Color(0xFF44403C),
          ),
        ),
        child: Row(children: [
          Icon(
            verified ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            size: 14,
            color: verified ? const Color(0xFF4ADE80) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                user.licenseNumber?.isNotEmpty == true
                    ? 'Số chứng chỉ: ${user.licenseNumber}'
                    : 'Chưa nhập số chứng chỉ',
                style: TextStyle(
                  color: verified ? const Color(0xFF86EFAC) : const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
              if (user.specialty?.isNotEmpty == true)
                Text('Chuyên khoa: ${user.specialty}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            ]),
          ),
          GestureDetector(
            onTap: () => _confirmVerify(context, user),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: verified
                    ? const Color(0xFF16A34A).withOpacity(0.15)
                    : const Color(0xFF92400E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: verified
                      ? const Color(0xFF16A34A).withOpacity(0.4)
                      : const Color(0xFFD97706).withOpacity(0.4),
                ),
              ),
              child: Text(
                verified ? '✓ Đã xác nhận' : 'Xác nhận',
                style: TextStyle(
                  color: verified ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
        title: Text(
          isVerified ? 'Hủy xác nhận?' : 'Xác nhận chứng chỉ?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isVerified
              ? 'Hủy xác thực chứng chỉ của bác sĩ "${user.name}"?'
              : 'Xác nhận chứng chỉ hành nghề của "${user.name}"?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Há»§y', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(VerifyDoctorLicense(user.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isVerified ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
            child: Text(isVerified ? 'Hủy xác nhận' : 'Xác nhận'),
          ),
        ],
      ),
    );
  }
}
