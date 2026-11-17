import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/calendar.dart';
import '../core/wiki_links.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme.dart';
import '../data/image_store.dart';
import 'actions.dart';
import 'entry_image.dart';

class _FieldRow {
  _FieldRow(String k, String v)
      : key = TextEditingController(text: k),
        value = TextEditingController(text: v);
  final TextEditingController key;
  final TextEditingController value;
  void dispose() {
    key.dispose();
    value.dispose();
  }
}

/// Edit form with debounced autosave. Create it with `key: ValueKey(entry.id)`
/// so switching entries rebuilds the controllers.
class EntryEditor extends ConsumerStatefulWidget {
  const EntryEditor({super.key, required this.entry, required this.onDone});
  final Entry entry;
  final VoidCallback onDone;

  @override
  ConsumerState<EntryEditor> createState() => EntryEditorState();
}

class EntryEditorState extends ConsumerState<EntryEditor> {
  late final Repository _repo = ref.read(repositoryProvider);
  late final _saved = ref.read(savedProvider.notifier);
  late final _title = TextEditingController(text: widget.entry.title);
  late final _aliases = TextEditingController(text: decodeList(widget.entry.aliases).join(', '));
  late final _tags = TextEditingController(text: decodeList(widget.entry.tags).join(', '));
  late final _summary = TextEditingController(text: widget.entry.summary);
  late final _body = TextEditingController(text: widget.entry.body);
  late final List<_FieldRow> _fields = [
    for (final f in decodeMap(widget.entry.fields).entries) _FieldRow(f.key, f.value),
  ];
  final _bodyFocus = FocusNode();

  // Timeline. Loaded asynchronously in initState; nothing is written to the timeline
  // until then, so a slow load can never wipe an existing date.
  bool _timelineLoaded = false;
  bool _onTimeline = false;
  bool _hasEnd = false;
  final _startYear = TextEditingController();
  final _endYear = TextEditingController();
  final _startDay = TextEditingController();
  final _endDay = TextEditingController();
  int? _startMonth;
  int? _endMonth;
  final Set<String> _participants = {};

  late EntryType _type = widget.entry.type;
  late EntryStatus _status = widget.entry.status;
  late String? _image = widget.entry.imagePath;
  bool _imageBusy = false;
  Timer? _debounce;
  bool _dirty = false;

  // The `modified` stamp this editor last saw or wrote. A save made while the stored entry
  // has a different one (a sync changed it) keeps the other version as a conflict copy.
  late DateTime _baseModified; // set in initState: a lazy initialiser would read the *new* widget later
  Future<void>? _chain; // saves run one after another so the stamp above is always current
  int _writing = 0;
  bool _titleClash = false;
  ({String query, int start})? _link;

  @override
  void initState() {
    super.initState();
    _baseModified = widget.entry.modified;
    _body.addListener(_onBodyChanged);
    _loadTimeline();
    // Placeholder title: select it so typing replaces it.
    if (RegExp(r'^รายการใหม่( \d+)?$').hasMatch(widget.entry.title)) {
      _title.selection = TextSelection(baseOffset: 0, extentOffset: _title.text.length);
    }
  }

  @override
  void didUpdateWidget(EntryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Our own saves echo back through the entry stream; only a change from elsewhere
    // (a sync, a link rewrite after a rename) differs from what this editor last saw.
    if (_changedElsewhere(widget.entry) && widget.entry.id == oldWidget.entry.id) {
      // Not now: this runs during build, and the reload touches controllers and shows a notice.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _changedElsewhere(widget.entry)) _reloadFrom(widget.entry);
      });
    }
  }

  bool _changedElsewhere(Entry e) => _writing == 0 && !_dirty && _secs(e.modified) != _secs(_baseModified);

  static int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  /// Nothing typed since the last save: show the version that arrived from elsewhere.
  void _reloadFrom(Entry e) {
    setState(() {
      _baseModified = e.modified;
      _title.text = e.title;
      _aliases.text = decodeList(e.aliases).join(', ');
      _tags.text = decodeList(e.tags).join(', ');
      _summary.text = e.summary;
      _body.text = e.body;
      _type = e.type;
      _status = e.status;
      _image = e.imagePath;
      _titleClash = false;
      for (final f in _fields) {
        f.dispose();
      }
      _fields
        ..clear()
        ..addAll([for (final f in decodeMap(e.fields).entries) _FieldRow(f.key, f.value)]);
    });
    _notify('รายการนี้ถูกอัปเดตจากการซิงก์');
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message, style: T.ui(13, color: C.bg))));
  }

  Future<void> _loadTimeline() async {
    final items = await _repo.timelineOfWorld(widget.entry.worldId);
    if (!mounted) return;
    final mine = items.where((i) => i.entry.id == widget.entry.id).firstOrNull;
    setState(() {
      if (mine != null) {
        _onTimeline = true;
        _startYear.text = '${mine.start.year}';
        _startMonth = mine.start.month;
        _startDay.text = mine.start.day?.toString() ?? '';
        if (mine.end != null) {
          _hasEnd = true;
          _endYear.text = '${mine.end!.year}';
          _endMonth = mine.end!.month;
          _endDay.text = mine.end!.day?.toString() ?? '';
        }
        _participants.addAll(mine.participantIds);
      }
      _timelineLoaded = true;
    });
  }

  /// Null if the year is missing/invalid (the timeline is then left untouched).
  WorldDate? _date(TextEditingController y, int? month, TextEditingController d) {
    final year = int.tryParse(y.text.trim());
    if (year == null) return null;
    final day = int.tryParse(d.text.trim());
    return WorldDate(year, month, month == null ? null : (day != null && day > 0 ? day : null));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) _write(); // not awaited: the repository outlives this widget
    for (final c in [_title, _aliases, _tags, _summary, _body, _startYear, _endYear, _startDay, _endDay]) {
      c.dispose();
    }
    for (final f in _fields) {
      f.dispose();
    }
    _bodyFocus.dispose();
    super.dispose();
  }

  List<String> _split(String s) =>
      s.split(RegExp(r'[,،、]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _write() => _serial(_doWrite);

  /// Runs [job] after every earlier save/picture change has finished.
  Future<void> _serial(Future<void> Function() job) {
    _writing++;
    final run = (_chain ?? Future<void>.value()).catchError((_) {}).then((_) => job());
    _chain = run;
    return run.whenComplete(() => _writing--);
  }

  Future<void> _pickImage() async {
    final bytes = await ref.read(imagePickerProvider)();
    if (bytes == null || !mounted) return;
    setState(() => _imageBusy = true);
    try {
      final name = await _repo.images.addFromBytes(bytes);
      await flush(); // text typed so far first, so the stamp below is current
      await _serial(() => _saveImage(name));
    } on ImageException catch (e) {
      _notify(e.message);
    } finally {
      if (mounted) setState(() => _imageBusy = false);
    }
  }

  Future<void> _removeImage() => _serial(() => _saveImage(null));

  Future<void> _saveImage(String? name) async {
    final r = await _repo.updateEntry(widget.entry.id, imagePath: Value(name), expectedModified: _baseModified);
    final stored = r.entry;
    if (stored != null) _baseModified = stored.modified;
    if (mounted) setState(() => _image = name);
    final copy = r.conflictCopy;
    if (copy != null) _notify('มีการแก้ไขจากการซิงก์ชนกับที่คุณพิมพ์ — เก็บฉบับนั้นไว้เป็น “$copy”');
  }

  Future<void> _doWrite() async {
    _dirty = false;
    // Snapshot first: this also runs from dispose(), where controllers go away.
    final typed = _title.text.trim();
    final type = _type, status = _status;
    final summary = _summary.text.trim(), body = _body.text;
    final aliases = _split(_aliases.text), tags = _split(_tags.text);
    final fields = {
      for (final f in _fields)
        if (f.key.text.trim().isNotEmpty) f.key.text.trim(): f.value.text.trim(),
    };
    // Timeline: untouched until loaded, and untouched while the year is unreadable.
    final start = _onTimeline ? _date(_startYear, _startMonth, _startDay) : null;
    final end = _onTimeline && _hasEnd ? _date(_endYear, _endMonth, _endDay) : null;
    final people = _participants.toList();
    final writeTimeline = _timelineLoaded && (!_onTimeline || start != null);
    // Links resolve by title, so a title already in use is not saved;
    // the previous title stays until the clash is fixed.
    final clash = typed.isNotEmpty && await _repo.titleTaken(widget.entry.worldId, typed, exceptId: widget.entry.id);
    if (mounted && clash != _titleClash) setState(() => _titleClash = clash);
    if (writeTimeline) await _repo.setTimeline(widget.entry.id, start: start, end: end, participants: people);
    final result = await _repo.updateEntry(
      widget.entry.id,
      expectedModified: _baseModified,
      type: type,
      status: status,
      title: typed.isEmpty || clash ? null : typed,
      summary: summary,
      body: body,
      aliases: aliases,
      tags: tags,
      fields: fields,
    );
    final stored = result.entry;
    if (stored != null) _baseModified = stored.modified;
    final copy = result.conflictCopy;
    if (copy != null) _notify('มีการแก้ไขจากการซิงก์ชนกับที่คุณพิมพ์ — เก็บฉบับนั้นไว้เป็น “$copy”');
  }

  void changed() {
    _dirty = true;
    _saved.set(false);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), flush);
  }

  /// Saves immediately (Ctrl+S, "เสร็จ").
  Future<void> flush() async {
    _debounce?.cancel();
    if (_dirty) await _write();
    if (mounted) _saved.set(true);
  }

  void _onBodyChanged() {
    final sel = _body.selection;
    final next = sel.isValid && sel.isCollapsed ? activeLinkQuery(_body.text, sel.baseOffset) : null;
    if (next?.query != _link?.query || next?.start != _link?.start) setState(() => _link = next);
  }

  List<Entry> _suggestions() {
    final q = _link?.query.trim().toLowerCase() ?? '';
    return ref
        .read(allEntriesProvider)
        .where((e) => e.id != widget.entry.id)
        .where((e) => q.isEmpty || e.title.toLowerCase().contains(q) || decodeList(e.aliases).any((a) => a.toLowerCase().contains(q)))
        .take(5)
        .toList();
  }

  void _insertLink(String title) {
    final link = _link;
    if (link == null) return;
    final caret = _body.selection.baseOffset;
    final text = _body.text;
    // Swallow an auto-closed "]]" right after the caret.
    final end = text.startsWith(']]', caret) ? caret + 2 : caret;
    final ins = '[[$title]]';
    _body.value = TextEditingValue(
      text: text.replaceRange(link.start, end, ins),
      selection: TextSelection.collapsed(offset: link.start + ins.length),
    );
    setState(() => _link = null);
    changed();
    _bodyFocus.requestFocus();
  }

  Future<void> _createAndInsert() async {
    final name = _link?.query.trim() ?? '';
    if (name.isEmpty) return;
    await createNewEntry(ref, type: _type, title: name, select: false);
    _insertLink(name);
  }

  void _insertBrackets() {
    final sel = _body.selection;
    final at = sel.isValid ? sel.start : _body.text.length;
    final picked = sel.isValid && !sel.isCollapsed ? _body.text.substring(sel.start, sel.end) : '';
    final text = _body.text.replaceRange(at, sel.isValid ? sel.end : at, '[[$picked]]');
    _body.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: at + 2 + picked.length));
    changed();
    _bodyFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _link == null ? const <Entry>[] : _suggestions();
    final typed = _link?.query.trim() ?? '';
    final exact = ref.read(allEntriesProvider).any((e) => e.title == typed);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('ชื่อ'),
      TextField(
        controller: _title,
        autofocus: true,
        onChanged: (_) => changed(),
        style: T.serif(26, w: FontWeight.w700),
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: C.lineInput)),
          errorText: _titleClash ? 'ชื่อนี้ซ้ำกับรายการอื่น — ยังไม่ได้บันทึกชื่อ' : null,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final t in EntryType.values)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              setState(() => _type = t);
              changed();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _type == t ? typeMeta[t]!.color : Colors.transparent,
                border: Border.all(color: _type == t ? typeMeta[t]!.color : C.lineInput),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(typeMeta[t]!.label, style: T.ui(13, color: _type == t ? C.bg : C.ink)),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 6, children: [
        for (final s in EntryStatus.values)
          ChoiceChip(
            label: Text(statusMeta[s]!.label, style: T.ui(13)),
            selected: _status == s,
            showCheckmark: false,
            selectedColor: statusMeta[s]!.bg,
            side: BorderSide(color: C.lineInput),
            onSelected: (_) {
              setState(() => _status = s);
              changed();
            },
          ),
      ]),
      const SizedBox(height: 16),
      _label('รูปภาพ'),
      _imageSection(),
      const SizedBox(height: 16),
      _label('ชื่อเรียกอื่น (คั่นด้วย,)'),
      _input(_aliases),
      const SizedBox(height: 14),
      _label('สรุปสั้น'),
      _input(_summary, maxLines: 3),
      const SizedBox(height: 14),
      _label('แท็ก (คั่นด้วย,)'),
      _input(_tags),
      const SizedBox(height: 18),
      _label('ข้อมูลเฉพาะ'),
      for (var i = 0; i < _fields.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(width: 120, child: _input(_fields[i].key, hint: 'ชื่อฟิลด์')),
            const SizedBox(width: 10),
            Expanded(child: _input(_fields[i].value, hint: 'ค่า')),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: C.inkSoft),
              onPressed: () {
                setState(() => _fields.removeAt(i).dispose());
                changed();
              },
            ),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() => _fields.add(_FieldRow('', ''))),
          child: Text('+ เพิ่มฟิลด์', style: T.ui(13, color: C.accent)),
        ),
      ),
      const SizedBox(height: 14),
      _timelineSection(),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _label('รายละเอียด')),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: _insertBrackets,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: C.bgBar, borderRadius: BorderRadius.circular(6)),
            child: Text('[[ ]]', style: T.mono(13, w: FontWeight.w500, color: C.ink)),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      TextField(
        controller: _body,
        focusNode: _bodyFocus,
        onChanged: (_) => changed(),
        minLines: 8,
        maxLines: null,
        style: T.serif(15, color: C.body, h: 1.8),
        decoration: InputDecoration(
          hintText: 'พิมพ์ [[ เพื่อลิงก์ไปยังรายการอื่น • เว้นบรรทัดว่างเพื่อขึ้นย่อหน้าใหม่',
          hintStyle: T.ui(13, color: C.inkFaint),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.lineInput)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.accent)),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      if (_link != null)
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: C.bg,
            border: Border.all(color: C.lineInput),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFF3C2814).withValues(alpha: .18), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.lineSoft))),
              child: Text('ลิงก์ไปยัง…', style: T.ui(11, color: C.inkFaint)),
            ),
            for (final e in suggestions)
              InkWell(
                onTap: () => _insertLink(e.title),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: typeMeta[e.type]!.color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.title, style: T.ui(14, w: FontWeight.w500))),
                    Text(typeMeta[e.type]!.label, style: T.ui(11, color: C.inkFaint)),
                  ]),
                ),
              ),
            if (typed.isNotEmpty && !exact)
              InkWell(
                onTap: _createAndInsert,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  child: Text('+ สร้างรายการใหม่ “$typed”', style: T.ui(14, color: C.accent)),
                ),
              ),
          ]),
        ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _timelineSection() {
    final cal = ref.watch(calendarProvider);
    final byId = {for (final e in ref.watch(allEntriesProvider)) e.id: e};

    Widget dateRow(String caption, TextEditingController year, int? month, ValueChanged<int?> onMonth, TextEditingController day) {
      final monthCount = cal.months.isEmpty ? 12 : cal.months.length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.end, children: [
          SizedBox(width: 56, child: Text(caption, style: T.ui(13, color: C.inkSoft))),
          SizedBox(
            width: 96,
            child: TextField(
              controller: year,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              onChanged: (_) {
                setState(() {});
                changed();
              },
              style: T.ui(14),
              decoration: InputDecoration(
                labelText: cal.yearLabel.isEmpty ? 'ปี' : cal.yearLabel,
                labelStyle: T.ui(12, color: C.inkFaint),
                errorText: year.text.trim().isNotEmpty && int.tryParse(year.text.trim()) == null ? 'ตัวเลข' : null,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int?>(
              initialValue: month,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'เดือน', labelStyle: T.ui(12, color: C.inkFaint)),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text('ไม่ระบุ', style: T.ui(14, color: C.inkFaint))),
                for (var m = 1; m <= monthCount; m++) DropdownMenuItem<int?>(value: m, child: Text(cal.monthName(m), style: T.ui(14))),
              ],
              onChanged: (v) {
                setState(() => onMonth(v));
                changed();
              },
            ),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: day,
              enabled: month != null,
              keyboardType: TextInputType.number,
              onChanged: (_) => changed(),
              style: T.ui(14),
              decoration: InputDecoration(labelText: 'วันที่', labelStyle: T.ui(12, color: C.inkFaint)),
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.bgPanel, border: Border.all(color: C.line), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('เส้นเวลา', style: T.ui(13, w: FontWeight.w600, color: C.inkSoft))),
          Switch(
            value: _onTimeline,
            onChanged: _timelineLoaded
                ? (v) {
                    setState(() => _onTimeline = v);
                    changed();
                  }
                : null,
          ),
        ]),
        if (!_onTimeline)
          Text('เปิดเพื่อให้รายการนี้ปรากฏบนเส้นเวลาของโลก', style: T.ui(12, color: C.inkFaint))
        else ...[
          const SizedBox(height: 8),
          dateRow('เริ่ม', _startYear, _startMonth, (v) => _startMonth = v, _startDay),
          Row(children: [
            Checkbox(
              value: _hasEnd,
              onChanged: (v) {
                setState(() => _hasEnd = v ?? false);
                changed();
              },
            ),
            Text('มีวันสิ้นสุด (ช่วงเวลา)', style: T.ui(13)),
          ]),
          if (_hasEnd) dateRow('สิ้นสุด', _endYear, _endMonth, (v) => _endMonth = v, _endDay),
          const SizedBox(height: 6),
          Text('ผู้เกี่ยวข้อง', style: T.ui(12, color: C.inkFaint)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final id in _participants)
              if (byId[id] != null)
                InputChip(
                  label: Text(byId[id]!.title, style: T.ui(13)),
                  onDeleted: () {
                    setState(() => _participants.remove(id));
                    changed();
                  },
                ),
            ActionChip(
              label: Text('+ เพิ่ม', style: T.ui(13, color: C.accent)),
              onPressed: _addParticipant,
            ),
          ]),
        ],
      ]),
    );
  }

  Future<void> _addParticipant() async {
    final options = ref
        .read(allEntriesProvider)
        .where((e) => e.id != widget.entry.id && !_participants.contains(e.id))
        .toList()
      ..sort((a, b) => thaiCompare(a.title, b.title));
    final picked = await showDialog<Entry>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('เพิ่มผู้เกี่ยวข้อง', style: T.serif(18, w: FontWeight.w700)),
        children: [
          if (options.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('ไม่มีรายการอื่นให้เลือก')),
          SizedBox(
            width: 360,
            height: options.isEmpty ? 0 : 380,
            child: ListView(children: [
              for (final e in options)
                ListTile(
                  dense: true,
                  leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: typeMeta[e.type]!.color, borderRadius: BorderRadius.circular(2))),
                  title: Text(e.title, style: T.ui(14)),
                  trailing: Text(typeMeta[e.type]!.label, style: T.ui(11, color: C.inkFaint)),
                  onTap: () => Navigator.pop(ctx, e),
                ),
            ]),
          ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => _participants.add(picked.id));
    changed();
  }

  Widget _imageSection() {
    final name = _image;
    return Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (name != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: C.bgPanel, border: Border.all(color: C.border), borderRadius: BorderRadius.circular(8)),
            child: EntryImage(name, fit: BoxFit.contain, cacheWidth: 360),
          ),
        ),
      OutlinedButton.icon(
        onPressed: _imageBusy ? null : _pickImage,
        icon: _imageBusy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate_outlined, size: 20),
        label: Text(name == null ? 'เพิ่มรูป' : 'เปลี่ยนรูป', style: T.ui(13)),
      ),
      if (name != null)
        OutlinedButton.icon(
          onPressed: _imageBusy ? null : _removeImage,
          style: OutlinedButton.styleFrom(foregroundColor: C.danger, side: BorderSide(color: C.danger, width: 1.3)),
          icon: const Icon(Icons.delete_outline, size: 20),
          label: Text('เอารูปออก', style: T.ui(13, color: C.danger)),
        ),
    ]);
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(s, style: T.ui(11, color: C.inkFaint)),
      );

  Widget _input(TextEditingController c, {int maxLines = 1, String? hint}) => TextField(
        controller: c,
        maxLines: maxLines,
        minLines: 1,
        onChanged: (_) => changed(),
        style: T.ui(14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: T.ui(13, color: C.inkFaint),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: C.lineInput)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: C.accent)),
        ),
      );
}
