import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'theme.dart';
import 'ui/backup_actions.dart';
import 'ui/desktop_shell.dart';
import 'ui/graph_view.dart';
import 'ui/mobile_shell.dart';
import 'ui/timeline_view.dart';

/// Width at which the 3-column PC layout replaces the single-column one.
const wideBreakpoint = 900.0;

GoRouter buildRouter() => GoRouter(routes: [
  GoRoute(
    path: '/',
    builder: (_, _) => _Adaptive(wide: const DesktopShell(), narrow: const MobileListPage()),
    routes: [
      GoRoute(
        path: 'world',
        builder: (_, _) => _Adaptive(wide: const DesktopShell(), narrow: const MobileWorldPage()),
      ),
      GoRoute(
        path: 'timeline',
        builder: (_, _) => _Adaptive(
          wide: const DesktopShell(),
          narrow: Consumer(
            builder: (context, ref, _) => MobileTimelinePage(onOpen: (e) {
              ref.read(selectedIdProvider.notifier).set(e.id);
              context.push('/entry/${e.id}');
            }),
          ),
        ),
      ),
      GoRoute(
        path: 'graph',
        builder: (_, _) => _Adaptive(
          wide: const DesktopShell(),
          narrow: Consumer(
            builder: (context, ref, _) => MobileGraphPage(onOpen: (e) {
              ref.read(selectedIdProvider.notifier).set(e.id);
              context.push('/entry/${e.id}');
            }),
          ),
        ),
      ),
      GoRoute(
        path: 'settings',
        // On PC, settings open as a dialog from the top bar instead.
        builder: (_, _) => _Adaptive(wide: const DesktopShell(), narrow: const SettingsPage()),
      ),
      GoRoute(
        path: 'entry/:id',
        builder: (_, s) => _Adaptive(
          wide: DesktopShell(initialId: s.pathParameters['id']),
          narrow: MobileDetailPage(id: s.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => _Adaptive(
              wide: DesktopShell(initialId: s.pathParameters['id']),
              narrow: MobileEditPage(id: s.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  ),
]);

class _Adaptive extends StatelessWidget {
  const _Adaptive({required this.wide, required this.narrow});
  final Widget wide;
  final Widget narrow;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, c) => c.maxWidth >= wideBreakpoint ? wide : narrow);
}

void _markAllDirty(Element root) {
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  root.visitChildren(visit);
}

class NslApp extends ConsumerStatefulWidget {
  const NslApp({super.key});

  @override
  ConsumerState<NslApp> createState() => _NslAppState();
}

class _NslAppState extends ConsumerState<NslApp> {
  // One router per app instance, so tests don't share navigation state.
  final _router = buildRouter();
  bool _backedUp = false;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // First launch: make sure there is a world to work in.
    ref.listen(worldsProvider, (_, next) {
      final worlds = next.value;
      if (worlds != null && worlds.isEmpty) {
        ref.read(repositoryProvider).createWorld('โลกของฉัน');
      }
      // Once per launch, as soon as the worlds are known: keep a dated copy of any that changed.
      if (worlds != null && worlds.isNotEmpty && !_backedUp) {
        _backedUp = true;
        // Unused picture files go first; the backup then only embeds pictures still in use.
        // (Providers are read now: `ref` must not be used after this widget is gone.)
        final backup = ref.read(autoBackupProvider);
        ref.read(repositoryProvider).pruneImages().whenComplete(backup.run);
      }
    });
    return MaterialApp.router(
      title: 'NSL Writer Tools',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Palette.light),
      darkTheme: buildTheme(Palette.dark),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: Duration.zero,
      builder: (context, child) {
        final next = Theme.of(context).brightness == Brightness.dark ? Palette.dark : Palette.light;
        if (!identical(C.p, next)) {
          // Colours are read from [C] while building, so every element (even ones
          // holding a const widget) must rebuild once for the switch to show.
          // Marking happens after this frame; marking mid-build corrupts text layout.
          C.p = next;
          final root = context as Element;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (root.mounted) _markAllDirty(root);
          });
          WidgetsBinding.instance.ensureVisualUpdate();
        }
        return child!;
      },
      routerConfig: _router,
    );
  }
}
