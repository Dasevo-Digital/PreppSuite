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
```

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

**PMTiles is read through `ByteRangeSource`, never a `File` directly.** A
country extract is gigabytes: it is never copied and never fully read, and
on Android it is a `content://` document that `dart:io` cannot open at all.

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
- Android reaches the shared folder through the Storage Access Framework
  (`SafSyncFolder` plus the channel in `MainActivity.kt`), because a
  `content://` tree is not something `dart:io` can open. Both
  implementations must produce the identical layout — `deviceFilePath` and
  friends in `sync_folder.dart` are the single definition of it.
- The macOS build runs **without** the app sandbox, deliberately: under it
  a picked folder's permission dies with the process, and keeping it needs
  security-scoped bookmarks in Swift. The reason is written into
  `macos/Runner/Release.entitlements`; put it back only alongside that
  native code.
- Comments in code are English; `docs/` prose is German.

## Conventions

Comments explain *why*, not *what* — the existing ones are the model to match,
including their density. Prefer extending an existing service over adding a
parallel one.
