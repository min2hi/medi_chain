import 'package:flutter_test/flutter_test.dart';

List<String> findDuplicateMeds(List<String> names) {
  final activeMeds = names
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toList();
  
  final seen = <String>{};
  final duplicates = <String>[];
  for (final med in activeMeds) {
    if (seen.contains(med)) {
      if (!duplicates.contains(med)) {
        duplicates.add(med);
      }
    } else {
      seen.add(med);
    }
  }
  return duplicates;
}

void main() {
  group('Clinical Validation Test - Duplicate Medication Detection', () {
    test('should return empty list when no medications', () {
      expect(findDuplicateMeds([]), isEmpty);
    });

    test('should return empty list when no duplicate medications exist', () {
      expect(
        findDuplicateMeds(['Paracetamol', 'Ibuprofen', 'Amoxicillin']),
        isEmpty,
      );
    });

    test('should detect duplicates case-insensitively and ignore whitespaces', () {
      expect(
        findDuplicateMeds(['Paracetamol ', ' paracetamol', 'Ibuprofen']),
        equals(['paracetamol']),
      );
    });

    test('should handle multiple duplicates correctly', () {
      expect(
        findDuplicateMeds([
          'Paracetamol', 
          'Ibuprofen', 
          'paracetamol', 
          'Amoxicillin', 
          'ibuprofen'
        ]),
        unorderedEquals(['paracetamol', 'ibuprofen']),
      );
    });
  });
}
