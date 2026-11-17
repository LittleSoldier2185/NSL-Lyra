import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme.dart';
import 'actions.dart';
import 'backup_actions.dart';
import 'desktop_shell.dart' show EmptyWorld;
import 'entry_detail.dart';
import 'entry_editor.dart';
import 'entry_list.dart';
import 'world_dashboard.dart';

void _openRoute(BuildContext context, WidgetRef ref, Entry e) {
  ref.read(selectedIdProvider.notifier).set(e.id);
  context.push('/entry/${e.id}');
}

/// Android list screen: world header, type chips, list, FAB, bottom bar.
class MobileListPage extends ConsumerStatefulWidget {
  const MobileListPage({super.key});

  @override
  ConsumerState<MobileListPage> createState() => _MobileListPageState();
}

class _MobileListPageState extends ConsumerState<MobileListPage> {
  bool _searching = false;
  final _focus = FocusNode();
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _focus.dispose();
    _ctl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (_searching) {
      _focus.requestFocus();
    } else {
      _ctl.clear();
      ref.read(queryProvider.notifier).set('');
    }
  }

  Future<void> _new() async {
    final e = await createNewEntry(ref);
    if (e != null && mounted) context.push('/entry/${e.id}/edit');
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(activeWorldProvider);
    final total = ref.watch(allEntriesProvider).length;
    ref.listen(queryProvider, (_, q) {
      if (_ctl.text != q) _ctl.text = q; // e.g. "clear filters"
    });

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              Expanded(
                child: _searching
                    ? TextField(
                        focusNode: _focus,
                        controller: _ctl,
                        onChanged: ref.read(queryProvider.notifier).set,
                        style: T.ui(16),
                        decoration: InputDecoration(hintText: 'ค้นหาชื่อ เนื้อหา หรือแท็ก', hintStyle: T.ui(15, color: C.inkFaint)),
                      )
                    : InkWell(
                        onTap: () => showWorldDialog(context, ref),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('โลก', style: T.ui(11, color: C.inkFaint)),
                          Text(world?.name ?? '…', style: T.serif(20, w: FontWeight.w700)),
                        ]),
                      ),
              ),
              IconButton.filledTonal(
                style: IconButton.styleFrom(backgroundColor: C.bgChip, minimumSize: const Size(44, 44)),
                icon: Icon(_searching ? Icons.close : Icons.search, color: C.ink),
                onPressed: _toggleSearch,
              ),
            ]),
          ),
          const TypeChips(mobile: true),
          const SizedBox(height: 8),
          const FilterBar(mobile: true),
          Expanded(
            child: total == 0
                ? EmptyWorld(onCreate: _new)
                : EntryListView(mobile: true, onOpen: (e) => _openRoute(context, ref, e)),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: C.accent,
        foregroundColor: C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _new,
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: C.bgBar,
        indicatorColor: C.navIndicator,
        selectedIndex: _searching ? 1 : 0,
        labelTextStyle: WidgetStatePropertyAll(T.ui(11)),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              if (_searching) _toggleSearch();
            case 1:
              if (!_searching) _toggleSearch();
            case 2:
              context.push('/world');
            case 3:
              context.push('/settings');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu), label: 'รายการ'),
          NavigationDestination(icon: Icon(Icons.search), label: 'ค้นหา'),
          NavigationDestination(icon: Icon(Icons.public), label: 'โลก'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}

/// Android "โลก" tab: overview and world management.
class MobileWorldPage extends ConsumerWidget {
  const MobileWorldPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(backgroundColor: C.bg, surfaceTintColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: WorldDashboard(
          onOpen: (e) => _openRoute(context, ref, e),
          onOpenTimeline: () => context.push('/timeline'),
          onOpenGraph: () => context.push('/graph'),
          onNewEntry: () async {
            final e = await createNewEntry(ref);
            if (e != null && context.mounted) context.push('/entry/${e.id}/edit');
          },
        ),
      ),
    );
  }
}

/// Android detail screen with Content / Backlinks tabs.
class MobileDetailPage extends ConsumerStatefulWidget {
  const MobileDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<MobileDetailPage> createState() => _MobileDetailPageState();
}

class _MobileDetailPageState extends ConsumerState<MobileDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allEntriesProvider);
    final entry = all.where((e) => e.id == widget.id).firstOrNull;
    if (entry == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('ไม่พบรายการ')));
    }
    final repo = ref.read(repositoryProvider);
    final n = repo.backlinksFor(all, entry).length;

    Widget tab(int i, String label) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _tab == i ? C.bg : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: T.ui(14, w: _tab == i ? FontWeight.w600 : FontWeight.w400, color: _tab == i ? C.ink : C.inkSoft)),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.bg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => context.push('/entry/${entry.id}/edit')),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'md') {
                await exportEntryMarkdown(context, ref, entry);
              } else if (v == 'copy') {
                final copy = await repo.duplicateEntry(entry.id);
                if (context.mounted) context.pushReplacement('/entry/${copy.id}');
              } else if (v == 'delete' && await confirmDelete(context, entry)) {
                if (context.mounted) context.pop();
                await repo.deleteEntry(entry.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('ทำสำเนา')),
              PopupMenuItem(value: 'md', child: Text('ส่งออกเป็น Markdown')),
              PopupMenuItem(value: 'delete', child: Text('ลบ')),
            ],
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        EntryContent(entry: entry, mobile: true, onOpen: (e) => _openRoute(context, ref, e), tabBar: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: C.bgChip, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [tab(0, 'เนื้อหา'), tab(1, 'Backlinks · $n')]),
        ), showBody: _tab == 0),
        if (_tab == 1) BacklinksList(entry: entry, onOpen: (e) => _openRoute(context, ref, e)),
      ]),
    );
  }
}

/// Android edit screen. Autosaves; "เสร็จ" saves immediately and closes.
class MobileEditPage extends ConsumerStatefulWidget {
  const MobileEditPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<MobileEditPage> createState() => _MobileEditPageState();
}

class _MobileEditPageState extends ConsumerState<MobileEditPage> {
  final _key = GlobalKey<EntryEditorState>();

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(allEntriesProvider).where((e) => e.id == widget.id).firstOrNull;
    if (entry == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('ไม่พบรายการ')));
    }
    Future<void> done() async {
      await _key.currentState?.flush();
      if (context.mounted) context.pop();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: C.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: done),
        title: Text('แก้ไขรายการ', style: T.ui(15, w: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.accent, shape: const StadiumBorder()),
              onPressed: done,
              child: Text('เสร็จ', style: T.ui(14, w: FontWeight.w500, color: C.bg)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: EntryEditor(key: _key, entry: entry, onDone: () => context.pop()),
      ),
    );
  }
}
