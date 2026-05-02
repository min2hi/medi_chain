import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/logic/medical/medical_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/app_skeleton.dart';

class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MedicalBloc>()..add(RecordsFetchRequested()),
      child: Scaffold(
        
        appBar: AppBar(
          title: Text(
            'records.title'.tr(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Color(0xFF14B8A6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(LucideIcons.plus, size: 20, color: Colors.white),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => context.push('/record-form').then(
                  (_) => context.read<MedicalBloc>().add(RecordsFetchRequested()),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<MedicalBloc, MedicalState>(
          builder: (context, state) {
            if (state is MedicalLoading) {
              return const AppSkeletonList(count: 5);
            }
            if (state is MedicalError) {
              return _buildErrorState(context, state.message);
            }
            if (state is RecordsLoaded) {
              if (state.records.isEmpty) return _buildEmptyState(context);
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<MedicalBloc>().add(RecordsFetchRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) =>
                      _buildRecordCard(context, state.records[index]),
                ),
              );
            }
            return SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF115E59) : Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.fileText,
                size: 52,
                color: Color(0xFF93C5FD),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'records.empty'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'records.empty_sub'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
            ),
            SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/record-form').then(
                (_) => context.read<MedicalBloc>().add(RecordsFetchRequested()),
              ),
              icon: Icon(LucideIcons.plus, size: 18),
              label: Text('records.add'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Color(0xFFDC2626)),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<MedicalBloc>().add(RecordsFetchRequested()),
              child: Text('records.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, MedicalRecordModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/record-form', extra: record).then(
          (_) => context.read<MedicalBloc>().add(RecordsFetchRequested()),
        ),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Accent left bar
                Container(width: 5, color: Color(0xFF14B8A6)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                record.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        // Meta row
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            _metaTag(context, LucideIcons.calendar,
                              DateFormat('dd/MM/yyyy').format(DateTime.parse(record.date)),
                            ),
                            if (record.hospital != null)
                              _metaTag(context, LucideIcons.building2, record.hospital!),
                          ],
                        ),
                        if (record.diagnosis != null) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF115E59) : Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              record.diagnosis!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF14B8A6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaTag(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Color(0xFF94A3B8)),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }
}
