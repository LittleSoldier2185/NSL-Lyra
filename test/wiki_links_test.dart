import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_writer_tools/core/wiki_links.dart';

void main() {
  test('parseBody splits text and links', () {
    final s = parseBody('เกิดที่ [[ท่าเรือโคราล]] และ [[สมาคมเข็มทิศ]]');
    expect(s.map((e) => e.isLink), [false, true, false, true]);
    expect(s[1].text, 'ท่าเรือโคราล');
  });

  test('extractLinks dedupes', () {
    expect(extractLinks('[[a]] [[b]] [[a]]'), ['a', 'b']);
  });

  test('backlinkSnippet strips links and trims', () {
    final snip = backlinkSnippet('พ่อ [[ออร์ริน]] หายไป', 'ออร์ริน');
    expect(snip, 'พ่อ ออร์ริน หายไป');
  });

  test('activeLinkQuery detects open brackets', () {
    expect(activeLinkQuery('อยู่กับ [[เ', 11)?.query, 'เ');
    expect(activeLinkQuery('[[done]] ต่อ', 12), isNull);
    expect(activeLinkQuery('ไม่มี', 3), isNull);
  });
}
