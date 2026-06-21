import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:medi_chain_mobile/core/di/injection.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/presentation/widgets/shared/scale_on_tap.dart';
import 'package:shimmer/shimmer.dart';

class DoctorSlotsScreen extends StatefulWidget {
  const DoctorSlotsScreen({super.key});

  @override
  State<DoctorSlotsScreen> createState() => _DoctorSlotsScreenState();
}

class _DoctorSlotsScreenState extends State<DoctorSlotsScreen> {
  final ApiClient _api = getIt<ApiClient>();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _registeredSlots = [];
  bool _isLoading = false;

  // Khung giờ mặc định cho ca làm việc (Mỗi slot dài 1 tiếng)
  final List<Map<String, String>> _defaultTimeSlots = [
    {'start': '08:00', 'end': '09:00'},
    {'start': '09:00', 'end': '10:00'},
    {'start': '10:00', 'end': '11:00'},
    {'start': '11:00', 'end': '12:00'},
    {'start': '13:30', 'end': '14:30'},
    {'start': '14:30', 'end': '15:30'},
    {'start': '15:30', 'end': '16:30'},
    {'start': '16:30', 'end': '17:30'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/user/doctor/slots');
      if (res.data != null && res.data['success'] == true) {
        final List<dynamic> list = res.data['data'];
        setState(() {
          _registeredSlots = list.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch làm việc: $e', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Lọc các slot đã đăng ký trùng với ngày đang chọn
  List<Map<String, dynamic>> get _slotsForSelectedDate {
    final targetDateStr = _selectedDate.toIso8601String().substring(0, 10);
    return _registeredSlots.where((slot) {
      final startStr = slot['startTime'] as String;
      final localDate = DateTime.parse(startStr).toLocal();
      final localDateStr = localDate.toIso8601String().substring(0, 10);
      return localDateStr == targetDateStr;
    }).toList();
  }

  // Helper để lấy slot đã đăng ký cho một khung giờ nhất định
  Map<String, dynamic>? _getRegisteredSlot(String startHour) {
    final slots = _slotsForSelectedDate;
    for (final slot in slots) {
      final localStart = DateTime.parse(slot['startTime']).toLocal();
      final localHourStr = '${localStart.hour.toString().padLeft(2, '0')}:${localStart.minute.toString().padLeft(2, '0')}';
      if (localHourStr == startHour) {
        return slot;
      }
    }
    return null;
  }

  Future<void> _toggleSlot(String startStr, String endStr) async {
    final existing = _getRegisteredSlot(startStr);

    final startParts = startStr.split(':');
    final endParts = endStr.split(':');

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    setState(() => _isLoading = true);

    try {
      if (existing != null) {
        // Nếu đã đăng ký thì xóa
        final res = await _api.delete('/user/doctor/slots/${existing['id']}');
        if (res.data != null && res.data['success'] == true) {
          _registeredSlots.removeWhere((item) => item['id'] == existing['id']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã hủy đăng ký ca khám $startStr - $endStr', style: GoogleFonts.inter()),
              backgroundColor: AppTheme.kPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Nếu chưa đăng ký thì thêm mới
        final res = await _api.post('/user/doctor/slots', data: {
          'startTime': startDateTime.toUtc().toIso8601String(),
          'endTime': endDateTime.toUtc().toIso8601String(),
        });
        if (res.data != null && res.data['success'] == true) {
          _registeredSlots.add(Map<String, dynamic>.from(res.data['data']));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã đăng ký ca khám thành công', style: GoogleFonts.inter()),
              backgroundColor: AppTheme.kSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      String msg = 'Có lỗi xảy ra';
      if (e is DioException && e.response?.data != null) {
        msg = e.response?.data['message'] ?? msg;
      } else {
        msg = e.toString();
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          title: Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppTheme.kError),
              const SizedBox(width: 8),
              Text('Không thể thay đổi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(msg, style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Đóng', style: GoogleFonts.inter(color: AppTheme.kPrimary)),
            )
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.kPrimary,
              onPrimary: Colors.white,
              onSurface: AppTheme.kTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Hai', 'Ba', 'Tư', 'Năm', 'Sáu', 'Bảy', 'CN'];
    final weekdayStr = weekdays[_selectedDate.weekday - 1];
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: AppBar(
        title: Text(
          'Đăng ký ca làm việc',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.kTextPrimary),
        ),
        backgroundColor: AppTheme.kSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppTheme.kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chọn ngày
          Container(
            color: AppTheme.kSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ScaleOnTap(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.kBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppTheme.kBorder),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendarDays, color: AppTheme.kPrimary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ngày khám bệnh', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.kTextSecondary)),
                          const SizedBox(height: 2),
                          Text('Thứ $weekdayStr, ngày $dateStr', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.kTextPrimary)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronDown, color: AppTheme.kTextMuted, size: 16),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'CHỌN KHUNG GIỜ LÀM VIỆC RẢNH',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.kTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),

          Expanded(
            child: _isLoading && _registeredSlots.isEmpty
                ? const _SlotsSkeleton()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _defaultTimeSlots.length,
                    itemBuilder: (context, i) {
                      final def = _defaultTimeSlots[i];
                      final registered = _getRegisteredSlot(def['start']!) != null;

                      return ScaleOnTap(
                        onTap: () => _toggleSlot(def['start']!, def['end']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: registered ? AppTheme.kPrimary : AppTheme.kSurface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: registered ? AppTheme.kPrimary : AppTheme.kBorder,
                              width: 1.5,
                            ),
                            boxShadow: registered
                                ? [
                                    BoxShadow(
                                      color: AppTheme.kPrimary.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : AppShadow.card,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  registered ? LucideIcons.checkCircle2 : LucideIcons.plus,
                                  size: 16,
                                  color: registered ? Colors.white : AppTheme.kTextSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${def['start']} - ${def['end']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: registered ? FontWeight.bold : FontWeight.w600,
                                    color: registered ? Colors.white : AppTheme.kTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            LinearProgressIndicator(color: AppTheme.kPrimary, backgroundColor: AppTheme.kSurface),
        ],
      ),
    );
  }
}

class _SlotsSkeleton extends StatelessWidget {
  const _SlotsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.kSurface,
      highlightColor: AppTheme.kBorder,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: 8,
        itemBuilder: (ctx, i) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
