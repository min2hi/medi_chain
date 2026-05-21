/// PrescriptionParser — On-device parser đơn thuốc giấy VN.
///
/// Input: raw OCR text từ Google ML Kit
/// Output: danh sách [ParsedMedicine] để user review trước khi lưu
///
/// Hỗ trợ:
///   - Đơn đánh số thứ tự: "1. Paracetamol 500mg"
///   - Đơn không đánh số: "Paracetamol 500mg\nUống 2 viên..."
///   - Có/không có dấu tiếng Việt (OCR đôi khi mất dấu)
///   - Liều viên/ngày, sáng/chiều/tối, X lần/ngày
library;

class ParsedMedicine {
  final String name;
  final String dosage;
  final String frequency;
  final String instruction;
  final int? durationDays;

  const ParsedMedicine({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.instruction = '',
    this.durationDays,
  });

  ParsedMedicine copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? instruction,
    int? durationDays,
  }) =>
      ParsedMedicine(
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        instruction: instruction ?? this.instruction,
        durationDays: durationDays ?? this.durationDays,
      );

  @override
  String toString() =>
      'ParsedMedicine(name: $name, dosage: $dosage, freq: $frequency, dur: $durationDays)';
}

class PrescriptionParser {
  // ── Từ khóa cần bỏ qua (header/footer đơn thuốc) ─────────────────────────
  static const _skipKeywords = [
    'bác sĩ', 'bac si', 'phòng khám', 'phong kham',
    'bệnh viện', 'benh vien', 'họ tên', 'ho ten',
    'địa chỉ', 'dia chi', 'chẩn đoán', 'chan doan',
    'chuẩn đoán', 'khám', 'tái khám', 'tai kham',
    'chữ ký', 'chu ky', 'đơn thuốc', 'don thuoc',
    'hướng dẫn', 'huong dan', 'lưu ý', 'luu y',
    'bs.', 'bs ', 'dr.', 'dr ', 'rx:', 'đơn số', 'ngày khám',
    'tuổi', 'tuoi', 'giới tính', 'gioi tinh', 'địa chỉ',
  ];

  // ── Từ khóa instruction (không phải tên thuốc) ────────────────────────────
  static const _instrWords = [
    'uống', 'uong', 'dùng', 'dung', 'sau', 'trước', 'truoc',
    'sáng', 'sang', 'chiều', 'chieu', 'tối', 'toi', 'trưa', 'trua',
    'viên', 'vien', 'gói', 'goi', 'ống', 'ong', 'lần', 'lan',
    'ngày', 'ngay', 'trong', 'khi', 'bữa', 'bua', 'ăn', 'an',
    'buổi', 'buoi',
  ];

  // ── Patterns ──────────────────────────────────────────────────────────────

  /// Tên thuốc: bắt đầu bằng chữ hoa, 2-5 từ, theo sau là hàm lượng
  static final _rxNameLine = RegExp(
    r'^(?:\d+[\.\)]\s*)?'                        // số thứ tự tuỳ chọn
    r'([A-ZÀ-Ỹa-zà-ỹ][A-Za-zÀ-ỹà-ỹ0-9\s\-]+?)' // tên thuốc
    r'\s*(\d+(?:[,.]\d+)?\s*'                     // hàm lượng số
    r'(?:mg|mcg|g|ml|IU|đv|%)'                   // đơn vị
    r'(?:/\d+\s*(?:ml|g))?)?'                     // ví dụ /5ml
    r'\s*$',
    caseSensitive: false,
  );

  /// Liều lượng: "2 viên", "1 gói", "500mg", "10ml"
  static final _rxDosage = RegExp(
    r'(\d+(?:[,.]\d+)?)\s*(viên|vien|gói|goi|ống|ong|ml|mg|mcg|g|giọt|giot|thìa|thia)',
    caseSensitive: false,
  );

  /// Tần suất dạng số: "3 lần/ngày", "2 lần mỗi ngày", "1 viên/ngày"
  static final _rxFreqNumeric = RegExp(
    r'(\d+)\s*(?:l[aầ]n|vien|viên)\s*[/x×]\s*ng[aà]y'
    r'|(\d+)\s*(?:l[aầ]n|vien|viên)\s*m[oỗ]i\s*ng[aà]y'
    r'|(\d+)\s*(?:vien|viên|goi|gói)\s*/\s*ng[aà]y',
    caseSensitive: false,
  );

  /// Buổi trong ngày: "sáng", "chiều", "tối", "trưa" — bất kỳ kết hợp nào
  static final _rxSession = RegExp(
    r'\b(s[aá]ng|chi[eề]u|t[oố]i|tr[uư]a)\b',
    caseSensitive: false,
  );

  /// Thời gian dùng: "5 ngày", "1 tuần", "2 tháng"
  static final _rxDuration = RegExp(
    r'(\d+)\s*(ng[aà]y|tu[aầ]n|th[aá]ng)',
    caseSensitive: false,
  );

  /// Hướng dẫn uống
  static final _rxInstruction = RegExp(
    r'(sau\s*(?:khi\s*)?[aă]n'
    r'|tr[uư][oớ]c\s*(?:khi\s*)?[aă]n'
    r'|trong\s*b[uữ]a\s*[aă]n'
    r'|l[uú]c\s*[dđ][oó]i'
    r'|khi\s*[dđ]i\s*ng[uủ])',
    caseSensitive: false,
  );

  // ── Public entry point ─────────────────────────────────────────────────────

  static List<ParsedMedicine> parse(String ocrText) {
    final lines = _cleanLines(ocrText);
    if (lines.isEmpty) return [];

    // Ưu tiên parse theo số thứ tự nếu có
    final numbered = _parseNumbered(lines);
    if (numbered.isNotEmpty) return numbered;

    // Fallback: parse theo block dòng tên thuốc
    return _parseByMedicineLine(lines);
  }

  // ── Strategy 1: Đơn có đánh số thứ tự ────────────────────────────────────
  static List<ParsedMedicine> _parseNumbered(List<String> lines) {
    final groups = <List<String>>[];
    var current = <String>[];

    for (final line in lines) {
      if (RegExp(r'^\d+[\.\)]\s+\S').hasMatch(line)) {
        if (current.isNotEmpty) groups.add(List.from(current));
        current = [line];
      } else if (current.isNotEmpty) {
        current.add(line);
      }
    }
    if (current.isNotEmpty) groups.add(current);
    if (groups.isEmpty) return [];

    return groups
        .map(_parseGroup)
        .whereType<ParsedMedicine>()
        .toList();
  }

  // ── Strategy 2: Đơn không đánh số ────────────────────────────────────────
  static List<ParsedMedicine> _parseByMedicineLine(List<String> lines) {
    final results = <ParsedMedicine>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isSkipLine(line)) continue;
      if (_isInstructionLine(line)) continue;

      // Thử strict match trước (tên thuốc riêng dòng)
      var nd = _extractNameAndDosage(line);

      // Fallback: dòng dạng "Paracetamol 500mg uong 2 vien..." — inline format
      nd ??= _extractNameFromInlineLine(line);

      if (nd == null) continue;

      // Thu thập body lines tiếp theo
      final body = <String>[];
      for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
        final nextNd = _extractNameAndDosage(lines[j])
            ?? _extractNameFromInlineLine(lines[j]);
        if (nextNd != null && !_isInstructionLine(lines[j])) break;
        body.add(lines[j]);
      }

      final allText = [line, ...body].join(' ');
      results.add(_buildMedicine(nd.$1, nd.$2, allText));
    }
    return results;
  }

  // ── Lenient extract cho dòng inline: "Paracetamol 500mg uong 2 vien" ─────
  /// Lấy phần tên thuốc trước khi gặp instruction word hoặc số liều
  static (String, String)? _extractNameFromInlineLine(String line) {
    final words = line.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return null;

    final nameWords = <String>[];
    String dosage = '';

    for (int i = 0; i < words.length; i++) {
      final w = words[i].toLowerCase();

      // Gặp instruction word → dừng
      if (_instrWords.contains(w)) break;

      // Gặp hàm lượng (500mg, 10ml...) → đây là dosage, dừng tên
      final dosageMatch = RegExp(
        r'^\d+(?:[,.]\d+)?\s*(?:mg|mcg|g|ml|IU|%)',
        caseSensitive: false,
      ).firstMatch(words[i]);

      if (dosageMatch != null) {
        dosage = words[i];
        break;
      }

      // Gặp số đứng đầu → có thể là liều lượng, dừng
      if (RegExp(r'^\d').hasMatch(w) && nameWords.isNotEmpty) break;

      nameWords.add(words[i]);
    }

    if (nameWords.isEmpty || nameWords.length > 5) return null;
    final name = nameWords.join(' ');
    if (name.length < 3) return null;

    return (name, dosage);
  }

  // ── Parse 1 group ─────────────────────────────────────────────────────────
  static ParsedMedicine? _parseGroup(List<String> group) {
    if (group.isEmpty) return null;
    final header = group.first;
    if (_isSkipLine(header)) return null;

    // Strip số thứ tự: "1. Paracetamol 500mg" → "Paracetamol 500mg"
    final stripped = header.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim();
    final nd = _extractNameAndDosage(stripped);
    if (nd == null) return null;

    final allText = group.join(' ');
    return _buildMedicine(nd.$1, nd.$2, allText);
  }

  // ── Build ParsedMedicine từ name, dosage hint và toàn bộ text block ───────
  static ParsedMedicine _buildMedicine(
      String name, String dosageHint, String allText) {
    // Dosage: ưu tiên từ tên thuốc, fallback từ body
    final dosage = dosageHint.isNotEmpty
        ? dosageHint
        : (_rxDosage.firstMatch(allText)?.group(0) ?? '');

    // Frequency
    final frequency = _extractFrequency(allText);

    // Duration
    final durationDays = _extractDuration(allText);

    // Instruction
    final instruction = _extractInstruction(allText);

    return ParsedMedicine(
      name: _capitalizeName(name),
      dosage: dosage,
      frequency: frequency,
      instruction: instruction,
      durationDays: durationDays,
    );
  }

  // ── Extract name + dosage từ 1 dòng ──────────────────────────────────────
  static (String, String)? _extractNameAndDosage(String line) {
    final m = _rxNameLine.firstMatch(line.trim());
    if (m == null) return null;

    final name = m.group(1)?.trim() ?? '';
    final dosage = m.group(2)?.trim() ?? '';

    // Validation
    if (name.length < 3) return null;
    if (name.split(' ').length > 5) return null;

    // Không phải tên thuốc nếu chứa instruction words
    final nameLower = name.toLowerCase();
    final wordList = nameLower.split(RegExp(r'\s+'));
    final instrHits = wordList.where((w) => _instrWords.contains(w)).length;
    if (instrHits >= 1) return null;

    return (name, dosage);
  }

  // ── Extract frequency ─────────────────────────────────────────────────────
  static String _extractFrequency(String text) {
    // 1. Tìm dạng số trước: "3 lần/ngày", "1 viên/ngày"
    final numericMatch = _rxFreqNumeric.firstMatch(text);
    if (numericMatch != null) return numericMatch.group(0)!.trim();

    // 2. Tìm các buổi trong ngày: sáng, chiều, tối, trưa
    final sessions = <String>{};
    for (final m in _rxSession.allMatches(text)) {
      final s = m.group(1)!.toLowerCase();
      if (s.startsWith('s')) sessions.add('Sáng');
      else if (s.startsWith('tr')) sessions.add('Trưa');
      else if (s.startsWith('ch') || s.startsWith('c')) sessions.add('Chiều');
      else if (s.startsWith('t')) sessions.add('Tối');
    }

    // Sắp xếp theo thứ tự trong ngày
    final order = ['Sáng', 'Trưa', 'Chiều', 'Tối'];
    final sorted = order.where(sessions.contains).toList();
    if (sorted.isNotEmpty) return sorted.join(' - ');

    return '';
  }

  // ── Extract duration ──────────────────────────────────────────────────────
  static int? _extractDuration(String text) {
    final m = _rxDuration.firstMatch(text);
    if (m == null) return null;
    final val = int.tryParse(m.group(1) ?? '') ?? 0;
    final unit = m.group(2)!.toLowerCase();
    if (unit.startsWith('tu')) return val * 7;   // tuần
    if (unit.startsWith('th')) return val * 30;  // tháng
    return val;                                   // ngày
  }

  // ── Extract instruction ───────────────────────────────────────────────────
  static String _extractInstruction(String text) {
    final m = _rxInstruction.firstMatch(text.toLowerCase());
    if (m == null) return '';
    final raw = m.group(0) ?? '';
    return raw.isEmpty ? '' : raw[0].toUpperCase() + raw.substring(1);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static bool _isSkipLine(String line) {
    final lower = line.toLowerCase();
    return _skipKeywords.any((kw) => lower.contains(kw));
  }

  static bool _isInstructionLine(String line) {
    final lower = line.toLowerCase();
    // Dòng bắt đầu bằng instruction word → không phải tên thuốc
    final firstWord = lower.split(RegExp(r'\s+')).first;
    return _instrWords.contains(firstWord);
  }

  static List<String> _cleanLines(String text) => text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && l.length > 2)
      .toList();

  static String _capitalizeName(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
