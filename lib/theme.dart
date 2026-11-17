import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/database.dart';

/// One complete set of colours. [light] is the design handoff's paper palette;
/// [dark] is the "night" variant: the same warm hues on a dark brown ground.
class Palette {
  const Palette({
    required this.brightness,
    required this.bg,
    required this.bgPanel,
    required this.bgBar,
    required this.bgChip,
    required this.hover,
    required this.selected,
    required this.line,
    required this.lineSoft,
    required this.lineInput,
    required this.ink,
    required this.body,
    required this.inkSoft,
    required this.inkFaint,
    required this.accent,
    required this.accentDark,
    required this.accentTint,
    required this.accentLine,
    required this.saved,
    required this.danger,
    required this.summary,
    required this.snippet,
    required this.chipText,
    required this.border,
    required this.dash,
    required this.edge,
    required this.navIndicator,
    required this.types,
    required this.statuses,
  });

  final Brightness brightness;
  final Color bg, bgPanel, bgBar, bgChip, hover, selected, line, lineSoft, lineInput;
  final Color ink, body, inkSoft, inkFaint;
  final Color accent, accentDark, accentTint, accentLine, saved, danger;
  final Color summary, snippet, chipText, border, dash, edge, navIndicator;
  final Map<EntryType, Color> types;
  final Map<EntryStatus, (Color bg, Color fg)> statuses;

  static const light = Palette(
    brightness: Brightness.light,
    bg: Color(0xFFFBF8F2),
    bgPanel: Color(0xFFF7F3EB),
    bgBar: Color(0xFFF4EFE6),
    bgChip: Color(0xFFECE4D6),
    hover: Color(0xFFEAE0CE),
    selected: Color(0xFFE2D6BF),
    line: Color(0xFFD3C7B0),
    lineSoft: Color(0xFFE3D9C8),
    lineInput: Color(0xFFA89B84),
    ink: Color(0xFF1F1B16),
    body: Color(0xFF2A241E),
    inkSoft: Color(0xFF52493F),
    inkFaint: Color(0xFF6B6256),
    accent: Color(0xFFA8432A),
    accentDark: Color(0xFF8F3822),
    accentTint: Color(0xFFF6E4DC),
    accentLine: Color(0xFFD9A593),
    saved: Color(0xFF4F6D4F),
    danger: Color(0xFFB3261E),
    summary: Color(0xFF3A332B),
    snippet: Color(0xFF4F473E),
    chipText: Color(0xFF3F382F),
    border: Color(0xFFBBAE96),
    dash: Color(0xFF8F8470),
    edge: Color(0xFF8A7D66),
    navIndicator: Color(0xFFE2D3BC),
    types: {
      EntryType.character: Color(0xFF9A4A2E),
      EntryType.place: Color(0xFF3F6B4E),
      EntryType.org: Color(0xFF4A5A8A),
      EntryType.event: Color(0xFF8A6A2A),
      EntryType.item: Color(0xFF6A4A7A),
      EntryType.rule: Color(0xFF2F6A6E),
      EntryType.species: Color(0xFF7A5A3A),
    },
    statuses: {
      EntryStatus.idea: (Color(0xFFEAE3D6), Color(0xFF4F463C)),
      EntryStatus.draft: (Color(0xFFF3E4C3), Color(0xFF6B4F12)),
      EntryStatus.canon: (Color(0xFFD9E8D6), Color(0xFF2C5A3C)),
    },
  );

  static const dark = Palette(
    brightness: Brightness.dark,
    bg: Color(0xFF16130F),
    bgPanel: Color(0xFF1B1713),
    bgBar: Color(0xFF211C16),
    bgChip: Color(0xFF342D23),
    hover: Color(0xFF3A3228),
    selected: Color(0xFF483B2D),
    line: Color(0xFF4F463A),
    lineSoft: Color(0xFF3A3329),
    lineInput: Color(0xFF76695A),
    ink: Color(0xFFF0E9DC),
    body: Color(0xFFDDD4C5),
    inkSoft: Color(0xFFCABFAB),
    inkFaint: Color(0xFFA89E8B),
    accent: Color(0xFFE08A68),
    accentDark: Color(0xFFC9714F),
    accentTint: Color(0xFF3A241B),
    accentLine: Color(0xFF8A5440),
    saved: Color(0xFF9CC29C),
    danger: Color(0xFFF2877D),
    summary: Color(0xFFD6CDBE),
    snippet: Color(0xFFCFC5B3),
    chipText: Color(0xFFE0D8C8),
    border: Color(0xFF665A4A),
    dash: Color(0xFF9A8F7C),
    edge: Color(0xFF9C907A),
    navIndicator: Color(0xFF483B2D),
    types: {
      EntryType.character: Color(0xFFDD8A66),
      EntryType.place: Color(0xFF7FB68F),
      EntryType.org: Color(0xFF93A5DA),
      EntryType.event: Color(0xFFD7B463),
      EntryType.item: Color(0xFFB994CE),
      EntryType.rule: Color(0xFF72B8BC),
      EntryType.species: Color(0xFFC79D73),
    },
    statuses: {
      EntryStatus.idea: (Color(0xFF2D2822), Color(0xFFB2A794)),
      EntryStatus.draft: (Color(0xFF3A2F1B), Color(0xFFD7B463)),
      EntryStatus.canon: (Color(0xFF22352A), Color(0xFF8FC8A0)),
    },
  );
}

/// Design tokens. They read the palette in force, so a widget must read them
/// while building (not cache them in a `const`) to follow a theme switch.
class C {
  /// The palette in force. Set by [NslApp] from the theme mode.
  static Palette p = Palette.light;
  static bool get isDark => p.brightness == Brightness.dark;

  static Color get bg => p.bg;
  static Color get bgPanel => p.bgPanel;
  static Color get bgBar => p.bgBar;
  static Color get bgChip => p.bgChip;
  static Color get hover => p.hover;
  static Color get selected => p.selected;
  static Color get line => p.line;
  static Color get lineSoft => p.lineSoft;
  static Color get lineInput => p.lineInput;
  static Color get ink => p.ink;
  static Color get body => p.body;
  static Color get inkSoft => p.inkSoft;
  static Color get inkFaint => p.inkFaint;
  static Color get accent => p.accent;
  static Color get accentDark => p.accentDark;
  static Color get accentTint => p.accentTint;
  static Color get accentLine => p.accentLine;
  static Color get saved => p.saved;
  static Color get danger => p.danger;
  static Color get summary => p.summary;
  static Color get snippet => p.snippet;
  static Color get chipText => p.chipText;
  static Color get border => p.border;
  static Color get dash => p.dash;
  static Color get edge => p.edge;
  static Color get navIndicator => p.navIndicator;
}

class TypeMeta {
  const TypeMeta(this.label, this.color, this.glyph);
  final String label;
  final Color color;
  final String glyph;
}

const _typeLabels = <EntryType, (String label, String glyph)>{
  EntryType.character: ('ตัวละคร', 'ค'),
  EntryType.place: ('สถานที่', 'ส'),
  EntryType.org: ('องค์กร', 'อ'),
  EntryType.event: ('เหตุการณ์', 'ห'),
  EntryType.item: ('ไอเทม', 'ไ'),
  EntryType.rule: ('กฎของโลก', 'ก'),
  EntryType.species: ('เผ่าพันธุ์', 'ผ'),
};

/// Type label / colour / glyph, in the palette in force.
Map<EntryType, TypeMeta> get typeMeta => {
      for (final e in _typeLabels.entries) e.key: TypeMeta(e.value.$1, C.p.types[e.key]!, e.value.$2),
    };

class StatusMeta {
  const StatusMeta(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;
}

const _statusLabels = <EntryStatus, String>{
  EntryStatus.idea: 'ไอเดีย',
  EntryStatus.draft: 'ร่าง',
  EntryStatus.canon: 'canon',
};

/// Status label / badge colours, in the palette in force.
Map<EntryStatus, StatusMeta> get statusMeta => {
      for (final e in _statusLabels.entries)
        e.key: StatusMeta(e.value, C.p.statuses[e.key]!.$1, C.p.statuses[e.key]!.$2),
    };

/// Typography: Noto Serif Thai for content, IBM Plex Sans Thai for UI,
/// IBM Plex Mono for shortcuts. A null colour means the palette's default.
class T {
  /// Sizes in the layouts were drawn for a denser screen; small ones are lifted so hints,
  /// counts and labels stay readable (nothing below 13).
  static double _f(double s) => s <= 12 ? 13 : s <= 13 ? 14 : s <= 15 ? s + 1 : s;

  static TextStyle serif(double size, {FontWeight w = FontWeight.w400, Color? color, double? h}) =>
      GoogleFonts.notoSerifThai(fontSize: _f(size), fontWeight: w, color: color ?? C.ink, height: h);

  static TextStyle ui(double size, {FontWeight w = FontWeight.w400, Color? color, double? h}) =>
      GoogleFonts.ibmPlexSansThai(fontSize: _f(size), fontWeight: w, color: color ?? C.ink, height: h);

  static TextStyle mono(double size, {FontWeight w = FontWeight.w400, Color? color}) =>
      GoogleFonts.ibmPlexMono(fontSize: _f(size), fontWeight: w, color: color ?? C.inkFaint);
}

ThemeData buildTheme([Palette p = Palette.light]) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.brightness,
      surface: p.bg,
    ).copyWith(primary: p.accent, onPrimary: p.bg, onSurface: p.ink, onSurfaceVariant: p.inkSoft),
    scaffoldBackgroundColor: p.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansThaiTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink),
    dividerColor: p.line,
    canvasColor: p.bg,
    dialogTheme: DialogThemeData(backgroundColor: p.bg, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: p.bgPanel, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.bg, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, isDense: true),
    iconTheme: IconThemeData(color: p.inkSoft, size: 22),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: p.ink, iconSize: 22)),
    // Buttons must look like buttons: text buttons in the accent colour, outlined ones with a
    // border you can see, filled ones solid.
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.accent)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: p.ink, side: BorderSide(color: p.lineInput, width: 1.3))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.bg)),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(backgroundColor: p.ink, contentTextStyle: TextStyle(color: p.bg)),
  );
}
