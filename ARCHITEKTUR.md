# PreppSuite

Self-hosted-free household preparedness app (inventory, checklists, budget,
official warnings, shelter map). **Everything runs on the device.** There is
no server, no account and no network dependency beyond the public feeds the
app fetches itself.

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
generated once and never changes, because two devices sharing a folder have
to agree on it for their rows to merge rather than pile up side by side.

**Every local write must set `dirty: const Value(true)` explicitly.** The
column defaults to true, but a default only applies on INSERT, and
`insertOnConflictUpdate` writes just the columns the companion sets. Leaving
`dirty` out therefore updates an already-synced row's values while leaving it
marked clean. This was a real bug across all three controllers;
`inventory_controller_test` guards it. The flag now feeds shared-folder sync
rather than a server.

**Adding a drift column means a migration.** Bump `schemaVersion` and add the
matching branch to `onUpgrade` in the same edit — an existing install will not
recreate its tables.

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
- Comments in code are English; `docs/` prose is German.

## Conventions

Comments explain *why*, not *what* — the existing ones are the model to match,
including their density. Prefer extending an existing service over adding a
parallel one.
