import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/providers.dart';

void main() {
  test('Thai sort ignores leading vowels', () {
    final titles = ['เซเรน', 'ไลรา', 'กัปตัน', 'ออร์ริน', 'เข็มทิศ']..sort(thaiCompare);
    // เข็มทิศ sorts under ข, เซเรน under ซ, ไลรา under ล.
    expect(titles, ['กัปตัน', 'เข็มทิศ', 'เซเรน', 'ไลรา', 'ออร์ริน']);
  });
}
