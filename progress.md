# NSL Writer Tools — progress log

A World Bible app for novel writers (characters, places, orgs, events, items, rules, species) with
`[[links]]`, backlinks, timeline, relationship graph and PC ↔ Android sync. Flutter, one codebase
for Windows and Android. UI is Thai.

**Date:** 2026-10-13 (log started 2026-10-12) · **Machine clock:** UTC+07:00

> **About the times.** They come from the last-modified time of each step's key files, so they are
> approximate (a file touched again later shows the later time). The design bundle itself was
> exported at **02:29**; the first code was written at **02:41**.

---

## Status (after entry pictures)

| Check | Result |
|---|---|
| `flutter analyze` | no issues |
| Tests | **139 passing** |
| Windows release build | builds: `build\windows\x64\runner\Release\nsl_writer_tools.exe` |
| Android release APK | builds: `build\app\outputs\flutter-apk\app-release.apk` (63.3 MB, debug-signed — fine for sideloading, not for the Play Store) |
| Picture UI looked at by eye | **no** (a screenshot test hung and was dropped) |
| Run on a real Android device | **not done yet** (no device/emulator was available) |
| Wi-Fi sync between two real devices | **not done yet** |
| Looked at the screens by eye | only via rendered screenshots of the graph; **night theme not yet looked at by eye** |

Project: `D:\nsl_writer_tools` · Design handoff (untouched): `D:\world-bible-design-system`

---

## Timeline

### 02:29 — Design handoff read
- Read `README.md`, `World Bible.dc.html` (3 screens: PC 3-column, Android list/detail/edit) and
  `uploads/world-bible-app-plan.md` (features, data model, tech, build order).
- Decisions: app name **NSL Writer Tools**; work through the plan step by step.

### 02:41 – 02:44 — Step 1: project skeleton + database
- Created the Flutter project (Windows + Android). Added Riverpod, go_router, drift/sqlite3, file_picker, google_fonts.
- Schema: **World / Entry / Relation**. Repository with create / edit / delete / duplicate, backlinks, search.
- `[[ ]]` link parser (split, extract, snippet, autocomplete trigger).
- Tests: 6.

### 02:44 – 02:56 — Step 2: main UI
- Design tokens → `theme.dart` (paper palette, Thai fonts, 7 type colours/glyphs, 3 status badges).
- PC: top bar, list | content | backlinks columns, shortcuts (Ctrl+F / N / S).
- Android: list + chips + FAB + bottom bar, detail with Content/Backlinks tabs, edit screen.
- Editor with 0.6 s autosave and `[[` autocomplete; relations dialog; broken links create entries.
- Sample world loader (from the design's data).

### ~02:56 — Steps 3 & 4: links polish, search and filters
- **Rename-safe links:** renaming an entry rewrites `[[old]]` everywhere (other entries keep their "last edited").
- Duplicate titles are refused (links resolve by title); new entries are "รายการใหม่ 2", …
- Status + tag filters, sort by last edited or Thai name (ignores leading vowels เ แ โ ใ ไ).
- Tests: 10.

### ~02:59 — Step 5: export / import
- JSON backup of a world (import always makes a **new** world — never overwrites).
- Markdown export (one entry with front matter, or the whole world).
- Settings screen (page on Android, dialog on PC). Round-trip tests.
- **Fix:** Android build failed (Kotlin incremental cache across `D:`/`C:`) → `kotlin.incremental=false`.
- Tests: 16.

### ~03:05 — Step 6: multiple worlds + dashboard
- Rename / delete / create / switch worlds (last world can't be deleted).
- Dashboard: counts by type and status, recent edits, **orphan entries**, **broken links** (tap to create).
- Tests: 18.

### ~03:09 — Step 7 (part): fonts + layout tests
- Bundled Noto Serif Thai, IBM Plex Sans Thai, IBM Plex Mono (9 files, SHA-256 verified) → works offline.
- Widget tests at 360×760, 1.3–1.5× text, and desktop.
- **Bug found:** the "empty world" screen overflowed by 225 px on phones.
- Not done: the real-device check (no device available).
- Tests: 23.

### 03:17 – 03:21 — Timeline (plan phase 2)
- Custom world calendar (word before the year, month names); dates with optional month/day; spans; participants.
- Timeline view grouped by year, filter by character/place; dates and "related events" on each entry.
- **Schema v2** with migration; backups became format v2 (v1 files still import).
- **Bug found:** the exporter/importer returned stale world rows (calendar lost) → now re-read.
- **Bug found:** v1 → v2 migration test caught a path where a column could be added twice.
- Tests: 37.

### 03:37 – 03:44 — Relationship graph (plan phase 2)
- Own force-directed layout (deterministic), pan / zoom / pinch / mouse wheel, drag nodes (they stay put).
- Filter by relation type, include `[[link]]` lines, show unlinked entries, focus on one entry (1–2 hops).
- Layout and filters survive opening an entry and coming back.
- **Fix before shipping:** gesture-detector drag started 36 px late and missed nodes → switched to raw pointer events.
- Replaced rarely-available symbols (◎ ◷ ⌬) with Material icons; toolbar wraps on wide windows.
- Tests: 60.

### 03:56 – 04:14 — Sync (PC ↔ Android, no server)
Decision: **no cloud server** — move data by file or over the same Wi-Fi, one shared merge engine.
- **03:57 Schema v3:** `modified` stamp on every record, **tombstones** for deletes, `lastSyncAt`; v1/v2 → v3 migration.
- **04:06 Merge engine** (`sync.dart`): newest edit wins; the loser is kept as a "(ขัดแย้ง)" conflict copy
  (deterministic id, so no duplicates); delete vs edit rules; renames carry link rewrites;
  title clashes renamed identically on both devices; clock-skew safe convergence.
- **04:06 Repository:** injectable clock, unique ids across devices, no-op autosaves no longer count as edits.
- **04:08 Wi-Fi transport** (`sync_net.dart`): server inside the app, HMAC-signed requests, local-network
  callers only, 5-wrong-codes lockout, 15-minute idle stop. Android `INTERNET` permission added.
- **04:10 – 04:14 UI:** Settings → ซิงก์ระหว่างเครื่อง: *รับซิงก์ผ่าน Wi-Fi*, *ซิงก์กับอีกเครื่อง*,
  *ส่งออกไฟล์ซิงก์*, *รวมจากไฟล์ซิงก์*; remembered address.
- **Tests (94 total):** 17 engine scenarios incl. a randomized 15-seed convergence test with a 40 s clock skew,
  12 real-socket transport tests, UI tests.
- **Bugs found by tests and fixed:** fake clocks made everything look "edited since last sync"
  (→ strict comparison + a clock floor after each sync); v1→v3 migration added a column twice;
  host dialog overflowed at 360 px (→ address and code scale to fit).
- 04:14: launched the new build on the existing database → schema version 2 → 3, app stayed up.

### 13:39 — Night theme
- **Palette:** `Palette.light` / `Palette.dark` in `theme.dart` (warm dark brown ground, lighter accent / type / status colours). `C.*` now reads the palette in force; `typeMeta` / `statusMeta` follow it. Remaining hard-coded colours became tokens.
- **Setting:** Settings → ธีม: ตามระบบ / สว่าง / กลางคืน, remembered in `theme_prefs.json` (`ThemePrefs`). Default follows the system.
- **Switching:** `NslApp` sets the palette and rebuilds every element once, so the open screen/dialog keeps its state and restyles in place.
- **Tests (102 total):** contrast checks for both palettes, prefs round-trip, phone at 1.5× text + desktop switch, system-brightness follow.
- **Note:** a test saw a debug-only text-layout assertion when switching right after Settings first opened (bundled font weight still loading); the test now waits for fonts. Not a theme bug, but not reproduced in a real run.

### 14:38 — Data-safety fixes: sync + automatic backups
- **Open editor vs sync (fixed):** the editor remembers the entry's `modified` stamp. Nothing typed → a change that arrives from a sync (or a link rewrite) is shown in place with a notice. Typing at the same time → your text wins and the other version is kept as an "(ขัดแย้ง)" copy (same id scheme as the sync engine), with a notice. Saves are serialised so the editor's own autosaves never look like conflicts. `Repository.updateEntry` takes `expectedModified` and now returns the stored entry + any copy title.
- **Deleting a world now syncs (fixed):** a `world` tombstone, carried in the bundle as `deletedWorlds` (no format bump; older builds ignore it). The other device deletes the world unless it was edited there after the deletion — then the world comes back everywhere. A device's last world is never deleted by a sync.
- **Automatic backups:** on each launch (and from Settings → สำรองอัตโนมัติ) every world that differs from its newest backup is written as a dated JSON in the app folder (a `backups` folder inside the app's data folder; Settings → สำรองอัตโนมัติ shows the exact path), newest 10 per world kept; backups of deleted worlds stay. Restore = Settings → นำเข้าจากไฟล์ JSON (always a new world).
- **Bugs found by tests and fixed:** a lazy `late` field read the *new* widget after an update (would have hidden every external change); reload/snackbar ran during build; Settings gained rows, so two sync UI tests needed `ensureVisible`.
- **Tests (124 total):** 7 world-deletion scenarios, 6 backup, 9 editor/conflict.
- **Not verified:** two real devices; the editor notice wording on screen.

### 15:19 — Legibility pass (both themes)
- **Text:** nothing smaller than 13 (11–12 → 13, 13 → 14, 14–15 → +1), via `T.ui/serif/mono`. Faint/soft text darkened (light) / lightened (night) to ≥ 4.5:1 / ≥ 7:1.
- **Lines and outlines:** panel lines, input/button outlines, card borders and graph edges are clearly visible now (checked by contrast tests).
- **Buttons:** theme-wide — outlined buttons have a real border, text buttons use the accent colour, filled ones are solid; entry actions on PC are outlined buttons that wrap, and ลบ is red (`C.danger`). Small icons 14–16 → 18–20.
- **Graph:** node titles 14, edge labels 13, glyph min 12, edges thicker (1.8 / 3 when selected), faded nodes/edges less faint.
- **Status badges** and type colours now meet 4.5:1 (light status colours darkened).
- **Tests (124):** contrast thresholds raised; two UI tests now scroll to their target (larger text pushes rows down). Looked at rendered PC screenshots in both themes; phone, graph and timeline screens were **not** looked at by eye. Symbols such as ✎ ▾ depend on system font fallback (blank in the test renderer).

### 16:46 — Entry pictures (one cover image per entry)
- **Add / change / remove** in the editor (รูปภาพ: เพิ่มรูป / เปลี่ยนรูป / เอารูปออก), using the file picker on PC and Android. Saved at once (not debounced), through the same conflict-safe save as text.
- **Shown** as a picture at the top of the entry (tap to zoom full-screen) and as the thumbnail in the list instead of the type letter.
- **Storage:** `ImageStore` keeps files in the app's `images` folder, named by content (`<16 hex sha-256>.jpg|png`); `Entry.imagePath` holds that name (no schema change). Pictures are decoded in a background isolate, scaled to ≤ 1280 px, JPEG (PNG if they use transparency).
- **Backup and sync carry the pictures** as base64 (`imageData`), so they reach the other device and restore from a backup. Names are validated (only names the store would make for exactly those bytes; no paths), size-capped at 12 MB, and stored before the entries that use them.
- **Housekeeping:** duplicating an entry keeps its picture; on launch, picture files no entry uses are deleted (before the automatic backup).
- **Bug found while testing:** the launch hook used `ref` after the app widget was gone.
- **Tests (139):** 12 store/backup/sync (incl. malicious sync file), 3 editor/UI.
- **Limits:** every sync resends all pictures (large worlds make big sync files; the Wi-Fi limit is 64 MB total); automatic backups embed pictures too, so they grow; Markdown export and the graph don't show pictures; not tried with a real Android file picker/camera roll.

---

## Decisions that shape the app
- **Links are by title** (`[[ท่าเรือ]]`, aliases also resolve); titles are unique per world.
- **Offline-first, no accounts, no server.** Sync is a merge of snapshots, not a live connection.
- Search is plain substring matching (Thai has no word spaces), not FTS5.
- Backups never overwrite: import = new world. Sync merges into the same world by id.

## Known limits
- Sync trusts device clocks; a badly wrong clock can make the wrong edit win (the text is still kept as a copy).
- If a sync would delete a device's only world, that device keeps it (the two devices then differ until a world is edited).
- Two edits in the same second can't be told apart by the editor's conflict check (stamps are whole seconds).
- The Wi-Fi transport is **not encrypted** (signed only) — use it on a trusted network.
- A calendar only names things; no month lengths, leap years or date arithmetic. One date per entry.
- Graph positions are kept while the app runs but not saved to the database.
- Bold / italic / `#tag` buttons are not in the editor (the body isn't rendered as Markdown yet).
- Markdown export doesn't include timeline dates yet.

## Not done yet
1. **Run on a real Android phone** (typing with the Thai keyboard, `[[` autocomplete, file dialogs, back button, tap sizes).
2. **Try Wi-Fi sync between the PC and the phone** (Windows Firewall prompt, Android networking).
3. Automatic sync from a cloud folder (OneDrive / Drive) — possible later on top of the same engine.
4. Plan phase 3: map pins, consistency checker, manuscript links, version history, wiki export.

## How to run
```
cd D:\nsl_writer_tools
flutter run -d windows        # PC
flutter run                   # a connected Android phone / emulator
flutter test                  # 139 tests
flutter build apk --debug     # Android APK
flutter build apk --release   # build\app\outputs\flutter-apk\app-release.apk
flutter build windows --release
```
