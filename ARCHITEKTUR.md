# PreppSuite

Self-hosted household preparedness app (inventory, checklists, budget,
official warnings, shelter map). Dart workspace monorepo on Serverpod 3.4.11.

| Package | Role |
| --- | --- |
| `preppsuite_server` | Serverpod backend: endpoints, services, Postgres |
| `preppsuite_client` | **Generated.** Never hand-edit; it is committed on purpose |
| `preppsuite_flutter` | The app (Flutter + Riverpod + drift) |

## Commands

Always `flutter pub get` from the repo **root** — it is a Dart workspace, and
resolving inside a single package is not equivalent.

```bash
flutter pub get                                  # root, resolves all 3 packages
flutter analyze                                  # root, covers all 3 packages
dart format --output=none --set-exit-if-changed .  # root
cd preppsuite_flutter && flutter test           # app tests, no backend needed
```

Server tests need a live Postgres + Redis:

```bash
cd preppsuite_server && docker compose up -d && dart test
```

Code generation:

```bash
cd preppsuite_server && serverpod generate        # after ANY .spy.yaml change
cd preppsuite_flutter && dart run build_runner build --delete-conflicting-outputs   # drift
```

`serverpod generate` rewrites `preppsuite_client` and
`preppsuite_server/lib/src/generated`; both are committed and CI fails if they
are stale. l10n is generated on build (`generate: true` + `l10n.yaml`), and the
output under `lib/l10n/generated/` is committed too.

## Architecture invariants

These are load-bearing — breaking one produces bugs that only show up on a
second device or after a restart.

**Drift is the source of truth for the UI.** Screens and providers read from
[`AppDatabase`](preppsuite_flutter/lib/local_db/database.dart), never from the
network. The app is fully usable offline; sync is a background reconciliation,
not a load path.

**Only [`SyncService`](preppsuite_flutter/lib/sync/sync_service.dart) touches
`client.*`.** Nothing under `features/` may call a Serverpod endpoint directly.
The exceptions are deliberately *not* Serverpod at all — third-party HTTP
clients (OpenFoodFacts, Overpass, WWBOTA, Nominatim) live in their feature's
`application/` folder and are called from there.

**The sync protocol, per entity:** push-then-pull. Local rows carry a
`clientId` (generated on device, the stable identity), a nullable `serverId`, a
`dirty` flag, and `deletedAt` for tombstones — rows are never hard-deleted.
Conflicts resolve last-write-wins on `updatedAt`. `DateTime`s must be
`.toUtc()`-normalized before crossing the wire (SQLite round-trips the right
instant but flags it local). Pull cursors live in the `sync_state` table.
Checklist templates sync before checklist items, because items reference
templates by *server* id.

**Every local write must set `dirty: const Value(true)` explicitly.** The
column defaults to true, but a default only applies on INSERT, and
`insertOnConflictUpdate` writes just the columns the companion sets. Leaving
`dirty` out therefore updates an already-synced row's values while leaving it
marked clean, and the edit is never pushed — silently, including deletions.
This was a real bug across all three controllers; `inventory_controller_test`
guards it.

**Adding a drift column means a migration.** Bump `schemaVersion` and add the
matching branch to `onUpgrade` in the same edit — an existing install will not
recreate its tables.

**No hard-coded user-facing strings.** Every one goes through `AppLocalizations`
with entries in both `app_de.arb` and `app_en.arb`. Enum-to-label mapping lives
in the feature's `*_l10n.dart` helper.

## Feature layout

```
lib/features/<feature>/
  application/    # logic, providers, HTTP clients — where the tests live
  presentation/   # widgets and screens
```

Keep decision logic in `application/` so it stays testable without a widget
tree; the test suite deliberately targets that layer rather than the UI.

Server side mirrors it: `lib/src/<feature>/` with `<feature>_endpoint.dart`
(thin, auth + validation), `<feature>_service.dart` (the actual work), and
`models/*.spy.yaml`.

## Gotchas worth knowing

- `file_picker` is pinned to `^8.3.7`; 9.x/12.x break file picking on macOS.
  The reason is written out in `preppsuite_flutter/pubspec.yaml` — read it
  before bumping.
- Auth tokens go through
  [`PrefsAuthKeyValueStorage`](preppsuite_flutter/lib/core/prefs_auth_storage.dart)
  rather than the Keychain, which would require a code-signing entitlement.
- `meteoAlarmCountrySlugs` (server) and `warningFeedCountries` (app) are two
  hand-maintained lists that must stay in sync.
- Warning region filtering is coarse by design in v1, and BBK warnings have no
  expiry. The limits are documented in [`docs/warning-feeds.md`](docs/warning-feeds.md).
- Push notifications go out from the server via FCM (which relays to APNs for
  iOS). `PushDevice` is deliberately *outside* the push/pull sync — a token
  belongs to one device and must never travel to another. Without a
  `firebaseServiceAccount` password the server boots normally with push off,
  and `firebase_messaging` is not a dependency until the project's config
  files exist (the Gradle plugin fails the Android build without them). See
  [`docs/push-notifications.md`](docs/push-notifications.md).
- `notificationsEnabledProvider` returns `false` for one turn of the event
  loop before its persisted value loads. Anything that *acts* on the setting
  rather than displaying it must `await ensureLoaded()` first — reading the
  provisional `false` unregistered the device on every launch.
- Comments in code are English; `docs/` prose is German.

## Conventions

Comments explain *why*, not *what* — the existing ones are the model to match,
including their density. Prefer extending an existing service over adding a
parallel one.
