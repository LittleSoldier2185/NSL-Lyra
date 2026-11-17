import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/seed.dart';
import '../providers.dart';
import '../theme.dart';
import 'actions.dart';
import 'backup_actions.dart';
import 'entry_detail.dart';
import 'entry_editor.dart';
import 'entry_list.dart';
import 'graph_view.dart';
import 'timeline_view.dart';
import 'world_dashboard.dart';

/// PC layout: list | content | backlinks, with keyboard shortcuts.
class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key, this.initialId});
  final String? initialId;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  final _search = FocusNode();
  final _searchCtl = TextEditingController();
  final _editorKey = GlobalKey<EntryEditorState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialId != null) {
      Future.microtask(() => ref.read(selectedIdProvider.notifier).set(widget.initialId));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  /// Back to the no-entry views (overview, timeline or graph).
  void _showMain(MainView view) {
    ref.read(editingProvider.notifier).set(false);
    ref.read(selectedIdProvider.notifier).set(null);
    ref.read(mainViewProvider.notifier).set(view);
  }

  Future<void> _new() async {
    final e = await createNewEntry(ref);
    if (e != null) ref.read(editingProvider.notifier).set(true);
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(activeWorldProvider);
    final entry = ref.watch(selectedEntryProvider);
    final editing = ref.watch(editingProvider) && entry != null;
    final total = ref.watch(allEntriesProvider).length;
    final view = ref.watch(mainViewProvider);
    ref.listen(queryProvider, (_, q) {
      if (_searchCtl.text != q) _searchCtl.text = q; // e.g. "clear filters"
    });
    void open(e) => openEntry(ref, e);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _search.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _new,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _editorKey.currentState?.flush(),
        // Esc leaves edit mode, or goes back to the overview. Not while typing in a text field.
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_search.hasFocus) {
            _search.unfocus();
          } else if (ref.read(editingProvider)) {
            _editorKey.currentState?.flush();
            ref.read(editingProvider.notifier).set(false);
          } else {
            ref.read(selectedIdProvider.notifier).set(null);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: C.bg,
          body: Column(children: [
            _TopBar(search: _search, controller: _searchCtl, total: total, worldName: world?.name ?? '…', onNew: _new),
            Divider(height: 1, color: C.line),
            Expanded(
              child: Row(children: [
                Container(
                  width: 300,
                  decoration: BoxDecoration(color: C.bgPanel, border: Border(right: BorderSide(color: C.line))),
                  child: Column(children: [
                    Row(children: [
                      _NavTab(
                        icon: Icons.dashboard_outlined,
                        label: 'ภาพรวม',
                        selected: entry == null && view == MainView.overview,
                        onTap: () => _showMain(MainView.overview),
                      ),
                      _NavTab(
                        icon: Icons.timeline,
                        label: 'เส้นเวลา',
                        selected: entry == null && view == MainView.timeline,
                        onTap: () => _showMain(MainView.timeline),
                      ),
                      _NavTab(
                        icon: Icons.hub_outlined,
                        label: 'กราฟ',
                        selected: entry == null && view == MainView.graph,
                        onTap: () => _showMain(MainView.graph),
                      ),
                    ]),
                    Divider(height: 1, color: C.line),
                    const TypeChips(),
                    const FilterBar(),
                    Expanded(child: EntryListView(onOpen: open)),
                  ]),
                ),
                Expanded(
                  child: entry == null
                      ? (total == 0
                          ? EmptyWorld(onCreate: _new)
                          : view == MainView.graph
                              ? GraphView(onOpen: open) // uses the whole column, no padding
                              : SingleChildScrollView(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 720),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 60),
                                    child: view == MainView.timeline
                                        ? TimelineView(onOpen: open)
                                        : WorldDashboard(
                                            onOpen: open,
                                            onNewEntry: _new,
                                            onOpenTimeline: () => _showMain(MainView.timeline),
                                            onOpenGraph: () => _showMain(MainView.graph),
                                          ),
                                  ),
                                ),
                              ),
                            ))
                      : SingleChildScrollView(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(40, 28, 40, 60),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _ActionRow(editing: editing, entry: entry, onFlush: () => _editorKey.currentState?.flush()),
                                  const SizedBox(height: 12),
                                  editing
                                      ? KeyedSubtree(
                                          // New state (fresh controllers) per entry.
                                          key: ValueKey(entry.id),
                                          child: EntryEditor(
                                            key: _editorKey,
                                            entry: entry,
                                            onDone: () => ref.read(editingProvider.notifier).set(false),
                                          ),
                                        )
                                      : EntryContent(entry: entry, onOpen: open),
                                ]),
                              ),
                            ),
                          ),
                        ),
                ),
                if (entry != null) BacklinksPanel(entry: entry, onOpen: open),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: selected ? C.selected : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              Icon(icon, size: 18, color: C.inkSoft),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13, w: FontWeight.w500))),
            ]),
          ),
        ),
      );
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.search, required this.controller, required this.total, required this.worldName, required this.onNew});
  final FocusNode search;
  final TextEditingController controller;
  final int total;
  final String worldName;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedProvider);
    return Container(
      height: 52,
      color: C.bgBar,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => showWorldDialog(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(6)),
                child: Text(worldName.isEmpty ? 'ห' : worldName.characters.first, style: T.serif(14, w: FontWeight.w700, color: C.bgBar)),
              ),
              const SizedBox(width: 10),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(worldName, style: T.serif(14, w: FontWeight.w600, h: 1.2)),
                Text('$total รายการ · สลับโลก ▾', style: T.ui(11, color: C.inkFaint, h: 1.2)),
              ]),
            ]),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              width: 440,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: C.bg, border: Border.all(color: C.lineInput), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Text('⌕', style: TextStyle(fontSize: 14, color: C.inkFaint)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    focusNode: search,
                    controller: controller,
                    onChanged: ref.read(queryProvider.notifier).set,
                    style: T.ui(14),
                    decoration: InputDecoration(hintText: 'ค้นหาชื่อ เนื้อหา หรือแท็ก', hintStyle: T.ui(14, color: C.inkFaint)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(border: Border.all(color: C.lineInput), borderRadius: BorderRadius.circular(4)),
                  child: Text('Ctrl F', style: T.mono(11, w: FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),
        Text(saved ? '● บันทึกแล้ว' : '○ กำลังบันทึก…', style: T.ui(12, color: saved ? C.saved : C.inkFaint)),
        IconButton(
          tooltip: 'ตั้งค่า / สำรองข้อมูล',
          icon: Icon(Icons.settings_outlined, size: 20, color: C.inkSoft),
          onPressed: () => showSettingsDialog(context),
        ),
        Material(
          color: C.accent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: C.accentDark,
            onTap: onNew,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Text('+ รายการใหม่', style: T.ui(14, w: FontWeight.w500, color: C.bg)),
                const SizedBox(width: 8),
                Text('Ctrl N', style: T.mono(11, color: C.bg.withValues(alpha: .75))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.editing, required this.entry, required this.onFlush});
  final bool editing;
  final Entry entry;
  final VoidCallback onFlush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    Widget btn(String label, VoidCallback onTap, {bool primary = false, bool danger = false}) => primary
        ? FilledButton(onPressed: onTap, child: Text(label, style: T.ui(13, color: C.bg, w: FontWeight.w600)))
        : OutlinedButton(
            onPressed: onTap,
            style: danger ? OutlinedButton.styleFrom(foregroundColor: C.danger, side: BorderSide(color: C.danger, width: 1.3)) : null,
            child: Text(label, style: T.ui(13, color: danger ? C.danger : C.ink)),
          );
    return Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
      if (editing)
        btn('เสร็จ', () {
          onFlush();
          ref.read(editingProvider.notifier).set(false);
        }, primary: true)
      else ...[
        btn('✎ แก้ไข', () => ref.read(editingProvider.notifier).set(true)),
        btn('ทำสำเนา', () async {
          final copy = await repo.duplicateEntry(entry.id);
          ref.read(selectedIdProvider.notifier).set(copy.id);
        }),
        btn('ส่งออก .md', () => exportEntryMarkdown(context, ref, entry)),
        btn('ลบ', () async {
          if (await confirmDelete(context, entry)) {
            ref.read(selectedIdProvider.notifier).set(null);
            await repo.deleteEntry(entry.id);
          }
        }, danger: true),
      ],
    ]);
  }
}

/// Shown when the active world has no entries yet.
class EmptyWorld extends ConsumerWidget {
  const EmptyWorld({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('โลกนี้ยังว่างอยู่', style: T.serif(22, w: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('เริ่มจากสร้างตัวละคร สถานที่ หรือกฎของโลกสักอย่าง',
              textAlign: TextAlign.center, style: T.ui(14, color: C.inkSoft)),
          const SizedBox(height: 20),
          // Wrap, not Row: two buttons don't fit side by side at 360px.
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
            FilledButton(onPressed: onCreate, child: const Text('+ สร้างรายการแรก')),
            OutlinedButton(
              onPressed: () {
                final w = ref.read(activeWorldProvider);
                if (w != null) seedSampleWorld(ref.read(repositoryProvider), w.id);
              },
              child: const Text('โหลดข้อมูลตัวอย่าง'),
            ),
          ]),
        ]),
      ),
    );
  }
}
