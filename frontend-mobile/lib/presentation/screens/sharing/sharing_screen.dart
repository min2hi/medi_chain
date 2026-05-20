import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/sharing/sharing_bloc.dart';
import 'package:medi_chain_mobile/data/models/ai_models.dart';

class SharingScreen extends StatelessWidget {
  const SharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SharingBloc>()..add(SharingLoadRequested()),
      child: const _SharingView(),
    );
  }
}

class _SharingView extends StatefulWidget {
  const _SharingView();

  @override
  State<_SharingView> createState() => _SharingViewState();
}

class _SharingViewState extends State<_SharingView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateShareSheet(BuildContext blocContext) {
    final emailCtrl = TextEditingController();
    String selectedType = 'VIEW';
    DateTime? expiresAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Chia sẻ hồ sơ mới',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nhập email người bạn muốn chia sẻ hồ sơ sức khỏe.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 20),

                  // Email
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email người nhận *',
                      hintText: 'example@email.com',
                      prefixIcon: Icon(
                        LucideIcons.mail,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Permission type
                  Text(
                    'Quyền truy cập',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption(
                        setSheetState,
                        value: 'VIEW',
                        label: 'Chỉ xem',
                        icon: LucideIcons.eye,
                        selected: selectedType,
                        onTap: () => setSheetState(() => selectedType = 'VIEW'),
                      ),
                      SizedBox(width: 12),
                      _buildTypeOption(
                        setSheetState,
                        value: 'MANAGE',
                        label: 'Toàn quyền',
                        icon: LucideIcons.shieldCheck,
                        selected: selectedType,
                        onTap: () =>
                            setSheetState(() => selectedType = 'MANAGE'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Expiry date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheetState(() => expiresAt = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 10),
                          Text(
                            expiresAt != null
                                ? 'Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiresAt!)}'
                                : 'Ngày hết hạn (tuỳ chọn)',
                            style: TextStyle(
                              color: expiresAt != null
                                  ? Color(0xFF1E293B)
                                  : Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty) return;
                        Navigator.pop(context);
                        blocContext.read<SharingBloc>().add(
                              SharingCreateRequested(
                                email: email,
                                type: selectedType,
                                expiresAt: expiresAt?.toIso8601String(),
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Xác nhận chia sẻ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeOption(
    StateSetter setSheetState, {
    required String value,
    required String label,
    required IconData icon,
    required String selected,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFFF0FDFA)
                : Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Color(0xFF14B8A6)
                  : Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Color(0xFF14B8A6)
                    : Color(0xFF94A3B8),
              ),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Color(0xFF14B8A6)
                      : Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(
          'Chia sẻ hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF14B8A6),
          unselectedLabelColor: Color(0xFF94A3B8),
          indicatorColor: Color(0xFF14B8A6),
          labelStyle:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(LucideIcons.userCheck, size: 18), text: 'Đang chia sẻ'),
            Tab(icon: Icon(LucideIcons.inbox, size: 18), text: 'Nhận được'),
          ],
        ),
      ),
      body: BlocConsumer<SharingBloc, SharingState>(
        listener: (context, state) {
          if (state is SharingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          if (state is SharingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (blocContext, state) {
          if (state is SharingLoading || state is SharingInitial) {
            return Center(child: CircularProgressIndicator());
          }

          final List<SharingModel> mySharings = switch (state) {
            SharingLoaded() => state.mySharings,
            SharingActionSuccess() => state.mySharings,
            _ => [],
          };
          final List<SharingModel> sharedWithMe = switch (state) {
            SharingLoaded() => state.sharedWithMe,
            SharingActionSuccess() => state.sharedWithMe,
            _ => [],
          };

          return Column(
            children: [
              // Info banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF99F6E4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 18,
                      color: Color(0xFF14B8A6),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dữ liệu được mã hoá. Bạn có thể thu hồi quyền bất cứ lúc nào.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: My Sharings (outbound)
                    RefreshIndicator(
                      onRefresh: () async =>
                          blocContext.read<SharingBloc>().add(
                                SharingLoadRequested(),
                              ),
                      child: mySharings.isEmpty
                          ? _buildEmpty(
                              icon: LucideIcons.share2,
                              title: 'Chưa chia sẻ với ai',
                              subtitle:
                                  'Chia sẻ hồ sơ với bác sĩ hoặc người thân để cùng theo dõi.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: mySharings.length,
                              itemBuilder: (ctx, i) => _buildSharingCard(
                                blocContext,
                                mySharings[i],
                                isOutbound: true,
                              ),
                            ),
                    ),

                    // Tab 2: Shared With Me (inbound)
                    RefreshIndicator(
                      onRefresh: () async =>
                          blocContext.read<SharingBloc>().add(
                                SharingLoadRequested(),
                              ),
                      child: sharedWithMe.isEmpty
                          ? _buildEmpty(
                              icon: LucideIcons.inbox,
                              title: 'Chưa ai chia sẻ với bạn',
                              subtitle:
                                  'Khi ai đó chia sẻ hồ sơ cho bạn, nó sẽ xuất hiện tại đây.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: sharedWithMe.length,
                              itemBuilder: (ctx, i) => _buildSharingCard(
                                blocContext,
                                sharedWithMe[i],
                                isOutbound: false,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (blocContext) => FloatingActionButton.extended(
          onPressed: () => _showCreateShareSheet(blocContext),
          backgroundColor: Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          icon: Icon(LucideIcons.plus),
          label: Text(
            'Chia sẻ mới',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingCard(
    BuildContext blocContext,
    SharingModel item, {
    required bool isOutbound,
  }) {
    final displayUser = isOutbound ? item.toUser : item.fromUser;
    final initials =
        displayUser?.name?.isNotEmpty == true
            ? displayUser!.name![0].toUpperCase()
            : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOutbound
                  ? Color(0xFFCCFBF1)
                  : Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isOutbound
                      ? Color(0xFF14B8A6)
                      : Color(0xFF16A34A),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayUser?.name ?? 'Người dùng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  displayUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge(item.type),
                    if (item.expiresAt != null) ...[
                      SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yy').format(
                              DateTime.parse(item.expiresAt!),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action button
          if (isOutbound)
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 18),
              color: Color(0xFFDC2626),
              onPressed: () => _confirmRevoke(blocContext, item.id),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String type) {
    final isManage = type == 'MANAGE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isManage
            ? Color(0xFFFFF7ED)
            : Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isManage ? 'Toàn quyền' : 'Chỉ xem',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isManage ? Color(0xFFEA580C) : Color(0xFF16A34A),
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext blocContext, String sharingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Thu hồi quyền truy cập'),
        content: Text(
          'Bạn có chắc muốn thu hồi quyền truy cập này không? Người dùng sẽ không thể xem hồ sơ của bạn nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huá»·'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              blocContext
                  .read<SharingBloc>()
                  .add(SharingRevokeRequested(sharingId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text('Thu hồi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      children: [
        SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Color(0xFF94A3B8)),
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
