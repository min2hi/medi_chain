import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/logic/metric/metric_bloc.dart';

class HealthMetricsScreen extends StatelessWidget {
  const HealthMetricsScreen({super.key});

  // Map metric type → (icon, accent color, background color)
  static const _metricStyles = <String, _MetricStyle>{
    'nhịp tim':   _MetricStyle(LucideIcons.heart,    Color(0xFFDC2626), Color(0xFFFEF2F2)),
    'huyết áp':   _MetricStyle(LucideIcons.activity, Color(0xFFEA580C), Color(0xFFFFF7ED)),
    'đường huyết': _MetricStyle(LucideIcons.droplet, Color(0xFF16A34A), Color(0xFFF0FDF4)),
    'cân nặng':   _MetricStyle(LucideIcons.scale,    Color(0xFF7C3AED), Color(0xFFEDE9FE)),
  };

  static _MetricStyle _styleFor(String type) {
    final key = type.toLowerCase();
    for (final entry in _metricStyles.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return const _MetricStyle(LucideIcons.activity, Color(0xFF14B8A6), Color(0xFFF0FDFA));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MetricBloc>()..add(MetricsFetchRequested()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Chỉ số sức khỏe',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _showAddMetricSheet(ctx),
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<MetricBloc, MetricState>(
          listener: (context, state) {
            if (state is MetricActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(children: [
                    Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Đã lưu chỉ số thành công'),
                  ]),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is MetricLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MetricError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.read<MetricBloc>().add(MetricsFetchRequested()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (state is MetricsLoaded) {
              if (state.metrics.isEmpty) return _buildEmptyState();
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<MetricBloc>().add(MetricsFetchRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: state.metrics.length,
                  itemBuilder: (_, i) => _buildMetricCard(state.metrics[i]),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.activity, size: 52, color: Color(0xFF93C5FD)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có chỉ số nào',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn + để thêm chỉ số sức khỏe đầu tiên.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(HealthMetricModel metric) {
    final date = DateTime.parse(metric.date);
    final style = _styleFor(metric.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(date),
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${metric.value}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: style.color,
                ),
              ),
              Text(
                metric.unit,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMetricSheet(BuildContext context) {
    final valueCtrl = TextEditingController();
    String selectedType = 'Nhịp tim';
    String unit = 'bpm';

    final types = {
      'Nhịp tim': 'bpm',
      'Huyết áp': 'mmHg',
      'Đường huyết': 'mmol/L',
      'Cân nặng': 'kg',
    };

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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thêm chỉ số sức khỏe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Type selector chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types.keys.map((t) {
                      final isSelected = t == selectedType;
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          selectedType = t;
                          unit = types[t]!;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF14B8A6) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Giá trị ($unit)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      suffix: Text(unit, style: const TextStyle(color: Color(0xFF64748B))),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(valueCtrl.text);
                        if (val == null) return;
                        context.read<MetricBloc>().add(
                          MetricCreateRequested({
                            'type': selectedType,
                            'value': val,
                            'unit': unit,
                            'date': DateTime.now().toIso8601String(),
                          }),
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Lưu chỉ số',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  const _MetricStyle(this.icon, this.color, this.bg);
}
