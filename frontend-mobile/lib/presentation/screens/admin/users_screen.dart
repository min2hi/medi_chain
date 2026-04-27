import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/admin_models.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';

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

  static const _roles = ['PATIENT', 'DOCTOR', 'ADMIN'];

  static const _roleColors = {
    'ADMIN': Color(0xFFEC4899),
    'DOCTOR': Color(0xFF3B82F6),
    'PATIENT': Color(0xFF10B981),
  };

  static const _roleLabels = {
    'ADMIN': 'Admin',
    'DOCTOR': 'Bác sĩ',
    'PATIENT': 'Bệnh nhân',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)));
          if (state is AdminError) return _buildError(context, state.message);
          if (state is UsersLoaded) return _buildList(context, state.users);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF020617),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Quản lý người dùng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadUsers()),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B), height: 1)),
      );

  Widget _buildList(BuildContext context, List<AdminUserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('Không có người dùng nào', style: TextStyle(color: Color(0xFF64748B))));
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
          for (final role in ['ADMIN', 'DOCTOR', 'PATIENT'])
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
    final adminCount = users.where((u) => u.role == 'ADMIN').length;
    final doctorCount = users.where((u) => u.role == 'DOCTOR').length;
    final patientCount = users.where((u) => u.role == 'PATIENT').length;
    return Row(children: [
      _buildStatChip('Admin', adminCount, const Color(0xFFEC4899)),
      const SizedBox(width: 8),
      _buildStatChip('Bác sĩ', doctorCount, const Color(0xFF3B82F6)),
      const SizedBox(width: 8),
      _buildStatChip('Bệnh nhân', patientCount, const Color(0xFF10B981)),
    ]);
  }

  Widget _buildStatChip(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
      ]),
    ),
  );

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
    final color = _roleColors[user.role] ?? const Color(0xFF64748B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(user.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ]),
        ),
        DropdownButton<String>(
          value: user.role,
          dropdownColor: const Color(0xFF1E293B),
          underline: const SizedBox.shrink(),
          icon: const Icon(LucideIcons.chevronsUpDown, color: Color(0xFF475569), size: 16),
          items: _roles.map((r) => DropdownMenuItem(
            value: r,
            child: Text(_roleLabels[r] ?? r, style: TextStyle(color: _roleColors[r], fontSize: 13, fontWeight: FontWeight.w600)),
          )).toList(),
          onChanged: (newRole) {
            if (newRole == null || newRole == user.role) return;
            _confirmRoleChange(context, user, newRole);
          },
        ),
      ]),
    );
  }

  void _confirmRoleChange(BuildContext context, AdminUserModel user, String newRole) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Thay đổi quyền', style: TextStyle(color: Colors.white)),
        content: Text(
          'Đổi quyền "${user.name}" từ ${_roleLabels[user.role]} → ${_roleLabels[newRole]}?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(UpdateUserRole(user.id, newRole));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 48),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.read<AdminBloc>().add(LoadUsers()), child: const Text('Thử lại')),
      ]),
    ),
  );
}
