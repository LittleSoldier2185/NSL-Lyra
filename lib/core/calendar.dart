import 'dart:convert';

/// A world's custom calendar, stored as JSON in `Worlds.calendarConfig`.
/// Only naming is configurable: dates are (year, month?, day?) and sort numerically.
class CalendarConfig {
  const CalendarConfig({this.yearLabel = 'ปีที่', this.months = const []});

  /// Printed before the year, e.g. "ปีที่ 401".
  final String yearLabel;

  /// Month names in order; empty means months are shown as plain numbers.
  final List<String> months;

  factory CalendarConfig.parse(String json) {
    try {
      final m = jsonDecode(json);
      if (m is! Map) return const CalendarConfig();
      return CalendarConfig(
        yearLabel: (m['yearLabel'] as String?) ?? 'ปีที่',
        months: (m['months'] is List) ? (m['months'] as List).map((e) => e.toString()).toList() : const [],
      );
    } on FormatException {
      return const CalendarConfig();
    }
  }

  String encode() => jsonEncode({'yearLabel': yearLabel, 'months': months});

  String monthName(int month) =>
      month >= 1 && month <= months.length ? months[month - 1] : 'เดือน $month';

  /// "12 เดือนหมอก ปีที่ 401", "เดือนหมอก ปีที่ 401" or "ปีที่ 401".
  String format(WorldDate d) {
    final year = '${yearLabel.isEmpty ? '' : '$yearLabel '}${d.year}';
    final parts = <String>[
      if (d.month != null && d.day != null) '${d.day}',
      if (d.month != null) monthName(d.month!),
      year,
    ];
    return parts.join(' ');
  }

  /// A span: "ปีที่ 401" , "12 – 13 เดือนหมอก ปีที่ 401" or "… – …" across larger gaps.
  String formatSpan(WorldDate start, WorldDate? end) {
    if (end == null || end.compareTo(start) == 0) return format(start);
    return '${format(start)} – ${format(end)}';
  }
}

class WorldDate implements Comparable<WorldDate> {
  const WorldDate(this.year, [this.month, this.day]);
  final int year;
  final int? month;
  final int? day;

  /// Missing month/day sort before any real one in the same year.
  @override
  int compareTo(WorldDate o) {
    final y = year.compareTo(o.year);
    if (y != 0) return y;
    final m = (month ?? 0).compareTo(o.month ?? 0);
    if (m != 0) return m;
    return (day ?? 0).compareTo(o.day ?? 0);
  }
}
