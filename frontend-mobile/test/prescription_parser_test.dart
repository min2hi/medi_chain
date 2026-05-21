/// Dart test script cho PrescriptionParser — chạy: dart run test/prescription_parser_test.dart
/// Validate parser với 4 sample đơn thuốc thực tế VN

// ignore_for_file: avoid_print

import 'package:medi_chain_mobile/core/utils/prescription_parser.dart';

void main() {
  // ── Sample 1: Đơn in, có số thứ tự, không dấu (OCR mất dấu) ──
  const s1 = '''
PHONG KHAM DA KHOA MEDICHAIN
Ho ten: Nguyen Van A - Tuoi: 35
Chan doan: Cam cum

1. Paracetamol 500mg
   Uong 2 vien x 3 lan/ngay sau an, 5 ngay

2. Amoxicillin 500mg
   1 vien x 2 lan/ngay (sang, toi), 7 ngay

3. Vitamin C 1000mg
   1 vien/ngay sau an, 10 ngay
''';

  // ── Sample 2: Đơn có dấu đầy đủ, có số ──
  const s2 = '''
1. Paracetamol 500mg
   Uống 2 viên x 3 lần/ngày sau ăn
   Dùng trong 5 ngày

2. Amoxicillin 500mg
   Sáng 1 viên, tối 1 viên
   7 ngày

3. Vitamin C 1000mg
   1 viên/ngày sau ăn, 10 ngày
''';

  // ── Sample 3: Đơn không đánh số ──
  const s3 = '''
Paracetamol 500mg uong 2 vien 3 lan/ngay
Amoxicillin 500mg sang chieu toi 1 vien 7 ngay
Vitamin C 1000mg 1 vien/ngay 10 ngay
''';

  // ── Sample 4: Đơn phức tạp với nhiều dòng mô tả ──
  const s4 = '''
PHONG KHAM ABC - BS. Nguyen Van B
Ngay kham: 21/05/2026

STT  Ten thuoc             Ham luong  So luong
1    Augmentin             625mg      14 vien
     Sang 1 vien, chieu 1 vien, sau an - 7 ngay

2    Loratadine            10mg       7 vien
     Uong 1 vien/ngay buoi toi truoc khi ngu

3    Omeprazole            20mg       10 vien
     Uong 1 vien sang truoc an 30 phut
''';

  _run('TEST 1 — Đơn không dấu, có số', s1);
  _run('TEST 2 — Đơn có dấu, có số', s2);
  _run('TEST 3 — Đơn không số', s3);
  _run('TEST 4 — Đơn bảng phức tạp', s4);
}

void _run(String label, String text) {
  print('\n═══════════════════════════════════');
  print('$label');
  print('═══════════════════════════════════');

  final results = PrescriptionParser.parse(text);

  if (results.isEmpty) {
    print('❌ FAIL — Không parse được thuốc nào!');
    return;
  }

  for (final m in results) {
    final ok = m.name.isNotEmpty;
    print('${ok ? "✅" : "❌"} ${m.name}');
    print('   dosage   : ${m.dosage.isEmpty ? "⚠️ trống" : m.dosage}');
    print('   frequency: ${m.frequency.isEmpty ? "⚠️ trống" : m.frequency}');
    print('   duration : ${m.durationDays != null ? "${m.durationDays} ngày" : "⚠️ null"}');
    print('   instr    : ${m.instruction.isEmpty ? "(trống)" : m.instruction}');
  }
  print('→ ${results.length} thuốc\n');
}
