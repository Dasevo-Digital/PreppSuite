# PreppSuite

Self-hosted-free household preparedness app (inventory, checklists, budget,
official warnings, shelter map). **Everything runs on the device.** There is
no server, no account and no network dependency beyond the public feeds the
app fetches itself. Several devices share a household through a folder they
can all see — see [`docs/gemeinsamer-ordner.md`](docs/gemeinsamer-ordner.md).

Single Flutter package: `preppsuite_flutter` (Flutter + Riverpod + drift).
It used to be a three-package Serverpod workspace; the server and its
generated client were removed once warnings moved into the app and household
sharing moved to a shared folder.

## Commands

```bash
flutter pub get                                     # root
flutter analyze                                     # root
dart format --output=none --set-exit-if-changed .   # root
cd preppsuite_flutter && flutter test

# Only on a device or simulator: the storage bridge is Kotlin and Swift,
# and nothing else checks there is anyone on the other end of the channel.
cd preppsuite_flutter && flutter test integration_test/ -d <device>
```

Linux is built in a container from here — see [`tool/docker/`](tool/docker/).
Windows cannot be built on a Mac at all; `.github/workflows/build-desktop.yml`
is the only path to one.

Code generation (drift):

```bash
cd preppsuite_flutter && dart run build_runner build
```

l10n is generated on build (`generate: true` + `l10n.yaml`); the output under
`lib/l10n/generated/` is committed.

## Architecture invariants

These are load-bearing — breaking one produces bugs that only show up on a
second device or after a restart.

**Drift is the source of truth for the UI.** Screens and providers read from
[`AppDatabase`](preppsuite_flutter/lib/local_db/database.dart). The app is
fully usable offline; nothing blocks on the network.

**Third-party HTTP clients live in their feature's `application/` folder**
(BBK, MeteoAlarm, OpenFoodFacts, Overpass, WWBOTA, Nominatim) and are called
from there. All are public and key-less.

**Warnings are fetched by the app.** `WarningPollService` runs from two
places that must stay interchangeable: `WarningSyncController` while a screen
is open, and `runWarningBackgroundPoll` in a separate isolate via WorkManager.
The isolate has no Riverpod, no widget tree and no profile object — it reads
`WarningRegionStore` (preferences) and the local database. That is why
relevance takes a plain `WarningRegionFilter` and not the profile itself.

**`warningRelevanceRank` ranks, it does not filter** — its 0 means both
"concerns everyone" and "concerns someone else". Use `isWarningRelevant`
wherever a yes/no is needed. The distinction became load-bearing when the
server stopped pre-filtering.

**The `notified` column is the record of what has been announced,** not an
in-memory list. A background isolate ends after every run.

**`HouseholdProfile.id` is the partition key for every local table.** It is
generated once and changes exactly once more: joining a folder that already
holds a household adopts that id, and `adoptHouseholdId` re-stamps every
existing row onto it. Without the re-stamp those rows do not merge — they
stop being visible, because every query selects by this column.

**A device only ever writes its own file in the shared folder.** That is
what makes the whole design work without locking: two people editing at the
same time write different paths, so the cloud engine underneath never has to
resolve a conflict — and the way those engines resolve one is to keep a copy
and rename the other, which would silently split a household in two.

**Merging is last-writer-wins by `updatedAt`, strictly greater.** Strictly,
so replaying a snapshot is free and the order device files happen to be read
in cannot change the result. It also means the clocks matter: a device set an
hour ahead wins arguments it should lose. That is why deletions are
tombstones — a wrong win can still be overruled.

**Rows seeded by `ChecklistSeeder` carry a fixed `updatedAt`
(`ChecklistSeeder.seededAt`), not `now()`.** A real timestamp would make a
fresh install's seed newer than another device's month-old edits, and the
merge would dutifully un-tick everything that had been ticked off.

**Nothing a controller writes is ever pushed by the controller.** A local
write only marks the row dirty; `SharedFolderSyncService` publishes on its
own schedule. Controllers hold no `Ref` and start no sync.

**Every local write must set `dirty: const Value(true)` explicitly.** The
column defaults to true, but a default only applies on INSERT, and
`insertOnConflictUpdate` writes just the columns the companion sets. Leaving
`dirty` out therefore updates an already-synced row's values while leaving it
marked clean. This was a real bug across all three controllers;
`inventory_controller_test` guards it. The flag now feeds shared-folder sync
rather than a server.

**The offline map only renders an OpenMapTiles-schema archive.** The style
is `ProvidedThemes.lightTheme()` from `vector_tile_renderer`, which reads
layer names like `water` and `transportation`; a Protomaps-schema archive
holds the same data under different names and would draw nothing.
`OfflineMapController` checks the archive's own `vector_layers` and refuses
before anything is stored. Its raster layer is filtered out of the theme —
that one fetches a shaded relief over HTTP, which has no place on a map
whose point is working without a network.

**ZIM title search reads the archive's own order; full text is a separate
index the app builds.** `searchTitles` binary-searches the title order the
archive carries — version 6 keeps it in an `X/listing` entry, version 5 in
the header — and capitalizes the query's first letter, because that order
is by bytes and Wikipedia titles start with a capital. The archive's own
full-text index is Xapian, which has no Dart binding, so
`KnowledgeIndexer` builds an FTS5 one instead, in
`KnowledgeIndexDatabase` — a database of its own, because it is derived,
gigabytes large, and belongs to one archive. `XapianIndex` is a second
route to the same thing through the archive's own index; it is proven but
not yet wired in, and it needs the native library from
`native/zim_xapian` — see [`docs/volltextsuche-xapian.md`](docs/volltextsuche-xapian.md).

**`directAccessInfo` is the only thing the ZIM reader hands out that is a
position rather than bytes,** and it returns null for every compressed
cluster on purpose. Xapian opens a database from a file offset, so the
search index can be read where it lies inside a thirty-gigabyte archive —
but a compressed blob exists only after decompression and has no place in
the file to point at. It also reads the blob offsets straight from the
source rather than through the cluster cache, because an uncompressed
index cluster is the size of the index.

**The indexer reads in cluster order, never entry order.** Entries are
sorted by URL and clusters are not; reading in entry order would
decompress the same cluster once per article inside it. It also runs on
the main isolate on purpose: on Android the archive is a `content://`
document behind a platform channel, which a plain isolate cannot reach.

**PMTiles and ZIM are both read through `ByteRangeSource`, never a `File`
directly.** A country extract or a Wikipedia archive is gigabytes: neither
is ever copied or fully read, and on Android both are `content://`
documents that `dart:io` cannot open at all.

**Adding or removing a drift column means a migration.** Bump
`schemaVersion` and add the matching branch to `onUpgrade` in the same edit —
an existing install will not recreate its tables. Removing one needs
`m.alterTable(TableMigration(table))`, since SQLite cannot drop a column in
place; `migration_to_8_test` writes out the old schema by hand and upgrades
it for real, which is the only way that path is ever exercised.

**The snapshot format in `device_snapshot.dart` is a contract, not a dump.**
Row codecs are hand-written rather than drift's generated `toJson` precisely
so that a migration does not silently change a file format other installs —
and older app versions — have to keep reading. A decode returns null for
anything it cannot use, which costs one row instead of the whole sync.

**No hard-coded user-facing strings.** Every one goes through
`AppLocalizations` with entries in both `app_de.arb` and `app_en.arb`.
Enum-to-label mapping lives in the feature's `*_l10n.dart` helper.

## Feature layout

```
lib/model/         # plain types: categories, household profile
lib/local_db/      # drift tables and the database
lib/features/<feature>/
  application/     # logic, providers, HTTP clients — where the tests live
  presentation/    # widgets and screens
```

`features/maps/` is the offline map: a hand-written PMTiles v3 reader, a
`VectorTileProvider` over it, and the layer that falls back to
OpenStreetMap's raster tiles when no archive is configured.

`features/knowledge/` is the offline encyclopedia: a hand-written ZIM
reader, a loopback HTTP server in front of it, and a WebView pointed at
that. The server is what makes links, images and stylesheets inside an
article resolve without any code — they come back to the same origin. It
is also what makes the platform split cheap: `articleViewer` picks an
embedded panel where `webview_flutter` reaches an engine and a window of
its own on Linux and Windows, where it does not, and both are handed the
same URL.

`features/sharing/` is the shared-folder sync. `SyncFolder` is an interface
over "a directory" with a `dart:io` implementation, so the merge is tested
against an in-memory folder with several databases standing in for devices.

Keep decision logic in `application/` so it stays testable without a widget
tree; the test suite deliberately targets that layer rather than the UI.

## Gotchas worth knowing

- `file_picker` is pinned to `^8.3.7`; 9.x/12.x break file picking on macOS.
  The reason is written out in `preppsuite_flutter/pubspec.yaml` — read it
  before bumping.
- `notificationsEnabledProvider` returns `false` for one turn of the event
  loop before its persisted value loads. Anything that *acts* on the setting
  rather than displaying it must `await ensureLoaded()` first.
- Warning region filtering is coarse by design: BBK is Kreis-level at best,
  MeteoAlarm's area is free text and is never matched. See
  [`docs/warning-feeds.md`](docs/warning-feeds.md).
- Background polling is dependable on Android (15-minute floor, a platform
  limit) and opportunistic on iOS. The app never promises the iOS case.
- NINA delivers the same warnings in ~30 seconds against this app's 15
  minutes. The warning screen says so rather than pretending otherwise.
- Android and iOS both reach picked storage through the same channel
  (`NativeSyncFolder` and `NativeByteRangeSource` in Dart; `MainActivity.kt`
  and `StorageBridge.swift` natively), for different reasons: a
  `content://` tree is not something `dart:io` can open, and an iOS URL
  works only inside a security scope and only until the process ends. The
  method names on that channel must stay identical on both sides, and all
  implementations must produce the identical folder layout —
  `deviceFilePath` and friends in `sync_folder.dart` are the single
  definition of it.
- **The scheme in a stored location is what picks the reader.**
  `content://` is Android, `bookmark://` an iOS bookmark, anything else a
  path. Read from the value rather than from the running platform, because
  a restored backup or a synced preference can carry another platform's
  handle. `isNativeStorageHandle` is the one place that decides.
- iOS must never copy a picked archive. `UIDocumentPickerViewController`
  is created with `asCopy: false`, and `LSSupportsOpeningDocumentsInPlace`
  is set — a country map extract or a Wikipedia archive is gigabytes, and
  the copy would land in the container and be swept away with the cache.
- The macOS build runs **without** the app sandbox, deliberately: under it
  a picked folder's permission dies with the process, and keeping it needs
  security-scoped bookmarks in Swift. The reason is written into
  `macos/Runner/Release.entitlements`; put it back only alongside that
  native code.
- iOS needs a deployment target of at least 14.0 — `workmanager-apple`
  brings the floor. It lives in three places in `project.pbxproj` plus
  `ios/Podfile`.
- The `zstandard` iOS and macOS pods copy zstd's sources in at `pod
  install` and **delete them again after every build**. A build that
  follows another without an intervening `pod install` therefore fails
  with "Build input file cannot be found". Running it again fixes it.
- `HomeShell` draws its seven destinations two ways — a bar below a phone,
  a rail beside anything wider — from one list, so a destination cannot
  reach one and not the other. `shellNavigationFor` in
  `home/application/` decides, and is the testable half.
- Anything at the very top of `HomeShell`'s body is under the status bar.
  The shell consumes the top inset itself, once, so the warning banner
  does not sit beneath the clock and the tab below is not handed an inset
  nothing used. A second `SafeArea` inside either would double it.
- Comments in code are English; `docs/` prose is German.

## Conventions

Comments explain *why*, not *what* — the existing ones are the model to match,
including their density. Prefer extending an existing service over adding a
parallel one.
