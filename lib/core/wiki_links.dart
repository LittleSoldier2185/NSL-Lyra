/// Parsing helpers for `[[title]]` links used in entry bodies.
final _linkRe = RegExp(r'\[\[([^\[\]]+)\]\]');

class BodySegment {
  const BodySegment(this.text, {this.isLink = false});

  /// Plain text, or the link target when [isLink] is true.
  final String text;
  final bool isLink;
}

/// Splits [body] into plain-text and link segments, preserving order.
List<BodySegment> parseBody(String body) {
  final out = <BodySegment>[];
  var last = 0;
  for (final m in _linkRe.allMatches(body)) {
    if (m.start > last) out.add(BodySegment(body.substring(last, m.start)));
    out.add(BodySegment(m.group(1)!.trim(), isLink: true));
    last = m.end;
  }
  if (last < body.length) out.add(BodySegment(body.substring(last)));
  return out;
}

/// Unique link targets referenced in [body], in first-seen order.
List<String> extractLinks(String body) {
  final seen = <String>{};
  for (final m in _linkRe.allMatches(body)) {
    seen.add(m.group(1)!.trim());
  }
  return seen.toList();
}

/// Replaces `[[x]]` with `x`.
String stripLinks(String body) =>
    body.replaceAllMapped(_linkRe, (m) => m.group(1)!.trim());

/// Rewrites every `[[from]]` in [body] to `[[to]]`.
String renameLinkTarget(String body, String from, String to) =>
    body.replaceAllMapped(_linkRe, (m) => m.group(1)!.trim() == from ? '[[$to]]' : m.group(0)!);

/// A short excerpt of [body] around the first link to [target], links stripped.
String? backlinkSnippet(String body, String target, {int before = 40, int after = 50}) {
  final plain = stripLinks(body);
  final at = plain.indexOf(target);
  if (at < 0) return null;
  final start = (at - before).clamp(0, plain.length);
  final end = (at + target.length + after).clamp(0, plain.length);
  return '${start > 0 ? '…' : ''}${plain.substring(start, end)}${end < plain.length ? '…' : ''}';
}

/// If the caret sits inside an unclosed `[[`, returns the query typed so far
/// and where the `[[` begins (for autocomplete). Otherwise null.
({String query, int start})? activeLinkQuery(String text, int caret) {
  if (caret < 2 || caret > text.length) return null;
  final before = text.substring(0, caret);
  final open = before.lastIndexOf('[[');
  if (open < 0) return null;
  final tail = before.substring(open + 2);
  if (tail.contains(']') || tail.contains('\n')) return null;
  return (query: tail, start: open);
}
