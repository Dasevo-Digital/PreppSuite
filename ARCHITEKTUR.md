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

Linux is built in a container from here — see [`tool/docker/`](tool/docker/),
but on Apple silicon that produces **arm64**. Windows cannot be built on a
Mac at all.

**The shipped x64 packages for both come from two machines on the LAN**,
`TestKubuntu` and `TestWindows` in `~/.ssh/config`, each with Flutter
3.44.8 installed. `.github/workflows/build-desktop.yml` describes the same
builds and is useful as a list of what they need, but it is **not** a build
path here: the repository lives on Gitea and has no Actions runner
registered — zero runs, checked. Anything saying the workflow is the only
way to a Windows build is wrong and has cost a detour before.

The source goes over as a tarball of the tag rather than a checkout, so
what is built is exactly what was tagged and no local build residue comes
along:

```bash
git archive --format=tar.gz --prefix=src/ -o /tmp/src.tar.gz v<version>
# TestKubuntu: extract, then
#   flutter pub get
#   preppsuite_flutter/native/zim_xapian/build_linux.sh   # before the app
#   cd preppsuite_flutter && flutter build linux --release
# TestWindows (cmd.exe over ssh): extract with `tar -xzf`, then
#   cd ...\preppsuite_flutter && flutter build windows --release
```

The Xapian step has to run **before** the app or CMake will not bundle the
library, and skipping it silently costs the archive's own full-text index —
1.5.0 shipped a Linux package without `libzim_xapian.so` for exactly that
reason.

**Windows gets the same shim, and never builds it itself.** `flutter build
windows` produces no `zim_xapian.dll` — the Visual Studio toolchain has
nothing to build it from, because xapian-core 1.4 dropped its MSVC project
files. It is cross-built on TestKubuntu with mingw-w64
(`native/zim_xapian/build_windows.sh`, needs `mingw-w64` and
`libz-mingw-w64-dev`), copied over, and placed beside the exe **before**
the zip is made. Count the entries: **56 is right, 24 means the DLL and
its dependencies are missing.**

**After every release, put this Mac back in order** — the machine that
builds is also the machine that uses the app, and a build leaves copies
behind:

```bash
tool/macos_install.sh ~/Desktop/PreppSuite-Release-v<version>-Upload/PreppSuite-<version>-macos-universal.zip
```

It installs the released bundle as both `/Applications/PreppSuite.app`
and `/Applications/PreppSuite Test.app` (same build, own identifier, own
sandbox container), re-signs both from `Release.entitlements`, and then
runs `tool/macos_spotlight_clean.sh` so Launch Services and the file index
know these two and nothing else. Install from the **release zip**, not
from `build/`: that way what is on this machine is byte-for-byte what was
published. Without this step the two installed apps keep the previous
version while Spotlight also offers the build tree's copy — three
PreppSuites, two of them wrong, in the menu somebody uses to reach their
own inventory.

Generated data assets:

```bash
tool/dwd_warncells.py    # assets/dwd_warncells.csv, when the DWD list changes
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

**Sync versions are ordered by `updatedAt`, then by shared contents.**
SQLite stores seconds. Every local upsert transaction advances the stored
row's timestamp by at least one second if the wall clock has not advanced.
Rapid edits and clock corrections therefore cannot reuse or decrease a
version. A timestamp is a logical version, not an exact audit time.
At equal timestamps, tombstones outrank live rows, then the lexicographically
larger canonical JSON of shared columns wins. Column names are sorted;
`dirty`, `photo_path` and `updated_at` are excluded, and dates use epoch
seconds. Identical snapshots remain no-ops. All household devices need this
merge rule for guaranteed convergence; the on-disk and wire formats stay
unchanged. Unseen edits on a device with a fast clock can still win.

**Publishing acknowledges exact row versions, never a wall-clock cutoff.**
Only the client ids and timestamps actually included in the uploaded snapshot
may have `dirty` cleared. Edits made during the write remain pending, even
when the logical timestamp leads the clock.
The first sync after upgrading republishes clean rows once, recorded per
household/device in `sync_state`, to recover old write/ack races.

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

**Map labels come from the archive, never from the app.** There is no
list of city names in the code, and there must not be one: a hard-coded
"Braunschweig" marker existed until 1.6.0 on the theory that the renderer
dropped the label. It did not — the extract's own `place` layer carries
Braunschweig from zoom 7 — so the marker drew a second copy from 7 up and
invented one at 6, where the schema names no city of that size in any
country. It also only applied to the map screen and not to the shelter
map, so the two disagreed about the same place.
`test/live/offline_map_labels_test.dart` checks the archive instead.

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
is by bytes and Wikipedia titles start with a capital.

**Full text has two indexes, and the archive's own is asked first.**
`builtInIndexProvider` opens the Xapian database lying inside a Kiwix
archive; `knowledgeFullTextProvider` uses it when it is there and falls
back to `KnowledgeIndexDatabase` — the FTS5 index `KnowledgeIndexer`
builds — when it is not. Four ordinary things send it down the fallback:
no native library in this build (the three desktop platforms carry one),
an archive with no index, an index in a compressed cluster, and a
location that is not a path, which is Android. The wrapper is `XapianSearcher`, which keeps
`XapianIndex` on an isolate of its own: the binding blocks, and one Xapian
database tolerates exactly one user at a time — the message queue is the
lock. See [`docs/volltextsuche-xapian.md`](docs/volltextsuche-xapian.md).

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

**A downloaded archive is validated against the server's length, never
the catalogue's.** Kiwix's OPDS catalogue rounds its stated file sizes up
— it offers 6,941,696 bytes for a file of 6,940,898 — so checking against
that figure rejects every download it describes. `estimatedLength` is
shown and nothing else; what a finished file has to match is the length in
the server's own `Content-Length` or `Content-Range`.

**`PmTilesWriter.add` serializes its writes, and has to.** The area
downloader fetches several tiles at once, and a `RandomAccessFile` throws
on a second pending write — besides which the offset bookkeeping is only
correct one tile at a time. The queue also has to survive a failed write,
or the first bad tile fails every tile after it.

**The tile journal is written after the bytes, never before.** A map
download survives the app closing because `PmTilesWriter` keeps a journal
of `tileId offset length` beside its scratch file — but only once the
bytes are flushed. A journal line describing bytes that are not there
produces a corrupt archive; bytes no line describes cost one tile, and
`PmTilesWriter.resume` truncates the scratch to what the journal accounts
for. That asymmetry is the whole reason the order is fixed.

**Cancelling a map download pauses it.** `MapAreaDownloader` calls
`writer.close()` rather than `abandon()` on the way out, and the session
file stays; only `discard()` and starting a new download delete the
working files. A country is over an hour of tiles, so treating a
cancellation as "start again" would mean the feature never finished for
anything larger than a town.

**A map download is a plan of rings, not one area.** `staggeredPlan`
gives each ring a band of zoom levels — the country coarse on the
outside, the chosen place at full detail — and searches for the deepest
bands that fit the budget, preferring the inner rings. That is what makes
a whole country possible at all: Germany flat at zoom 14 is 319,812
tiles, staggered around Hannover it is 85,063 with every street in
Niedersachsen still in it. A ring its neighbour already covers to the
deepest level drops out, or the plan would hold a level back for a town
that its state already contains.

**The tile limit is a request budget, never a storage one.** The app must
work offline, so the archive may be as large as the device allows; what
is rationed is how many times a public tile server is asked. Anything
that reads the limit as "how much disk to use" has it backwards.

**The tile limit is where "a Bundesland at full detail" is decided.** It
is set to 100,000 so that every German state fits at zoom 14 — the
largest, Bayern, is 68,028 tiles by Nominatim's bounding box — and a
country does not: Germany would be 319,812, some fourteen gigabytes and
as many requests as tiles, against a server run for other people. Moving
it changes which places the feature can promise, so move it with the
numbers in `docs/karte-offline.md`.

**A downloaded map must copy the source's `vector_layers` into the
archive's metadata.** That list is how `_schemaLooksRight` tells an
OpenMapTiles archive from a Protomaps one, and without it the app refuses
the archive it just built. It is also why the tile source has to be one
that speaks OpenMapTiles — OpenFreeMap and MapTiler's `tiles/v3` do; the
`.pmtiles` files circulating on the web mostly do not.

**Adding or removing a drift column means a migration.** Bump
`schemaVersion` and add the matching branch to `onUpgrade` in the same edit —
an existing install will not recreate its tables. Removing one needs
`m.alterTable(TableMigration(table))`, since SQLite cannot drop a column in
place; `migration_to_8_test` writes out the old schema by hand and upgrades
it for real, which is the only way that path is ever exercised.

**A column added to `inventory_items` has to be named in the schema-8
branch's `newColumns`.** `alterTable` recreates the table from the
definition as it stands *today* and copies every column in it — so a
column added later is one that SELECT reads out of a version-7 table
which never had it, and the upgrade dies. Naming it in `newColumns`
makes the rebuild create it empty instead; its own branch then has to
read `from == 8` rather than `from < 9`, because anything older already
got it from the rebuild. `migration_to_8_test` and `migration_to_9_test`
cover the two halves.

**Every road a household travels goes through `snapshot_exchange.dart`.**
The shared folder, the QR chain, the local handover *and the encrypted
backup* all read and merge through the same two functions. The backup
service used to spell both out again, which meant a table added to the
snapshot was simply absent from every backup — with no error, and no way
to notice until somebody restored one. A second copy of the merge is a
second set of tie-break rules; a second copy of the read is silent data
loss. `backup_service_test` now asserts that a newer table comes back.

**What is not in the database is not in the backup — unless it says so.**
The crisis plan in `preparedness_hub_store.dart` is the one exception to
"drift is the source of truth": a radio frequency, a document location
and an evacuation route are deliberately kept out of the shared folder,
because they should not travel to every household device just because the
inventory does. For a while that also meant they were in no backup, so a
lost phone took the whole plan with it — the same silent loss as the
missing table above, one layer further out. The backup now carries the
plan in its own encrypted section (`'device'`), under the same passphrase
and outside the snapshot, so an older version reads the household from a
newer file and a newer version finds no plan in an older one. Restoring
merges rather than overwrites: every note, card and station carries the
date it was last checked, and the later one wins, so a restore onto a
device somebody kept using cannot wind the plan back. Crisis mode is the
exception to the exception — it describes what this device is showing
right now, so a restore never switches it.

Anything else that grows outside drift inherits this problem. A new
`SharedPreferences` key that holds something a household would be sorry
to lose is not finished until it is named here and in a backup test.

**The snapshot format in `device_snapshot.dart` is a contract, not a dump.**
Row codecs are hand-written rather than drift's generated `toJson` precisely
so that a migration does not silently change a file format other installs —
and older app versions — have to keep reading. A decode returns null for
anything it cannot use, which costs one row instead of the whole sync.

**Who the household feeds lives in `HouseholdProfile`, nowhere else.**
The inventory screen used to keep a second, device-local person count
beside the household's own, and the two silently disagreed. The supply
calculator reads the profile.

**The stockpiling tables are a citation, not the app's advice.**
`storage_plan.dart` reproduces the BLE's two *Vorratstabellen* — mixed
diet and ovo-lacto-vegetarian, one person and ten days at 2,200 kcal —
with the amounts and energy figures exactly as printed. Group totals are
stored as printed rather than summed from the rows, so a transcription
error shows up instead of being hidden, and `storage_plan_test` checks
every row's printed total against its own per-100 g figure, which is the
only thing that can catch a slipped digit in sixty copied numbers. The
food names live in that file with an English name beside each rather
than in the `.arb` files, for the same reason the built-in checklists do:
a table split across sixty translation keys cannot be checked against
the original. There is **no official vegan table** — the BLE publishes
two and the app prints no third; the screen names the rows a vegan
household has to replace instead. `StorageNutrient` is the one thing the
app adds, and it says so on screen.

**Nutrition figures are stored exactly as the label prints them**, per
100 g or per 100 ml, for all five. Nothing is converted at scan time any
more — see "Nutrition is per 100 g" below for the two bugs that came out
of converting there, and for why food and water are the only categories
whose unit must name a measure. A null means the label did not say and is
never stored as zero —
the supply calculator adds these up, and a guessed zero is
indistinguishable from a measured one. A nutrient heavier than the
package it is in is rejected, which is what catches the common Open Food
Facts error of a per-package figure typed into the per-100 g field.

**Where a public authority publishes the interpretation, the app uses
theirs.** Three live feeds now show a bare number, and a bare number is
unreadable or frightening or both: a gauge reading, a gamma dose rate and
a fire-danger step. So every band is the issuing authority's own.
PEGELONLINE's long-run reference levels place a water level; the BfS
states 0.05–0.2 µSv/h as natural, rain lifting a reading by up to a
factor of three for hours as harmless, and an event only in question past
that or after a day; the DWD names its five WBI steps "sehr geringe" to
"sehr hohe Gefahr". None of the three screens invents a threshold, none
of them calls itself a warning, and each says so — a real warning arrives
through the BBK feed. `radiation_level.dart` and `fire_danger_level.dart`
carry the sources in their library comments.

**Where no German authority publishes the interpretation, a foreign
one is quoted by name.** The blackout clock in
`energy/application/outage_food_safety.dart` is the only place this
applies: four hours of refrigerator, forty-eight of a full freezer,
twenty-four of a half-full one, and perishables gone two hours above
4 °C. Those figures are FEMA's and the USDA's. The BZfE, the BfR, the
BMEL and the Verbraucherzentrale were all checked and all describe the
principle without stating hours. So the rule above gains one sentence
rather than an exception: the source is named on the screen. A cold
chain is not a national quantity, and the alternative — this app
choosing its own number — is the thing the rule exists to prevent. See
[`docs/us-behoerden-abgleich.md`](docs/us-behoerden-abgleich.md) for the
whole comparison, including what was already covered and what was
deliberately left out.

**The possessions list is not the supply list, and mixing them would
break both.** `inventory_items` answers "how long do the stores last" —
quantities, expiry dates, calories, and the supply calculator adding it
up. `possessions` answers "what did we lose", which is what an insurer
asks after a fire and what nobody answers from memory. They are separate
tables on purpose: a washing machine in the calorie target is what one
table would produce. The photo on a possession stays on the device that
took it, like an inventory item's, which is why the PDF export exists at
all — a list of what burned that lives only in the flat that burned is
not a list.

**A dose rate is judged against its own probe, not against one national
number.** `baselineFrom` takes the median of the station's last week —
the median precisely because every rainfall in that week is a spike of up
to three times the baseline, and a mean would fold the spikes into the
thing they are measured against. Hausach reads 0.157 µSv/h in perfectly
ordinary weather; against the national ceiling of 0.2 the Black Forest
would look permanently raised.

**The DWD station list is Latin-1.** It is the only file in this app that
is, and reading it as UTF-8 mangles every umlaut in it — the same class
of mistake as `KiwixCatalogue` reading `response.body`, from the other
direction. `fire_danger_live_test` asserts "Großenkneten" against the
real server for exactly this.

**Figures that are official and figures this app invented are kept
apart.** `SupplyHead` carries one rate per kind of head and says at each
where it came from. The BBK's page states 1.5 + 0.5 litres and ~2200 kcal
for an adult and nothing for children or animals; its own pointer, the
BLE stockpiling table, does carry a children's figure in a footnote — 1
litre of drinking a day up to age 12, per DGE and MRI — and that is what
the app uses, plus the same 0.5 for cooking. The 1400 kcal for a child
and the veterinary water rates are still the app's own, labelled as such
in the code and on screen. The same footnote's 2 litres from age 65 is a
note on the inventory screen rather than a fifth head: age is not in the
profile, and asking for it to adjust one number would be a poor trade.
Pet food is never added to the calorie target: those are human calories,
and counting dog food in them would report a household as fed when it is
not.

**No hard-coded user-facing strings.** Every one goes through
`AppLocalizations` with entries in both `app_de.arb` and `app_en.arb`.
Enum-to-label mapping lives in the feature's `*_l10n.dart` helper.

**The first aid guides are the one deliberate exception to that,** and
they are content rather than interface: `first_aid_guides_de.dart` and
`first_aid_guides_en.dart`, one file per language. Medical text has to be
reviewable as prose against the guideline it came from, and two hundred
strings scattered through fourteen hundred lines of interface wording
cannot be read end to end by anybody. `first_aid_guides_test.dart` holds
the two files to the same ids, the same order and the same number of
steps, cautions and figures â a translation that quietly drops a step
drops a step of a resuscitation. Buttons and headings on those screens go
through the ARB files like everything else.

**First aid works on a fresh install with no network, no download and no
setting.** That is the whole reason it is its own feature rather than a
corner of `features/knowledge/`, which is an encyclopedia behind a
multi-gigabyte archive. Nothing on those screens may come to depend on a
download, a profile or a permission. The optional video pack is built so
that no guide needs it.

**A `FirstAidGuide.id` is a published name.** A downloaded video pack
names it to say which guide a clip belongs to, so renaming one orphans
every video that pointed at it. Adding is free; renaming is not.

**The compression pacer is a pure function of elapsed time,** never a
counter a timer increments. 110 a minute is 545,454.54â¦ Âµs; a counting
pacer is several beats adrift after two minutes, which puts the count of
thirty â and therefore the breaths â in the wrong place. See
`compression_pacer.dart`.

**A video pack manifest is untrusted input.** It arrives from an address
somebody typed or a zip somebody was handed, and is far likelier to be a
captive portal's login page than a manifest. `file` must be a plain
basename; anything with a path in it is dropped rather than written. On
import, only entries the manifest itself names are extracted. Size and
sha256 are checked after every download, and a file that fails is deleted
rather than kept under its final name.

**There is one folder, and it is a document, not five exports.** This
app is built on the assumption that the device may be gone — that is why
the database is local, why the maps download and why the knowledge
archive is offline. Paper is the last fallback under all of it, and it
used to come in five separate exports on five separate screens, each
partial, with the household expected to know all five existed. The crisis
hub even asked whether copies of the important papers were ready and then
gave no help answering. `emergency_folder_report.dart` is that help, and
it sits behind exactly that question.

Two things it deliberately leaves out: the possessions list is for an
insurer and belongs in another drawer, and the missing-equipment report
is a shopping list, not a record. Empty sections print as empty rather
than vanishing, because a folder that shows its own gaps is one somebody
can finish. The emergency cards are asked about every time and never
remembered, exactly as `EmergencyPlanReport` argues; `emergencyCardRows`
is shared between the two so the rule that an empty field is left off the
sheet cannot drift apart.

**The bundled font is a subset, and U+2192 is not in it.** `tool/font_instance.py`
cuts NotoSans down, and an arrow written into a PDF prints as nothing at
all — silently. The crisis briefing had been shipping an invisible one in
every evacuation line. PDF text uses `->`; the screen, which has the
system font, may keep the real arrow. Measured with a probe over the
bundled asset: U+2013, U+2014, U+00B7, U+00BB, U+203A and U+2026 are all
present, U+2192 alone is not.

**The app reports what is happening; the household decides what to do
about it.** "Crisis mode" used to be a switch on one screen that scaled
that screen's text by a quarter, while the app already knew when
something was going on — a severe warning over the household's own
region, a blackout clock somebody had started — and none of it reached
the page the plans are on. `current_situation.dart` is that join, and it
is deliberately narrow: severe and above only, because an app that cries
wolf over a wind advisory is one people learn to scroll past.

What it must not do is act. The larger display stays an offer, and the
incident log opens the ordinary dialog with the warning's own words
filled in rather than writing an entry itself. A screen that rearranges
itself because a feed said so is a screen nobody can rely on, and a log
the app wrote is not a record of what the household saw.

**A reach the app can divide, it does not ask for.** Four of the crisis
hub's five autonomy figures were already calculated elsewhere — water and
food in `supply_calculator.dart`, medicines in `medication_range.dart`,
stored energy in `energy_range.dart` — and the hub asked the household to
type them in anyway, beside an inventory that knew them. That is the same
second, silently disagreeing number the supply calculator itself had and
removed. `autonomy_overview.dart` divides the records; the hand-entered
figures survive only as the fallback for what cannot be divided.

The division has to be able to fail out loud. Water in crates rather than
litres, food with no calorie figure, a medicine with no daily dose, a
reserve nothing draws on: each of those is a gap the screen names, never
a zero, and never quietly dropped from a total — a reach that omits half
the cupboard reads as covering all of it. Hygiene has no calculation at
all and is not given one, because nothing in this app counts soap.

**A photo drawn small is decoded small.** `InventoryPhotoService` stores
pictures at up to 2000 pixels wide, and what a picture costs in memory is
the size it is decoded to, not the size it is drawn at: one of them is
eleven megabytes of pixels, and Flutter's whole image cache holds a
hundred. The possessions list draws them at 48 by 48 and builds every
tile at once, so without a `cacheWidth` eight photographed items filled
that cache and the ninth started evicting the others — after which every
rebuild decoded JPEGs again. Measured before and after in
`possessions_photo_memory_test`: 91.6 MB down to 0.8 MB.

Width only, never both axes: two of them stretch the picture to the
target rectangle before `BoxFit.cover` crops it. And the number is taken
from the picture's *short* side, because that is the one `cover` fills
the box from — on a landscape photo in a square tile that is the height.

**Work that does not change is not repeated every frame.** Decoding a
warning's areas walks every coordinate pair it names; the situation map
draws many at once and rebuilds on every filter chip and every poll. At a
storm-day feed of 120 warnings that was 14 ms a rebuild and at a
saturated one 71 ms, on a desktop machine — a phone is slower and a frame
is 16 ms. `WarningPolygonCache` keys the result by the warning's identity
and the time it was last written, so a rewritten warning decodes again
and an ended one is forgotten. It is handed everything the feed holds,
not what a filter left of it: otherwise turning a filter on would discard
exactly what turning it off again needs.

**A Windows package is launched in a Windows Sandbox, not on the build
machine.** A developer machine has the Visual C++ Redistributable, and a
user's machine may not; starting it where everything is already installed
proves nothing. That is how the packages came to be shipped for months
needing a runtime they did not carry — the failure is silent, with no
crash, no message and no event-log entry, just a process sitting at five
megabytes with no window. The check runs a control package alongside the
new one, because a failure on its own does not say whether the package or
the environment is at fault. See `tool/windows-startcheck/`.

**The sandbox does not get past Smart App Control.** It inherits the
host's state, and TestWindows has it enforced, so no unsigned binary runs
there at all -- not from an archive and not straight out of the build
folder. Either that is turned off on the host (one way only: turning it
back on needs a reinstall of Windows) or the binaries are signed. Until
then the Windows launch check cannot run on this hardware.

**`CompanyName` stays `com.example` until a Windows build can be
launched, and that is a decision, not an oversight.** On Windows
`path_provider` builds its directory out of the executable's version
resource: `%APPDATA%\<CompanyName>\<ProductName>`, from `Runner.rc`, with
no fallback. Changing that string moves the household database, the
product photos and the WebView2 working directory in one step, and the
takeover that exists today only covers the documents folder of a much
older version, not one Application Support path to another.

So the change needs a second legacy candidate — `%APPDATA%\com.example\
PreppSuite` — and it needs to be *launched* against a real household
before it ships, because a takeover that silently does nothing leaves
somebody with an empty app and their data still on disk under a name
they will never look for. Smart App Control makes that run impossible
here today, so the change waits for the certificate rather than going
out unverified. When it does go out, the name is **MMDM**, in
`CompanyName` and in `LegalCopyright`, and the takeover ships in the
same release — not after it.

The cost of waiting is known and accepted: every release adds installs
that the takeover will later have to find.

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
that. Several archives stay registered and one is open at a time, so the
reader, the server and the full-text index all belong to whichever that
is — the index is a database file named after the archive's id, which is
what lets switching keep it. The server is what makes links, images and stylesheets inside an
article resolve without any code — they come back to the same origin. It
is also what makes the platform split cheap: `articleViewer` picks an
embedded panel where `webview_flutter` reaches an engine and a window of
its own on Linux and Windows, where it does not, and both are handed the
same URL.

`features/downloads/` is the shared machinery for fetching things that
are measured in gigabytes: a resumable HTTP download, where the files
land, and the banner both features show. It knows nothing about maps or
archives — the caller passes a callback for what to do with the finished
file.

`features/possessions/` is the household's inventory of what it owns,
with a PDF export meant to be kept somewhere else.

`features/first_aid/` is the instructions, the drawings the app paints
itself, the compression pacer and the optional video pack. It is the only
feature that is fully usable the moment the app is installed. See
`docs/erste-hilfe.md`.

`features/sharing/` is the shared-folder sync. `SyncFolder` is an interface
over "a directory" with a `dart:io` implementation, so the merge is tested
against an in-memory folder with several databases standing in for devices.

Keep decision logic in `application/` so it stays testable without a widget
tree; the test suite deliberately targets that layer rather than the UI.

## Gotchas worth knowing

- `flutter test integration_test/` leaves a
  `GeneratedPluginRegistrant.java` behind under
  `android/app/src/main/java/io/flutter/plugins/`, with the
  integration_test plugin registered in it. The file is git-ignored, so it
  never shows up in a diff, and the next `flutter build apk --release`
  compiles it against a classpath that has no integration_test: the build
  dies on "Package dev.flutter.plugins.integration_test ist nicht
  vorhanden" and points at a file nobody wrote. Deleting it is enough --
  the build regenerates it correctly. `tool/android_release.sh` removes it
  before building for exactly this reason.
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
- **Linux has no scheduled notifications at all.** The freedesktop
  specification only knows notifications shown now, so the plugin
  implements neither `zonedSchedule` nor `pendingNotificationRequests` and
  throws when either is called — which, from a timer behind every tab, is
  an unhandled exception every few minutes. `supportsScheduledNotifications`
  gates both, and the settings screen explains rather than offering a
  switch that cannot work. Warnings still arrive there; they are shown,
  not scheduled.
- iOS needs a deployment target of at least 14.0 — `workmanager-apple`
  brings the floor. It lives in three places in `project.pbxproj` plus
  `ios/Podfile`.
- The `zstandard` iOS and macOS pods copy zstd's sources in at `pod
  install` and **delete them again after every build**. A build that
  follows another without an intervening `pod install` therefore fails
  with "Build input file cannot be found". Running it again fixes it.
- `HomeShell` draws its nine destinations three ways — a bar below a
  phone, a rail beside anything wider, and a "more" sheet for what the bar
  has no room for — from one `ShellDestination` list, so a destination
  cannot reach one and not the others. `shellNavigationFor` and
  `shellSlotsFor` in `home/application/` decide, and are the testable
  half. `shellSlotsFor` guarantees the open destination is always on the
  bar, swapping it into the last slot when it would otherwise be hidden;
  without that the bar shows no selection while that screen is on display.
- Warnings are both a banner above every tab and a destination. The banner
  is the one that must be seen without looking; the screen behind it is
  where the history, the filter and the ones concerning somewhere else
  live. The overview card, the destination badge and the banner all count
  through `isWarningRelevant`, so none of them can report calm while
  another is red.
- Anything at the very top of `HomeShell`'s body is under the status bar.
  The shell consumes the top inset itself, once, so the warning banner
  does not sit beneath the clock and the tab below is not handed an inset
  nothing used. A second `SafeArea` inside either would double it.
- The photo editor's crop rectangle is a fraction of the *picture*, not
  of the box it is drawn in. `_CropArea` therefore sits inside an
  `AspectRatio` set to the image's own proportions and draws with
  `BoxFit.fill`; with `contain` the letterboxed margin would count as
  part of the picture and the crop would land somewhere else than the
  frame did. Rotation happens before the crop in `applyPhotoEdit` for the
  same reason: the rectangle was drawn on the turned picture.
- `img.decodeImage` throws on a truncated file rather than returning
  null — it sniffs the format by reading a header straight out of the
  buffer. `applyPhotoEdit` catches, because it runs on a worker isolate
  and an uncaught throw there loses both the picture and the message.
- **The distributable Android package is not what `flutter build apk`
  produces.** Since 0.11.0 the APK carries a signing-certificate lineage
  (`android/signing-lineage.bin`) proving the old debug key authorised the
  release key, which is the only thing that lets an existing 0.8.0-0.10.0
  install update instead of being uninstalled. The Android Gradle Plugin
  cannot attach a lineage, so `tool/android_release.sh` re-signs the Gradle
  output with apksigner and refuses to leave behind an APK where the
  certificate per SDK range is not exactly: debug for API 24-32, release for
  API 33+. Handing out the plain Gradle APK is not a cosmetic mistake — it
  breaks the update path silently and costs the user their local data.
  Consequence: `~/.android/debug.keystore` is part of the signature, not a
  leftover, until `minSdk` reaches 33. The 33 boundary is apksigner's
  default (rotation goes into a v3.1 block); see README for why it is not
  lowered to 28.
- **The first Windows build in a fresh checkout can produce a plugin DLL
  that will not load.** Seen while packaging 0.13.0: the build reported
  success, and the app died at startup with `0xC0000142`
  (`STATUS_DLL_INIT_FAILED`) before any Flutter code ran, so there is no
  log and no crash report. Swapping the rebuilt DLLs one at a time found
  `desktop_webview_window_plugin.dll`; the build had also printed "Nuget.exe
  not found, trying to download or use cached version", which is how it
  fetches the WebView2 package. `flutter clean` and a second build produced
  a working DLL from the same source. Nothing detects this except starting
  the binary — which is why every desktop package is launched before it
  ships, not merely compiled.
- **`android/gradlew clean` deletes every platform's build output, not
  Android's.** `android/build.gradle.kts` redirects
  `rootProject.layout.buildDirectory` to `preppsuite_flutter/build` — the
  directory Flutter puts *all* platforms under — and the `clean` task it
  registers deletes that whole directory. Running it in the middle of
  assembling a release throws away the macOS and Linux bundles that are
  already built. Use `flutter clean` if that is what you mean, and
  otherwise nothing: the Android build has no stale-output problem that
  needs it.
- **The shopping list answers two different questions and keeps them
  apart.** The gap to the household target (`calculateSupply`) says
  whether the stores would carry everyone through the planned days; the
  per-item lines say what goes in a basket, and only an item whose
  household gave it a `minQuantity` can be short of one. An item without a
  minimum is unanswered, not empty — counting it as missing would fill the
  list with everything ever entered.
- **The rotation queue leaves out what cannot be rotated.** No expiry date
  (salt) and nothing left (quantity zero) are both excluded, and days are
  counted as calendar days rather than elapsed hours so "tomorrow morning"
  reads as 1 and not 0. Its `soon` window is the overview's `soonWindow`,
  re-exported rather than redeclared: the two must never disagree about
  the same item.
- **An encrypted folder is written as `household.json` version 2, a plain
  one stays at version 1.** Writing 2 unconditionally would lock every
  household out of its own folder the day one member updated, because an
  older app refuses a version it does not know. For an encrypted folder
  that refusal is right — it could not read the device files anyway — and
  for a plain one it would be a disaster.
- **Encryption cannot silently fall back to plaintext.** A household-specific
  requirement is persisted locally and survives forgetting its key. Missing or
  plain metadata for a previously encrypted household stops sync with
  `encryptionChanged`, including a second identity check before publication.
  Version 2 without vault metadata is invalid. A saved key must pass the
  folder's authenticated check value before reading or writing.
- **A device without the folder key writes nothing at all**
  (`SharedFolderSyncError.locked`). Publishing a plaintext device file
  into an encrypted folder would silently undo the encryption for every
  row that device owns, and no later sync would put it back. Both shapes
  are *read*, though: a household does not update every device in the same
  minute, and dropping the plain files would make rows vanish for
  everyone until it had.
- **`HouseholdPlans.clientId` is the household id, not a generated one.**
  Every other table follows "a client id is generated once, on one
  device"; the plan deliberately does not, because it is a single record
  the whole household edits. Two devices writing the same key let
  last-writer-wins settle it; generated ids would give each device its own
  plan and the two would never converge. The price is that
  `adoptHouseholdId` has to *re-key* this row rather than re-stamp it —
  keeping its `updatedAt`, so the joined household's own plan can still
  win — and `_syncableTableNames` must not list it, because that list is
  read by the schema-6 repair, which runs before schema 10 creates the
  table.
- **`HouseholdMembers` is health data and the only table that is.** It
  travels through the shared folder like every other row, which is why
  the folder can be encrypted at all — the emergency-card screen says
  which of the two states the household is in before anyone types a
  diagnosis into it. Unlike the plan, its client ids are generated: these
  are many rows, each created on one device, so `adoptHouseholdId`
  re-stamps them the ordinary way.
- **macOS ties every permission to the code signature, not to the bundle
  id.** The designated requirement of an ad-hoc signed app is a `cdhash`
  — a fingerprint of that exact binary — so every build is a different
  app as far as TCC is concerned, and folder and location access get
  asked for again after each update. A real signing identity is the only
  thing that fixes it for camera and location; the sandbox is what fixes
  it for folders. `tool/macos_sign.sh --identity <name>` takes one when
  there is one.
- **The macOS build runs sandboxed since 0.14.0**, with
  `macos/Runner/StorageBridge.swift` as the AppKit twin of the iOS file —
  same method names, same `bookmark://` scheme, same Dart above it. The
  panel is the one part that cannot be shared: picking and writing the
  bookmark must happen in a single native call, because the permission
  hangs on the `NSURL` the panel returns and not on its path.
- **Apple's automatic container migration only runs when the system
  creates the container.** A container left over from an earlier
  sandboxed launch makes it skip silently, and the app then starts on an
  empty household while the real one sits outside, unreachable. That is
  not hypothetical — it is what the development machine looked like.
  `macos/Runner/SandboxMigration.swift` does it explicitly instead, before
  the engine runs any Dart, because the Dart-side migration would
  otherwise settle for the container's empty Documents folder first.
- **`flutter build macos` puts `com.apple.security.get-task-allow` in the
  Release bundle** — a debug entitlement that would be rejected by
  notarization. `tool/macos_sign.sh` re-signs from `Release.entitlements`
  and strips it, which is one more reason to run it on anything shipped.
- **`FileHandle.read(upToCount:)` and `seek(toOffset:)` need macOS
  10.15.4**, and the deployment target is 10.15. `StorageBridge` keeps the
  older non-throwing pair behind an `#available` for those four point
  releases rather than raising the minimum.
- **Spotlight's app results come from Launch Services, not from the
  disk.** Deleting a copy of the app does not remove it from the search:
  the database keeps an entry per bundle it has ever seen and goes on
  offering it. Seventeen of the twenty PreppSuites registered on the
  development machine pointed at paths that no longer existed — old
  release folders, the Trash, an external volume. `lsregister -u <path>`
  removes one, and `tool/macos_spotlight_clean.sh` does the sweep;
  `tool/macos_install.sh` runs it. `.metadata_never_index` is not an
  alternative — on macOS 26 the marker is ignored, verified with a probe
  file next to it — so a build must be removed rather than hidden.
- **Nothing of this app goes into a cloud backup.** Android's is on by
  default and would have taken the shared folder's key out of
  `SharedPreferences` along with the household database — a second copy
  somewhere the household does not control, which is the exact thing
  `folder_crypto.dart` exists to prevent. `allowBackup="false"` plus
  `data_extraction_rules.xml` close it; device-to-device transfer stays
  allowed, because that is a cable between two phones in the same hands.
  On iOS the equivalent is per-file: `excludeFromBackup` marks every
  download, or a fifty-gigabyte encyclopedia would be uploaded to
  somebody's iCloud.
- **A failure reaches the screen as a sentence, not as a type.**
  `describeError` maps the failures that actually happen — no network, an
  archive that moved, a refused permission, a database complaint — onto
  plain language, and keeps `error.toString()` only for the ones nobody
  named. This app is opened when something has already gone wrong, which
  is the worst moment for "SqliteException(11)".
- **An index records how it was built.** `KnowledgeIndexDatabase` keeps
  the stemmer's name in its own state, and `search` reads it back rather
  than working it out again. A query stemmed differently than the text
  finds nothing, and nothing reads exactly like an article that is not
  there — there is no error to notice. It also settles the upgrade: an
  index from before 0.15.0 answers null, is searched unstemmed, and goes
  on working instead of being thrown away, which for a whole Wikipedia
  would be an hour of rebuilding.
- **The two stemmers have to agree.** Where an archive carries its own
  index, Xapian stems; where it does not, `germanStem` does. The same
  search finding different articles depending on the platform would be
  the worst kind of difference, so the Dart one is a transcription of
  `german.sbl` rather than an approximation, and it is measured against
  Xapian's output over a whole German dictionary — 356 006 words, no
  disagreement. `tool/german_stems.sh` regenerates the fixture.
- **A `regionKey` must never be free text.** The region filter compares
  keys, and a key it cannot match does not read as "somewhere else" — it
  reads as nowhere, and the warning is dropped. MeteoAlarm's `areaDesc`
  went in unchanged until 0.15.0, which cost every severe-weather warning
  it carries: measured against a live feed, 121 of them, none reaching a
  household that had set a region. `DwdAreas` now maps the name to a
  district key, and `null` — "concerns everyone" — is the fallback,
  because for a civil-protection alert too many people is the safe error.
- **The six BBK sources are asked at once.** One after another meant six
  round trips to the same host before the warning list could be drawn —
  115 ms against 28 measured live. The number is small on a desk
  connection and is not the point: on mobile data at 200 ms a round trip
  that is a second and a quarter in front of the screen somebody opens
  first in an emergency. `BbkFetchResult.complete` still means every
  source answered.
- **The air quality index is the UBA's, class and thresholds alike.**
  `luftdaten.umweltbundesamt.de/api/air-data`, no key. The `airquality`
  endpoint returns an index of 0 to 4 per hour per station and each
  pollutant's own index beside it; the class boundaries come from
  `v4/thresholds` rather than being written down here, because they have
  already changed once — the UBA publishes both the classic index (`aq`)
  and its post-WHO-2021 revision (`aq4`) on the same endpoint, and only
  `aq` at scope 2 matches what `airquality` returns. **The UBA's
  behaviour advice is deliberately not shipped**: it is published only as
  images, and paraphrasing somebody else's health advice is exactly what
  the rule against invented scales exists to prevent. The screen names
  the class, names the pollutant the class came from, and points at the
  source. Two things the interface does that cost an hour to find: asking
  for every station at once answers 502, so it is asked per station; and
  the same request answers 404 now and then, which is why there is one
  retry.
- **The Autobahn service answers per road, so the roads are chosen.**
  `verkehr.autobahn.de/o/autobahn`, no key. Closures and warnings are
  fetched; roadworks are not — the same interface lists over a hundred
  per motorway, almost none of them blocking anything. Titles are mixed
  and there is no rule to lean on: of 25 closures on the A2, 16 began
  with "A2 | …" and the rest were free text out of a roadworks system, so
  the screen prefixes the road itself. `future` arrives as a real boolean
  and `isBlocked` as the string "true"/"false"; both are read for what
  they are. And an open road answers with an empty list, so failure is
  recorded as failure and never inferred from emptiness — "nothing is
  shut" and "could not ask" looking the same is the one way that screen
  could actively mislead somebody.
- **The DWD's fire-danger paths carry a dataset version.** `v2-3--0` is
  in every file name, so a bump there breaks every request at once while
  the code stays perfectly valid. It is a constant in
  `fire_danger_client.dart` and the live test is what notices.
- **Only the woodland index ships.** The grassland index (GLFI) sits
  beside it in the same directory and is not used: the DWD publishes the
  five-step wording for the WBI and not, where this was written, for the
  GLFI — and a five-step scale described in words somebody made up is
  what this app refuses to ship.
- **zstd clusters are streamed, never size-guessed.** The `zstandard`
  plugin's own `decompress` reads the final size out of the frame header
  and, where the header does not carry one, allocates twenty times the
  compressed length. No ZIM frame carries one: Kiwix writes clusters with
  streaming compression, measured across all eight archives here — zero
  declared sizes. So the guess is all there is, and it is often wrong:
  688 of iFixit's 718 clusters expand past twenty times, the worst 114
  times; Wikiversity 37, Wikibooks 7, Wikipedia none at 18.9 times.
  Beyond the guess the plugin returns null, `decompressCluster` throws,
  and the article view says "the archive answered with 500" — which is
  what "iFixit shows nothing after the start page" always was. The app
  therefore drives `ZSTD_decompressStream` itself
  (`zstd_stream.dart`), through the same native library the plugin
  loads, which needs no size in advance. The 64 MiB bound moves into
  that loop. `integration_test/native_archive_test.dart` holds both
  halves: a frame with no declared size that expands 6835 times, and —
  with `PREPPSUITE_TEST_ZIM` set — the real archive served over its own
  loopback server with every link off the start page fetched.
- **The macOS build has to be checked for zstd symbols, because nothing
  else notices.** `zstandard_macos` compiles zstd into its own framework
  from C sources it syncs into the pub cache. CocoaPods collects that file
  list at `pod install`; the plugin's own clean-up phase deletes the
  sources after a build; and the `prepare_command` meant to restore them
  never runs, because CocoaPods runs it only for pods it downloads and a
  Flutter plugin is always a local one. So the glob can find nothing, and
  the result is a valid, signed, launchable 228 KB framework holding the
  Swift registrar and no zstd at all. Every Kiwix archive then fails to
  open — a ZIM keeps even its `M/Title` in a compressed cluster, so
  `_open` throws and the app says "a ZIM archive is expected" — and
  **1.4.0 through 1.7.1 all shipped that way**, checked against the
  packages on Gitea. Two guards: `macos/Podfile` syncs the sources in a
  `pre_install` hook, before the file list is collected; and
  `tool/macos_sign.sh` refuses to finish unless the framework exports
  `ZSTD_decompress`, `ZSTD_compressBound` and `ZSTD_getFrameContentSize`.
  Linux and Windows ship zstd as a library of its own and were never
  affected. `integration_test/native_archive_test.dart` is what proves it
  from the Dart side; a plain `flutter test` cannot, because the plugin
  needs a real engine.
- **A dropped connection is resumed, not reported.** These downloads run
  for hours — 11 GB from a public mirror is an ordinary ask — and over
  that span a mirror closing the socket is a normal event. The banner
  used to show the mirror's own words ("Connection closed while receiving
  data, uri=https://ftp.nluug.nl/...") and stop, leaving the user to press
  download again; that did resume from the partial file, and then usually
  stopped somewhere else. `ArchiveDownloader.download` now loops around
  one attempt, each picking up from what is on disk, so no byte is
  fetched twice. The budget resets whenever an attempt brings bytes in: a
  transfer that is making progress may drop as often as the mirror likes,
  while one that cannot get a single byte through gives up after six
  tries. What is *not* retried is anything the server said on purpose —
  `DownloadException.retryable` is false for a status code, because
  asking a mirror six more times for something it has already answered
  404 to is rude and cannot help. Two traps found while writing it: an
  error out of a `yield*`-ed stream goes straight to the listener and
  never touches the `try` around it, so the loop has to `await for`; and
  the waiting itself has to be visible (`DownloadProgress.resuming`),
  because a progress bar that stops for a minute without a word reads as
  a hung app. Speed and remaining time are dropped while it waits rather
  than left standing — both would be measurements of a transfer that is
  not happening.
- **A download outlives the screen that started it, so its take-up must
  not hold that screen's `ref`.** An archive is tens of gigabytes and takes
  hours; the progress banner exists precisely so the user can go
  elsewhere meanwhile. `ArchiveDownloadController.start` therefore hands
  its callback the notifier's own `Ref`. Closing over the library
  screen's `WidgetRef` instead threw the moment the file arrived —
  reading a provider through a disposed widget's ref is an error — and
  because the throw happened inside the stream's `onDone`, nothing caught
  it: the banner announced a finished download and the archive was never
  added. That is how a download folder came to hold nine archives and the
  library none. The map never had the bug because its take-up already ran
  from the download provider's own ref.
- **`_takeUp` turns any failure into a state that says so.** Silence
  there is worse than an error message, because the banner's other
  wording claims the opposite. Same rule as everywhere else here: where
  something can fail out of sight, the screen says what happened.
- **A library entry carries what the archive says about itself.**
  `StoredArchive` keeps the title, the one-line description and the 48x48
  cover out of the ZIM's own `M/` namespace, written when the archive is
  opened alongside its size and entry count. Read on demand instead, a
  library screen would mean opening every archive and decompressing a
  cluster per tile — and only one archive is ever open at a time. An entry
  from before 1.6.0 has none of the three until the next time it is
  opened, which is why every reader falls back to the file name.
- **`response.body` decodes as Latin-1 unless the header names a
  charset.** `KiwixCatalogue._get` carried a comment saying to use
  `bodyBytes` for years while the code below it used `body`, and
  "français" came through as "franÃ§ais". The live server does send
  `charset=utf-8`, so nothing showed it; a mirror that does not would
  mangle every non-ASCII title in the library. Same trap as PEGELONLINE.
- **The offline "what is nearby" search reads the map archive, not a
  service.** `OfflinePoiSearch` opens the same PMTiles file the map draws
  from, decodes the OpenMapTiles `poi` layer at zoom 14 and measures every
  point against a centre. It is the only search in this app that still
  answers when the network is gone, which is the same moment the shelter
  map, the warnings and the gauges all stop. Four things it turns on:
  **the layer exists only from zoom 14** — below it there is no `poi`
  layer at all, so an area downloaded at zoom 12 draws a fine map and
  holds not one pharmacy, and the screen says that rather than reporting
  an empty result; **the filter keys on `subclass`, never on `class`** —
  measured over 21 real tiles, `class=fuel` held 569 points of which 525
  were charging stations and 44 were filling stations, and in a scenario
  that starts with the power being off, merging those would be the most
  misleading answer the screen could give; **a point outside the tile's
  own square is dropped**, because the schema buffers each tile and the
  neighbour that owns the point writes it too; and **tiles are read
  nearest first and the result is a stream**, so the closest pharmacy is
  on screen long before the far edge of the radius has been touched.
  Reading is capped at 225 tiles — at German latitudes a zoom-14 tile is
  about 1.5 km across, so ten kilometres is already 196 of them. Each
  tile is decoded in `Isolate.run`: a city tile carries three and a half
  thousand features. `shelter` is deliberately **not** offered: 695 of
  them in the sample, 10 with a name — in OpenStreetMap it is a bus
  shelter, not a Schutzraum.
- **The almanac is arithmetic, not a feed.** `features/daylight/`
  computes sunrise, twilight, solar noon, moonrise, moonset and the
  moon's lit fraction on the device: the NOAA solar-position algorithm
  for the sun, the Astronomical Almanac's low-precision series for the
  moon. Nothing is fetched, so nothing can go stale — it is as right on
  the tenth day without a network as on the first, which is the whole
  reason it is here. It is checked against the **US Naval Observatory's**
  own tables (`aa.usno.navy.mil/api/rstt/oneday`) in
  `test/live/daylight_live_test.dart`: over 112 compared times across four
  places and four seasons, sun and moon are at most **one minute** out.
  The app never calls that service; the test exists so that an almanac
  shipped as fact can be shown to be one. Three traps, each found by
  being a minute or two wrong against the tables: **the moon's rise
  threshold is compared against the *geocentric* altitude** — Meeus's
  `0.7275 * parallax - 34'` already contains the parallax, so subtracting
  it as well put every moonrise six or seven minutes late; **a
  local-flavoured `DateTime` must never reach `toUtc()`** in this code,
  because the machine's own zone would then be applied on top of the one
  already added by hand, which put every moonrise two hours out; and
  **the conversion back to the wall clock is Dart's `toLocal` by
  default**, not a fixed offset taken at midnight, or every event on the
  morning the clocks change would be an hour out. An event that does not
  happen is `null` and said in words — "the sun does not set today" —
  never printed as `--:--`, which reads as a broken app rather than as a
  midnight sun.
- **The licence-free bands carry the allocation they come from.** The
  Notfunk screen now covers PMR446 and Freenet beside CB and amateur
  radio — the two bands a household is most likely to already own, and
  the only ones here needing neither a licence nor an examination. Both
  were re-regulated in 2025 and the two now live in *different*
  documents: Freenet in **Vfg. 45/2025** (corrected by Mitt. 193/2025,
  in force 1 October 2025, 1 W ERP, 0.5 W within 10 km of the Belgian and
  Polish borders, handhelds only, no coaxial antenna, no repeater or
  gateway, no transmission past 180 seconds), PMR446 in the SRD
  collective allocation **Vfg. 91/2025**, band 83 (500 mW ERP, built-in
  antennas only, peer-to-peer), which replaced Vfg. 46/2020. Every card
  names its Verfügung underneath, which is what lets a reader check a
  figure and see when it has been superseded. And the screen states that
  **no calling or emergency channel is laid down by the regulator** for
  either band: the "Kanal 3" convention is named as the private
  initiative it is, alongside the places that use channel 1 instead —
  the same rule as the DWD's Graslandfeuerindex, that where an authority
  publishes no scale this app does not invent one.
- **The energy range estimates nothing.** `features/energy/` is the
  supply calculator's other half: that one answers how long the food and
  water last, this one how long the cooking, the light and the radio do.
  It keeps the same rule about figures, and keeps it harder — **every
  number on that screen was typed in by the household**, off the stove
  ("160 g/h") and off the cartridge ("230 g"). The app supplies the
  division, the units and one question nobody asks themselves: which of
  the reserves runs out first, which is the household's actual range and
  is never the number anyone reads off the list. Three decisions worth
  keeping: the five kinds are counted in the unit their own labels use
  (gas in grams, not kilograms, because that is how a stove states its
  consumption — so no constant from anywhere is needed to divide), days
  are rounded **down** (a reserve lasting three days and twenty hours
  lasts three days), and "stored but nothing uses it" is a state of its
  own rather than an infinite range. The one conversion offered is
  mAh -> Wh for a power bank, with the caveat that it is the cell's
  rating and not what leaves the socket — and deliberately **without** an
  efficiency percentage, which would be exactly the invented figure the
  rest of the feature avoids.
- **A carried copy keeps its data beside the program.** A folder named
  `PreppSuite-Daten` next to the executable turns it on; nothing is
  created on its own, so an installed copy behaves exactly as before.
  See `core/portable_location.dart` and
  [docs/mitgefuehrte-fassung.md](docs/mitgefuehrte-fassung.md). Four
  things this turns on: **the settings store is ours**
  (`portable_preferences.dart`, a JSON file) rather than the platform's,
  because on macOS the platform's is `NSUserDefaults` — not a file in a
  directory and not pointable anywhere, so one implementation that
  behaves the same on all three desktops beats three that nearly do;
  **macOS cannot find the folder by itself** and is pointed at one
  instead, because the sandbox is deliberately on (it is what stops the
  system asking for folder access after every update) and a sandboxed app
  may not read a directory beside its own bundle — the same
  security-scoped bookmark machinery the shared folder uses; **paths
  inside the data folder are stored relative** with the `daten:` prefix
  and forward slashes (`portable_paths.dart`), because an absolute path
  is a claim about one machine and the stick is `E:` today and
  `/Volumes/PREPP` tomorrow — without this it is a portable program with
  a broken library, which is worse than none; and **taking over an
  installed copy's data copies, never moves**, because that installation
  is still somebody's. The pointer to a chosen folder lives in a file in
  the platform's own Application Support and deliberately **not** in the
  preferences — the preferences are one of the things that move, so the
  way there cannot be kept inside them.
- **An article is readable without a browser engine.** Where the system
  has one it is used — a panel on macOS, iOS and Android, a window on
  Linux and Windows. Where it has not, `article_document.dart` parses the
  page into blocks and spans and `article_reader_screen.dart` draws them
  as ordinary widgets. That case is not exotic: WebKitGTK is not
  installed on a KDE desktop by default and the WebView2 runtime is not
  on every Windows 10, and neither can be fetched on a machine with no
  network — which is the situation this app is for. Parsing is the Dart
  team's `html` package (real markup is full of unclosed tags); the
  drawing is ours. **Bundling the engine was measured and rejected**:
  WebKitGTK finds its helper processes at a path compiled into the
  library, a release build carries no `WEBKIT_EXEC_PATH`, and it works
  the path out from neither `dladdr` nor `/proc/self/*` — a copied
  library finds nothing, quite apart from the ~170 MB and the two extra
  binaries it needs. Chromium through CEF is a 300 MB download against an
  app of 31 MB. Two traps met while writing it: text before a nested list
  inside an `li` has to be closed *as that list entry* or it falls out as
  a paragraph and the article loses its outline; and `SelectableText.rich`
  swallows the taps that follow links, so it is `SelectionArea` around
  `Text.rich` instead — which also gives selection across blocks rather
  than within one. On Linux and Windows the two are **offered as a
  choice** (`article_viewer_choice.dart`, settings card), defaulting to
  the window because it shows more of the article; the fallback still
  holds whichever is chosen, so the choice only decides what is tried
  first. The card appears on no other platform — there the embedded panel
  is both the best option and the only one.
- Comments in code are English; `docs/` prose is German.

### Moving a household

Three roads, one payload. `DeviceSnapshot` is what travels in every case,
and `sharing/application/snapshot_exchange.dart` is the only place that
reads one out of the database or merges one in. Adding a fourth road means
calling those two functions, never writing a second merge: two sets of
tie-break rules is how two devices come to disagree about what is in the
cellar, quietly.

  * the shared folder (`shared_folder_sync_service.dart`) -- the one that
    runs by itself;
  * the local handover (`transfer/application/local_handover.dart`) -- an
    HTTP socket on the local network, bootstrapped by a QR code that
    carries the address and a one-shot key. The key is the whole security
    model: whoever can see the screen gets in, nobody else. The body is
    encrypted with `folder_crypto.dart` anyway, because "local network" on
    a phone often means a café;
  * the QR chain (`transfer/application/qr_chain.dart`) -- frames shown in
    a loop and filmed. No back channel at all, which is why it loops.

The chain is deliberately **not** encrypted, and that is only defensible
because a picture on a screen can only be filmed by somebody present. The
same payload over radio, network or a file must be encrypted -- the
snapshot carries the emergency cards.

**Two things travel beside the snapshot.** What both roads that reach a
second device now send is a *superset* of the snapshot JSON, not a wrapper
around it (`transfer/application/handover_payload.dart`): an older install
decodes it with `DeviceSnapshot.decode`, never sees the extra keys, and
the transfer works. A wrapper would have made the first handover between
an old and a new install fail as "different household", which is both
wrong and frightening. What rides along:

  * **the household's own setup** -- the profile, plus the allow-list in
    `sharing/application/carried_settings.dart`. Three kinds of setting
    are deliberately *not* on it: what identifies the device
    (`syncDeviceId`), anything naming a local file (the shared folder, the
    map archive, the knowledge archives) and anything secret (the MapTiler
    key lives in the platform keychain and must not be moved into a plain
    preferences file). The warning-region keys are off the list too, for a
    different reason: they are a copy of the profile kept where the
    background isolate can read it, so carrying them would carry the
    shadow. **Applied only by a device being set up** -- on one that has
    been in use, the same copy would silently replace its own region,
    energy plan and reminders. Carried by **both** the handover and the QR
    chain: a couple of kilobytes is a few more frames to film, and it
    spares somebody typing the whole energy plan again. The shared folder
    does not carry it -- every device writes there, so it would need a
    rule for whose settings win, and there is none;
  * **the photographs** (`transfer/application/handover_photos.dart`),
    on the **handover alone**. They are in no snapshot because what the
    row stores is a path into one machine's own folder, and the other two
    roads cannot carry the bytes: the QR chain would need some two hundred
    extra frames per picture, and the
    shared folder republishes a whole snapshot per device per sync, so the
    same bytes would be re-uploaded forever. The receiving side sends the
    names it already holds, so a second handover carries nothing twice,
    and a row that already has a working picture keeps it. The incoming
    file name is **not** trusted: it goes into a path, so it is rejected
    unless it is a bare file name.

Writing a received photo onto a row uses `setInventoryPhotoPath` /
`setPossessionPhotoPath` and deliberately **not** an upsert: the path is
local, so touching `updatedAt` or `dirty` would push the row straight back
out carrying a path that means nothing on the other device.

Two things about drawing the codes, both learned the hard way in
`qr_code_view.dart`: the four-module quiet zone is not decoration (without
it many readers cannot find the code at all), and anti-aliasing has to be
switched off. Measured on a 600-character frame, the default paint left
37% of the painted pixels neither dark nor light, and a grey module is not
a value a decoder can read -- a code that looks perfectly fine and does
not scan.

### Nutrition is per 100 g, and nothing converts on the way in

`inventory_items.calories` and the four macronutrient columns hold what a
label prints: per 100 g, or per 100 ml on a drink. `calculateSupply`
multiplies against the stock reduced to grams or millilitres by
`food_amount.dart`, and that multiplication is the only conversion in the
feature.

**The column has meant three things, and the first two failed the same
way.** It began as a total for the stock, which nothing could maintain:
`consumeQuantity` lowers the quantity and cannot rescale a figure whose
basis it does not know. It then became a figure per stored unit, which
survived that but moved the conversion to scan time -- where it had to
guess a package size out of free text. Both bugs after it came from that
guess: a stockpiling-table row handed over as a per-unit figure was out by
a factor of 710, and the integer column the guess was rounded into made
"Kalorien je g" a field that accepted no usable number.

Per 100 has no conversion on the way in, so there is nothing to get wrong
on the way in. `package_energy.dart` -- the package-size parser, the
multipack rule, `kcalPerStoredUnit` -- is **gone**, 180 lines of it, and
`open_food_facts_service.dart` now copies five numbers across.

**Food and water are the only categories held to a measurable unit.** A
per-100 figure only becomes a total if the stock can be said in grams, and
"6 Dosen" cannot until somebody reads the tin. Everything else keeps free
text on purpose: a medicine is counted in tablets and its daily dose with
it, and `medication_range.dart` divides one by the other. Forcing grams
there would destroy a working calculation to tidy up a field.

Rows already counted in tins are **kept and named**, never converted --
`foodWithoutMeasure`, shown beside `foodWithoutCalories` on the crisis
hub. There is no honest factor for a tin, and guessing one would turn a
gap somebody can see into a wrong number nobody can.

**Mass and volume never mix.** A hundred millilitres of oil is not a
hundred grams of it, and Open Food Facts states per 100 g for solids and
per 100 ml for liquids. `FoodAmount` carries which base it is in so a
caller cannot lose track.

### "Not reachable" must mean the network, and nothing else

`joinLocalHandover` tries each address the invitation names and steps over
the ones that do not answer, which is right: a machine can have several
and only one of them reaches. What it used to do as well was step over
every *other* failure the same way — so an exchange that timed out looked
exactly like an address that was dead, the loop ran out, and the person
was told "Das andere Geraet ist nicht erreichbar. Haengen beide im selben
Netz?" while standing next to their own router.

It became reachable once the photographs started travelling. The request
carries the whole household in one body, the ceiling for that was raised
from eight to thirty-two megabytes, and **the eight-second timeout was
left where it was** — which is roughly what the upload alone costs. So the
connection succeeded, the exchange ran out of time, and the app blamed the
wifi.

Two timeouts now, and they answer different questions. `connectTimeout`
decides whether an address answers at all and stays short. The exchange
gets `exchangeTimeoutFor`, which is a floor for the far side's own work
plus an allowance at a deliberately pessimistic half a megabyte a second.
And past the moment an address answers, a failure is no longer allowed to
fall through to the next address: it is `LocalHandoverFailure.interrupted`,
which says the connection was made and to try again, rather than sending
somebody to look at the one thing that was demonstrably fine.

### base64 runs twice on the way out, and the ceiling has to know it

`localHandoverMaxRequestBytes` was a flat 32 MB, with a comment allowing
for base64 adding "a third". base64 runs **twice**: once to put each
picture's bytes into the JSON, and again on the ciphertext of the whole
sealed body. Sixteen ninths, not four thirds -- so the 20 MB photo budget
arrives as **35.6 MB** against a 32 MB ceiling, measured.

What that looked like from the outside was not a size error. The host threw
`_HandoverTooLarge` mid-stream, answered 413 while the guest was still
uploading, and the connection broke under the answer -- so the guest never
saw the status. It saw a broken pipe, reported a handover that started and
did not finish, and sent a household off to check its wifi.

Two things follow, and both are in the code now. The ceiling is **derived**
from `handoverPhotoBudgetBytes` rather than picked, so the two cannot drift
apart again. And `_readRequest` reads an oversized body **to the end**,
dropping the buffer rather than the reading: nothing is held past the
ceiling, so it costs the time to receive and no memory, and the 413
actually reaches the guest.

An address that answers and then fails still lets the remaining addresses
have their turn -- a machine can have a VPN interface that accepts a
connection and leads nowhere -- but the final failure is `interrupted`
rather than `unreachable`, because something was demonstrably there.

### A QR chain is filmed, not scanned, and both ends have to allow for it

Two settings decide whether a run of frames can be read at all, and both
had drifted from what the comments beside them claimed.

**The frame size is for the whole frame.** `qrChainFrameSize` was 700 with
a comment saying that landed "around version 20". It did not: the
`PS1:<crc>:<index>:<total>:` header is another seventeen to twenty-three
characters, so a frame came to 717 and the encoder went to version 22 --
105 modules, about 3.4 logical pixels each on an ordinary phone. The size
is now derived from version 20's capacity minus the header, and
`qr_chain_test.dart` holds every full frame to that rather than trusting
the prose.

**A count on its own cannot say why a run is stuck.** Sitting at "1 von
18" has two very different causes: the camera reading the same picture
over and over, or every picture arriving under a different checksum and
clearing what came before. `QrChainReceiver` therefore reports `lastSeen`
and `discarded` beside the count, and the screen shows them -- the first
stands still in one case and moves in the other. The redraw is keyed to
those moving rather than to each detection, so a camera reading thirty
times a second does not rebuild the screen thirty times a second.

**The camera is watching a sequence, not a till.** `MobileScanner`'s
default is `DetectionSpeed.normal`, which ignores everything for 250 ms
after a read. That is right where the same barcode sits in front of the
lens and the saving is memory on an old phone. Here the thing being filmed
is a *run* of different codes, each up for about half a second, and every
one has to be caught -- so the throttle leaves roughly two chances per
frame instead of the fifteen the camera offers. The receive screen passes
its own controller with `DetectionSpeed.unrestricted`; the screen lives for
seconds and holds one small collector, so the memory the default protects
is not at stake.

### A value migration cannot simply be replayed

Every migration before schema 16 changed a shape, and a shape can be asked
about: `_addColumnOnce` reads `PRAGMA table_info` and steps over a column
that is already there. Schema 16 changes *values*, and nothing in
`calories = 213` says whether it was `2.13` a moment ago.

That matters because drift writes the new version as a **separate**
statement after `onUpgrade` returns. A process that dies in between leaves
the schema changed and the version where it was, and the next launch
replays the steps -- the exact state the real household database reached
between 1.7.4 and 1.8.0. Adding a column twice throws, which is at least
loud. Multiplying a figure by a hundred twice is silent and wrong.

So a value migration writes its name into `migration_marks` and a replay
reads it. `onCreate` writes every mark up front, because a database born
at today's schema already has today's meanings -- without that, a fresh
install is precisely the one a replayed upgrade would corrupt.
`migration_rerun_test.dart` is what caught both halves.

### The knowledge check must not know anything the guides do not

`first_aid/application/knowledge_check_*.dart` asks back about first aid,
because reading a guide again is not how anybody finds out what they have
forgotten. Every question names the guide it is answerable from, and its
explanation is **one caution or one step of that guide, word for word** --
not a paraphrase and not an addition. A test holds every question in both
languages to that, and it earns its keep: it caught four German and
sixteen English explanations where a sentence of reasoning had crept in
that no guide contains. The moment an explanation may say "because...",
the quiz has started giving medical advice of its own, arrived at by
whoever wrote the question.

The result is stored per device and deliberately **not** in the
household's carried settings, unlike the drill progress beside it.
Practising an evacuation is something a household does together; knowing
that a tourniquet stays on is something a person knows or does not.

### Wide windows

**A block is all-or-nothing, and that is a trap on a phone.** With one
column `AdaptiveColumns` is a plain `ListView`, which builds only what is
on screen -- but only per *block*. A room holding two hundred
photographed things was one block, so the first room to reach into the
viewport was built whole: measured at 400 by 800 with six tiles visible,
a household of 300 things in three rooms built **100 tiles and decoded
10.5 MB**, growing with the size of the room and with no limit. Anything
that is a heading plus an unbounded list of user data is an
`AdaptiveSection`, which stays one block while there are columns to be
separated by and is taken apart when there is only one (measured after:
11 pictures, 1.2 MB). The other screens with a loop inside a block --
energy, medication range, the first-aid guides -- were checked and build
cheap text rows, so they stay as they are.

Screens that are a list of sections lay themselves out with
`core/adaptive_columns.dart` rather than a plain `ListView`. It cuts the
page into columns of readable width and lets the window decide how many;
below about 1140 px it *is* a plain `ListView`, so phones are unchanged and
nothing lazy is given up there.

Pass `blocks`, not children: a block is whatever must stay together, a
heading with its list. Blocks are dealt into the lanes in order, so a
heading can never land in one column with its list in the next. Spacing
between blocks comes from the layout, not from `SizedBox`es in the caller.

Two things it is deliberately not: it is not a way to centre a narrow
column in a wide window (the space is used, not abandoned), and it is not
for long or unbounded lists -- it builds every block. The warning list is
the one exception and says why in place: that list is what the subscribed
regions currently have out, tens of entries at worst. The inventory is not
converted for exactly this reason.

### Ein Arzt ist Teil einer Karte, kein eigener Datensatz

Auf einer Notfallkarte stehen mehrere Ärzte und mehrere Personen, die man
wegen dieser Person anruft. Beides sind Listen, und beides liegt weiterhin
in genau der Textspalte, in der vorher eine einzelne Zeile lag -- eine
Zeile je Eintrag, geschrieben wie man es sagen würde:

    Dr. Mira Sandoval (Hausärztin) · 0531 123456
    Anna Weber (Partnerin) · 0170 9876543

Keine zweite Tabelle, weil ein Arzt keine eigene Lebensdauer hat: Die Karte
ist das, was synchronisiert, gelöscht und gedruckt wird. Eigene Zeilen
müssten beim Löschen der Karte mitgelöscht, beim Zusammenführen mitgeführt
und durch Ordner, Übergabe und QR-Kette mitgeschleppt werden -- Maschinerie
für etwas, das ohne die Karte nicht existiert.

Und kein JSON, weil das Format auch dort lesbar bleiben muss, wo es niemand
auswertet: Ein Gerät auf einer älteren Fassung zeigt die Spalte roh an und
zeigt damit genau obige Zeilen. Deshalb braucht es auch keine
Wertmigration -- was vorher als freier Text dastand ("Dr. Müller, Praxis am
Markt"), liest sich als ein Eintrag mit Namen und schreibt sich unverändert
zurück. Siehe `features/household/application/card_people.dart`.

### Checklisten haben zwei Achsen, nicht eine

Eine Liste hat eine Kategorie (Wasser, Energie, Naturgefahren) *und* eine
Art: Vorsorge oder Im Ereignis. Die eine lässt sich nicht aus der anderen
ablesen -- "Strom- und Heizungsausfall" und "Wenn der Strom ausfällt" sind
beide `energy`, und die eine sagt, was zu kaufen ist, die andere, was zu
tun ist, während es dunkel ist.

Die Zuordnung der eingebauten Listen steht in `built_in_templates.dart` und
nirgends sonst. Sie erreicht bestehende Haushalte über den **Seeder**, nicht
über die Migration: Der Seeder überspringt eine Vorlage, die er schon
findet, läuft aber bei jedem Start -- also schreibt er bei jedem Start die
Art auf die eingebauten Zeilen. Das ist die einzige Stelle im Projekt, an
der sich eine Aussage über eingebaute Inhalte nachträglich korrigieren
lässt; die Migration läuft einmal, der Seeder immer.

Dieser Schreibvorgang ist bewusst **keine Änderung**: `updatedAt` und
`dirty` bleiben, wie sie sind. Sonst würde ein Gerät, das gestern die Hälfte
abgehakt hat, beim nächsten Abgleich von einem frisch gestarteten Gerät
überschrieben. Er muss auch nicht reisen -- jedes Gerät kommt aus derselben
Deklaration zur selben Antwort.

### Eine halb gezeichnete Karte hat zwei sehr verschiedene Ursachen

Ein Kartenausschnitt, der nur teilweise erscheint, heißt entweder "dieser
Bereich wurde nie heruntergeladen" oder "der Kachelserver hat nicht
geantwortet". Auf dem Bildschirm sehen beide gleich aus, und in beiden
Fällen weiß die App, welcher Fall vorliegt:

* `offline_map_coverage.dart` fragt das Archiv, wie viele Kacheln des
  gezeigten Ausschnitts es überhaupt hat. Ein Auszug endet an seinem Rand;
  darüber hinauszuschauen ist das Normale und nichts, worauf man warten
  könnte.
* `BaseMapLayer` meldet fehlgeschlagene Netzkacheln an
  `onlineTileFailures`. Das kann sich von selbst erledigen.

`MapCoverageNotice` sagt es und bietet jeweils die andere Quelle an. Ohne
das wird aus "die Karte lädt nicht" ein Abend am falschen Ende des Hauses:
Die Offlinekarte wurde immer schon verwendet, wenn eine da war -- nur stand
das nirgends.


### Bewegung gibt es nur an den Nahtstellen

Bis 1.9.8 stand in der App keine einzige Animation -- sechzehn Arten
gesucht, null gefunden. Jeder Ladezustand sprang in einem Bild vom Kreisel
auf die fertige Seite, und ein harter Schnitt liest sich wie ein Fehler,
nicht wie ein Abschluss.

Es gibt genau ein Widget dafür, `core/content_swap.dart`, und es sitzt an
den `AsyncValue`-Nahtstellen: Kreisel wird Liste, Liste wird leerer
Zustand. Es wechselt nur, wenn sich die *Art* des Inhalts ändert, weil
`AnimatedSwitcher` Widgets so vergleicht, wie das Framework es tut. Eine
Liste, die eine Zeile dazubekommt, ist dieselbe Art Sache und bleibt
unangetastet -- sonst würde bei jedem Datenbank-Tick die Scrollposition
gegen eine Überblendung kämpfen.

Zwei Regeln für alles, was dazukommt: Es respektiert
`MediaQuery.disableAnimationsOf` -- wer sein Gerät gebeten hat, nichts zu
bewegen, bekommt die frühere Bild-zu-Bild-Änderung, nicht eine kürzere
Fassung dieser. Und es bleibt unter 250 ms; darüber liest sich eine
Überblendung als langsame App, was das Gegenteil des Zwecks ist.

### Was eine Liste je Zeile kostet

Die Checklistenansicht hat lange je Kachel einen eigenen Strom ihrer
eigenen Punkte geöffnet *und* aus dem kompletten Inventar eine Map neu
gebaut, um darin nachzuschlagen. Bei neunzehn eingebauten Listen sind das
neunzehn Datenbank-Abonnements für einen Bildschirm und neunzehn Kopien
derselben Inventar-Map, die bei jedem Tick weggeworfen werden. Die Map ist
die teure Hälfte, weil sie so groß ist wie die ganze Vorratskammer und
nicht wie die Liste, die gerade gezeichnet wird.

`checklistProgressByTemplate` rechnet es einmal für den ganzen Bildschirm
aus, und die Kachel bekommt ihre Zahlen gereicht. Die Regel dahinter:
**ein `ref.watch` in einem Listenelement ist ein `ref.watch` mal Anzahl der
Zeilen.** `allChecklistItemsProvider` existierte bereits genau dafür und
wird von drei anderen Bildschirmen benutzt.

### `async` verschiebt nichts

`HandoverPayload.seal` und `.unseal` laufen auf einem Isolate, und das ist
kein Feinschliff. Zwanzig Megabyte Fotos werden zu siebenundzwanzig
base64 in einem fünfunddreißig Megabyte großen JSON-String; AES-GCM ist
hier reines Dart und bewegt zehner- statt hunderter-Megabyte je Sekunde.
Zusammen sind das Sekunden, in denen nichts auf dem Bildschirm reagiert --
und ein `await` auf Arbeit, die nie nachgibt, ist genau derselbe
Stillstand mit einem Schlüsselwort davor.

Das Isolate bekommt die Nutzlast kopiert, was einen Durchgang über die
Bytes kostet gegen die mehreren, die das Kodieren ohnehin macht. Es ist
auch das, was den Fortschrittsbalken weiterdrehen lässt: Eine Übergabe,
die hängen zu bleiben scheint, ist eine, die jemand auf halbem Weg
abbricht.

Beide Richtungen halten ihre zwei Fehlerfälle auseinander: Was sich nicht
öffnen lässt, gehört jemandem im Netz, der den Bildschirm nie gesehen hat
(403); was sich öffnet und etwas anderes enthält, gehört zu einem anderen
Haushalt (409).


### Eine Liste sagt, was die App kann

`core/app_destinations.dart` ist die einzige Stelle, die den Funktionsumfang
als **Daten** führt statt als Widgets in Widgets. Sie entstand für die Suche,
denn zweiundsechzig Bildschirme hinter zehn Reitern werden nicht mehr
navigiert, sondern gesucht -- und eine Suche braucht etwas zum Durchsehen.
Wer die Blackout-Uhr sucht, muss sonst wissen, dass sie unter Notfall liegt
und nicht unter Energie.

Die Hub-Bildschirme zeichnen weiter ihre eigenen Kacheln. Beide lesen
dieselben `l10n`-Getter, ein umbenannter Bildschirm heißt also in beiden
sofort anders. Auseinanderlaufen kann nur die *Menge*: ein Bildschirm, der
einem Hub hinzugefügt und hier vergessen wird, ist ein Bildschirm, den die
Suche nicht findet -- und das merkt niemand beim Benutzen, sondern nur beim
vergeblichen Suchen.

Deshalb liest `app_destinations_test.dart` den Quellbaum: Jeder
`*_screen.dart` muss entweder im Register stehen oder namentlich mit Grund
ausgenommen sein. Ausgenommen sind die, die ohne einen vorhandenen Datensatz
nicht existieren -- ein Formular braucht die Zeile, die es bearbeitet, ein
Artikel ein geöffnetes Archiv, der Foto-Editor ein Foto. Der Test prüft auch
die Gegenrichtung: Eine Ausnahme für einen gelöschten Bildschirm würde still
den nächsten decken, der denselben Namen bekommt.

**Die Notfallkarten sind absichtlich nicht durchsuchbar.** Es sind
Gesundheitsdaten, und eine allgemeine Trefferliste, die eine Diagnose zwei
Zeilen unter eine Dose Bohnen setzt, ist der falsche Ort dafür -- auch vor
demjenigen, der das Telefon gerade in der Hand hält. Sie haben ihren eigenen
Bildschirm, der sagt, was sie sind, bevor etwas hineingeschrieben wird.

**Die Suche rät nicht.** Kein Scoring, kein Fuzzy-Abstand: Wer "Pegel" tippt,
will den Pegel, und eine Liste, die drei Beinahetreffer darüber setzt, hat
eine Frage beantwortet, die niemand gestellt hat. Was sie sehr wohl tut, ist
falten, wie Deutsch tatsächlich getippt wird -- "Notgepack" findet
"Notgepäck" und umgekehrt, samt der kombinierenden Akzente, die eine
Mac-Tastatur erzeugt.


### Haptik ist eine Aussage, keine Vibration

`core/feel.dart` ist die einzige Stelle, die `HapticFeedback` überhaupt
aufruft. Aufrufer sagen, *was passiert ist* -- `Feel.removed()`,
`Feel.failed()` -- und diese Datei entscheidet, wie sich das anfühlt.
Verstreute Aufrufe sind der Weg, auf dem dieselbe Art Ereignis an zwei
Stellen unterschiedlich brummt und am Ende alles brummt.

Sie meldet sich nur in vier Fällen, alles andere bleibt still:

* die Augen sind woanders -- Kamera auf einem Strichcode, ein Telefon
  gegen ein zweites gehalten;
* die Hände sind voll und die Liste ist lang -- ein Notgepäck abhaken,
  während man es packt;
* es lässt sich nicht zurücknehmen;
* es ist schiefgegangen, und das einzige Zeichen ist eine Meldung, die von
  selbst wieder verschwindet.

Ein Brummen, das nichts hinzufügt, bringt Leuten bei, Brummen nicht mehr
zu beachten. Das Löschen im Vorrat bekommt deshalb **keins**: dort steht
acht Sekunden lang ein Rückgängig.

Die Plattformabfrage steht einmal in `Feel` und nicht an den Aufrufstellen.
Genau so war sie vorher: im Taktgeber vorhanden, im Notsignal vergessen.
Ein Desktop hat nichts zu fühlen, und jeder Aufruf wäre trotzdem eine
Runde über den Plattformkanal.

### Ein Hinweis kostet die Höhe, die er einnimmt

Die Notiz „Nicht mitgerechnet: Einheit ohne Maß" steht als **Fußnote in der
Vorratskarte**, nicht als eigene Karte und nicht als erste Zeile der Liste.
Beides wurde probiert, und beides schob die Liste um die eigene Höhe nach
unten -- auf einem kurzen Bildschirm landeten damit die Knöpfe des ersten
Eintrags unter dem schwebenden Aktionsknopf. Das ist ein schlimmerer Fehler
als der, den die Notiz meldet, und `inventory_list_test.dart` hat ihn
gefunden.

Die Regel daraus: Ein Hinweis, der dauerhaft dasteht, gehört zu der Zahl,
die er einschränkt, und bekommt eine Zeile. Der Absatz liegt hinter einem
Tippen (`showUnitInfo`), denn dort hat jemand danach gefragt.

Der Dialog beantwortet die Frage, die wirklich gestellt wird: Wird mein
Vorrat jetzt umgeschrieben? Nein -- die Zeile bleibt, sie zählt nur so
lange nicht mit, bis die Einheit ein Maß nennt. Die Einheiten darin sind
zum Antippen, nicht zum Lesen: Das Feld steht direkt hinter dem Dialog.


### Eine Ortung, die nicht kommt, heißt nicht „kein Standort"

`getCurrentPosition` wartet auf eine **frische** Messung. In der Wohnung,
am Rechner oder mit kaltem Empfänger reichen die fünfzehn Sekunden oft
nicht — und das Gerät hält währenddessen eine völlig brauchbare Position
von vor drei Minuten in der Hand. Wer in dieser Lage „Standort konnte
nicht ermittelt werden" liest, geht eine Einstellung prüfen, die nie aus
war.

`GeolocationService._getPosition` fällt deshalb auf
`getLastKnownPosition` zurück. Zwei Dinge daran sind wichtig:

* Der Rückfall sitzt **nach** den Berechtigungsfragen, nie davor. „Ortung
  ist aus" und „für immer abgelehnt" werfen vorher, und eine alte Position
  darüberzulegen würde eine Frage beantworten, die der Haushalt nicht
  gestellt hat, und eine verdecken, auf die er reagieren muss.
  `geolocation_fallback_test.dart` prüft genau das mit.
* Eine alte Messung wird **als alt ausgewiesen**. `ReadablePosition`
  trägt `takenAt`, und der Bildschirm, auf dem Koordinaten vorgelesen
  werden, sagt ab zwei Minuten dazu, wie alt sie sind. Koordinaten über
  Funk sind eine Aussage darüber, wo jemand *jetzt* ist.

Das sitzt im Dienst und nicht in den Bildschirmen: fünf davon fragen nach
dem Standort, und fünf Rückfälle wären vier Gelegenheiten, einen zu
vergessen.

### Die dunkle Karte wird gedreht, nicht geschrieben

Der Renderer bringt genau einen Stil mit und der ist hell. In dunkler
Oberfläche war die Offlinekarte damit ein weißes Rechteck — das hellste
auf dem Bildschirm, ausgerechnet auf der Funktion, die man nachts im
Stromausfall aufschlägt.

`dark_map_style.dart` läuft durch die Stildaten und dreht **jede** Farbe
darin um: Farbton bleibt, Helligkeit kippt, Sättigung wird gedämpft. Ein
Park bleibt dadurch grün, statt bei einer reinen Bildumkehr magenta zu
werden. Gelaufen wird über jede Zeichenkette in der Struktur, nicht über
die bekannten Farbschlüssel: ein Mapbox-Stil versteckt Farben auch in
Ausdrücken und Stützstellen, und genau die wären beim schemakundigen Weg
durchgerutscht.

Weiß geht nicht auf reines Schwarz und Schwarz nicht auf reines Weiß
(`clamp(0.06, 0.90)`). An den Enden verschluckt es die Haarlinien
zwischen zwei Flächen, und die sind es, die eine Karte lesbar machen.

Zwei Dinge, die dabei in Kauf genommen sind:

* **Ein Implementierungs-Import.** `lightThemeData()` wird vom Paket nicht
  exportiert, nur das fertige helle `Theme`. Die Alternative wäre, sechzig
  Kilobyte Stil ins Repository zu kopieren, wo sie still gegen das Paket
  veralten; so ist eine Änderung ein Übersetzungsfehler.
* **Die Rasterkacheln werden nur gefiltert.** OpenStreetMap liefert ein
  Kachelbild, keinen Stil — da gibt es nichts zu drehen, also läuft
  `darkModeTileBuilder` darüber. Schlechter als der Vektorweg, und besser
  als das hellste Rechteck auf dunklem Grund.

`mapThemeProvider` ist eine Familie über die Helligkeit, damit jeder Stil
einmal gelesen und dann behalten wird. Sechzig Kilobyte durch den
`ThemeReader` bei jedem Themenwechsel wären ein Ruckler jedes Mal, wenn
die Sonne untergeht.


### Zwei Ampeln, und niemals eine

Oben auf der Übersicht stehen zwei Lampen: **Vorrat** und **Lage**. Jede
Karte darunter beantwortet eine Frage gut, und keine beantwortet die, mit
der jemand diesen Bildschirm aufschlägt — das hieß bisher vier Karten
lesen und selbst zusammenzählen.

**Sie werden nicht zu einer verrechnet.** „Vorrat reicht, aber Unwetter"
hat keine gemeinsame Farbe, und die Gewichtung, die eine ergäbe, wäre hier
erfunden. Genau das macht diese App mit Skalen nicht.

Beide Lampen nennen, wessen Zahl sie benutzen:

* **Vorrat** vergleicht gegen die Werte des BBK — zehn Tage, 2 l und
  2200 kcal je Person und Tag. Grün heißt erreicht, gelb heißt darunter,
  **grau heißt „zu wenig eingetragen, um etwas zu sagen"**. Grau und nicht
  rot: eine leere Datenbank ist kein leerer Keller, und Rot würde einem
  Haushalt Unvorbereitetsein vorwerfen, der nur noch nichts eingetippt
  hat. Was die Rechnung auslassen musste, steht auf der Lampe selbst —
  eine Zahl, die weniger abdeckt als der Schrank, muss das zugeben können.
* **Lage** zeigt die höchste amtliche Warnstufe, die gerade für eure
  Bereiche gilt, in der Leiter des Herausgebers. **Hier gibt es kein
  Grün.** Behörden veröffentlichen Warnungen, keine Entwarnungen; dass
  keine vorliegt, ist keine Aussage über Sicherheit und wird nicht als
  eine verkleidet. Gefiltert wird mit derselben Regel wie Banner und
  Benachrichtigung, sonst könnte die Lampe „ruhig" sagen, während das
  Banner eine zeigt.

Eine Skala, deren Herausgeber nicht mitliefert, wie sie zu lesen ist,
kommt weiterhin nicht in die App. Für Deutschland gibt es **keine
öffentliche Gefährdungs- oder Terrorwarnstufe** — nachgeschlagen am
22.09.2026, die Behörden warnen konkret über NINA, Katwarn und Sirenen und
veröffentlichen keine Zahl. Eine selbst gebaute „Kriegsgefahr: 3 von 5"
wäre genau die erfundene Skala, die hier nicht vorkommt, und auf einem
Bildschirm, den jemand in echter Sorge öffnet, besonders schädlich.

**Zum Layout:** die Reihe steckt in einem `IntrinsicHeight`. In einem
`ListView` hat eine Reihe, die sich streckt, nichts zum Strecken — das
ging beim ersten Mal als „BoxConstraints forces an infinite height"
hinaus und wurde von `optimization_layout_test` gefangen, nicht vom Test
neben dem Widget: der hatte einen begrenzten Kasten zum Sitzen. Der Test
rendert es jetzt in einer Liste.


### Einstellungen bleiben in Schritt, ohne dass ein Schreibort es merkt

`CarriedHousehold` brachte die Einstellungen **einmal** herüber, bei der
Einrichtung. Ein Pegel, der auf dem Telefon gewechselt wurde, erreichte
den Rechner nie. Der Grund dafür war gut: Einstellungen hatten keinen
Zeitstempel, und ohne den ist jede Zusammenführung auf einem benutzten
Gerät ein stiller Verlust.

Sie haben jetzt welche, und zwei Entscheidungen machen das billig:

**Gestempelt beim Veröffentlichen, nicht beim Schreiben.** Nichts fängt
`prefs.setString` ab. Stattdessen wird das, was hinausgeht, mit dem
verglichen, was beim letzten Mal hinausging; was sich unterscheidet,
bekommt diesen Moment. Kein Schreibort zu merken heißt kein Schreibort zu
vergessen — die Fehlerklasse, die dieses Projekt immer wieder findet. Der
Preis: eine Änderung ohne Netz trägt die Zeit der nächsten
Veröffentlichung statt der Änderung. Für „wer ist weiter" ist das
dieselbe Antwort.

**Ein Boden, damit niemand beim Start schreit.** Die erste
Veröffentlichung nach dieser Änderung würde sonst jeden Wert mit „jetzt"
stempeln, und zwei Geräte eine Minute auseinander ließen das spätere
alles überschreiben. Ungestempelte Werte starten deshalb bei
`settingsEpoch` — derselbe Kniff wie `ChecklistSeeder.seededAt`. Beide
Seiten stehen gleich, und die erste echte Änderung ist das Erste, was
gewinnt.

**Nicht alles reist.** `CarriedWhen` trennt, was dem Haushalt gehört, von
dem, wie *dieses Gerät* eingerichtet ist. Welchen Pegel der Haushalt
liest, gehört dem Haushalt. Ob dieser Bildschirm dunkel ist, ob dieses
Gerät benachrichtigt und ob es aus einem Archiv zeichnet, das es
vielleicht gar nicht hat, gehört ihm nicht — sonst würde der Rechner
dunkel, weil jemand im Zug das Telefon umgestellt hat. Die reisen weiter
**einmal**, bei der Einrichtung.

**Die Zeilen zuerst, die Einstellungen danach.** Eine Einstellung, die
sich nicht speichern lässt, darf die Zeilen nicht kosten: `readSynced-`
und `applySyncedSettings` geben im Fehlerfall leer beziehungsweise null
zurück, statt zu werfen. Genau diese Reihenfolge stand beim ersten Wurf
falsch herum, und acht Abgleich-Tests haben es gemeldet.

Getragen wird das im `DeviceSnapshot` — der Datei, die ohnehin alle zwei
Minuten neu veröffentlicht wird. Damit reist es über **alle vier** Wege
zugleich: gemeinsamer Ordner, Direktübergabe in beide Richtungen und
QR-Kette. `settings_sync_store_test.dart` liest den Quellbaum und meldet
jeden Weg, der Zeilen zusammenführt und die Einstellungen vergisst; die
Sicherung ist namentlich ausgenommen, denn ein Rückspielen ist eine Kopie
dieses Geräts aus seiner eigenen Vergangenheit und hat den anderen nicht
zu sagen, wer den Pegel zuletzt geändert hat.

### Bei den Videos steht die Zahl, nicht die Vermutung

Die App verweist auf kein fertiges Videopaket, weil es keines gibt — und
seit 1.9.9 sagt sie auch, **wo** man realistisch anfängt und wie dünn es
dort ist. Nachgesehen am 22.09.2026: `Category:Videos of first aid` auf
Wikimedia Commons existiert nicht, `Category:Videos of cardiopulmonary
resuscitation` enthält acht Dateien, überwiegend nicht auf Deutsch, eine
davon die Reanimation eines Hundes.

Das steht so auf dem Bildschirm und in `docs/erste-hilfe.md`. Eine
Quellenangabe ohne geprüfte Zahl wäre in dieser App dasselbe wie eine
erfundene Skala.


### Verschlüsselung im Ruhezustand: pro Datei, nicht pro Installation

`lib/core/local_database_encryption.dart` hält einen 256-Bit-Schlüssel im
plattformgebundenen sicheren Speicher und öffnet damit die Drift-Dateien.
Vier Dinge daran sind teuer erkauft und dürfen nicht zurückgedreht werden.

**`PRAGMA key` auf einer Klartextdatei macht sie unlesbar.** Nicht "ignoriert"
und nicht "verschlüsselt sie" — SQLite3MultipleCiphers versucht danach zu
entschlüsseln und scheitert mit *file is not a database*. Die erste Fassung
setzte vor dem `PRAGMA rekey` einen Schlüssel und konnte deshalb nie eine
einzige Datenbank umstellen. Der Weg ist: schlicht öffnen, nur `PRAGMA
cipher` wählen, `PRAGMA rekey` ausführen, danach mit dem Schlüssel neu
öffnen und lesen.

**Die Entscheidung fällt pro Datei, beim Öffnen.** `_configureCipherForFile`
liest den Dateikopf und legt den Schlüssel nur auf etwas an, das kein
lesbarer Klartext ist. Damit ist eine halb fertige Migration harmlos: die
umgestellten Dateien öffnen mit Schlüssel, die noch nicht erreichten ohne,
und eine Datei, die es noch nicht gibt, entsteht verschlüsselt. Ein Modus,
der für die ganze Installation gilt, hatte genau den gegenteiligen Effekt —
nach einem Abbruch war die Hälfte des Haushalts nicht mehr zu öffnen.

**Die Wiederherstellung sucht über die Namen, nicht über `.sqlite`.** Im
Moment zwischen den beiden `rename`-Aufrufen heißt die Datenbank weder wie
sie selbst noch irgendwie auf `.sqlite`. Eine Aufräumschleife über
`*.sqlite` besucht sie deshalb nie — der Haushalt blieb als
`.plaintext-recovery` liegen, und die App legte daneben einen leeren an.
`_databaseBaseFiles` faltet die beiden Migrationsendungen auf den
eigentlichen Namen zurück; `local_database_encryption_test.dart` stellt
jeden Abbruchpunkt nach.

**Die Migration läuft in einem eigenen Isolate und ist wiederaufnehmbar.**
`VACUUM INTO` kopiert die ganze Datei, und die Wissensindizes können
Gigabyte groß sein. Ein zweiter Lauf überspringt, was bereits
verschlüsselt ist, und benutzt **denselben** Schlüssel — ein neuer würde
verwaisen lassen, was der erste Lauf geschafft hat.

Ohne Schlüssel ist der Zustand `recoveryRequired`, und der hat seit 2.0.1
einen Bildschirm: `lib/core/local_data_gate.dart` steht vor der App-Sperre,
erklärt die Lage und bietet "Neu einrichten" an, das die unlesbaren Dateien
**umbenennt statt löscht**.


### Ein Hintergrundlauf, der nichts tun konnte, ist kein erledigter Lauf

`runWarningBackgroundPoll` meldete `true`, wenn der Geräteschlüssel nicht
zu bekommen war. Das ist die Antwort "fertig, nichts zu tun" — auf dem
einen Weg, über den diese App im Hintergrund überhaupt warnt. Ein Android,
das neu gestartet und noch nicht entsperrt wurde, hat keinen Keystore; das
Gerät hätte still aufgehört zu warnen.

Jetzt meldet der Lauf `false` und hinterlässt mit `recordBlocked()` die
einzige Spur, die er hinterlassen kann. Die Karte "Warnbereitschaft" in den
Einstellungen liest sie zurück — aber nur, solange kein späterer
vollständiger Abruf sie überholt hat.


### Private Einstellungen: was neben der Datenbank liegt

Die Datenbanken sind verschlüsselt, die Werte daneben waren es nicht — und
einige davon sind die interessantere Hälfte: wo jemand wohnt, wen er
anruft, der Schlüssel zu seinem gemeinsamen Ordner. `PrivatePreferences`
(`lib/core/private_preferences.dart`) legt sie als AES-GCM-Umschlag ab,
unter einem **abgeleiteten** Schlüssel: HKDF-SHA256 über den Datenschlüssel
mit eigener Beschriftung. Ein Schlüssel, der zwei Dinge öffnet, ist ein
Fehler davon entfernt, beide zu öffnen.

Drei Eigenschaften machen es unter bestehende Stores schiebbar, ohne einen
Migrationsschritt: Lesen nimmt beide Formen an, ein Klartextwert wird beim
Lesen verschlüsselt zurückgeschrieben, und ohne Schlüssel wird geschrieben
wie vorher. Die Migration ist der normale Gebrauch der App.

Verschlüsselt sind: Profil, Warnregionen, persönliche Orte, Krisenplan,
Dokumentliste und der Ordnerschlüssel. Absichtlich **nicht**: Sprache,
Farbschema, Benachrichtigungsschalter und die Zwischenspeicher öffentlicher
Daten — die App muss einen Bildschirm zeichnen können, bevor sie irgendetwas
geöffnet hat.

**Ein mitgeführter Ordner wird nie versiegelt.** Er geht zum nächsten
Rechner, der Schlüssel bleibt im Schlüsselbund dieses einen. Deshalb
verschlüsselt weder `PrivatePreferences` noch die Datenbankschicht, wenn
`portableLocation.isPortable` gilt, und die Einstellungskarte sagt warum.
Ein verschlüsselter Ordner, der ohne seinen Schlüssel ankommt, führt nicht
in einen SQLite-Fehler drei Bildschirme später, sondern in
`recoveryRequired`.

**Was zwischen Geräten reist, reist im Klartext im verschlüsselten Kanal.**
`carried_settings.dart` liest die beiden privaten Schlüssel
(`preparednessHubV1`, `personalMapPlaces.v1`) ebenfalls durch den Container,
sonst bekäme die Gegenseite den Umschlag dieses Geräts, den sie nie öffnen
kann.


### Sicherungsformat 2, und der Weg zurück

Die Sicherung trug Datenbankzeilen und den Krisenplan. Nicht dabei waren
Profil und die mitgeführten Einstellungen — ein wiederhergestellter Haushalt
kannte seinen ganzen Vorrat, aber nicht, für wie viele Personen er reichen
muss. Seit die Werte auf dem Gerät verschlüsselt liegen, ist die Sicherung
zusätzlich der einzige Weg, auf dem sie einen verlorenen Schlüsselbund
überleben. Format 2 legt sie in einen eigenen verschlüsselten Block;
Format 1 bleibt lesbar.

Der Plan wird dabei **nicht** aus diesem Block geschrieben, sondern weiter
von `_restorePlan`, das ihn *zusammenführt*. Beides zu tun hieße, die ältere
Fassung zurückzugeben — genau das, was die Zusammenführung verhindert. Ein
Test hält das fest.

`restoreAsNewHousehold` ist der Weg zurück nach einem verlorenen Schlüssel
und steht auf dem Einrichtungsbildschirm. `restore` besteht darauf, dass
Sicherung und Gerät vom selben Haushalt sprechen — richtig, solange es einen
zu schützen gibt, und eine Sackgasse nach „Neu einrichten": der eben
angelegte Haushalt trägt eine neue Kennung und würde seine eigene Sicherung
als fremde abweisen. Auf einem Gerät ohne Zeilen gibt es nichts zu
verlieren, also wird die Kennung aus der Datei übernommen.


### Ein unlesbarer Schlüsselspeicher heißt nicht „nichts eingerichtet"

Als der macOS-Start daran scheiterte, dass die App keinen Schlüsselbund
bekommt, wurde in drei Speicherklassen jeder Lesefehler verschluckt. Für
die App-Sperre war das eine Umgehung: `isEnabled()` ist
`read(...) == 'true'`, und aus „nicht lesbar" wurde damit „keine Sperre" —
also eine App, die sich öffnet. Am selben Tag war die Weiche davor
ausdrücklich auf Fail-Closed gestellt worden; der Fehler erreichte sie nur
nicht mehr.

Unterschieden wird jetzt mit einer Markierung in den gewöhnlichen
Einstellungen: `appLockConfigured.v1` sagt **dass** eine Sperre besteht,
nie etwas über sie. Sie gehört genau deshalb nicht in den Schlüsselspeicher
— ihre Aufgabe ist, lesbar zu sein, wenn der es nicht ist. Daraus folgen
drei Regeln:

- Ohne Markierung und ohne lesbaren Speicher startet die App. Wo nie
  etwas geschützt wurde, ist ein fehlender Schlüsselbund kein Grund,
  jemanden auszusperren.
- Mit Markierung wirft `isEnabled()` `AppLockStatusUnavailable`, und die
  Weiche bleibt zu.
- Die Markierung wird beim Einrichten **zuletzt** gesetzt und beim
  Abschalten **zuletzt** entfernt. Andersherum sperrt ein fehlgeschlagener
  Schreibvorgang jemanden aus seinem eigenen Haushalt aus, für den es
  keine Passphrase gibt.

Beim **Datenschlüssel** darf derselbe Fehler verschluckt werden, und das ist
kein Widerspruch: „kein Schlüssel" wird dort von den Dateien auf der Platte
beantwortet — verschlüsselte ohne Schlüssel führen in die Wiederherstellung,
unverschlüsselte bleiben schlicht unverschlüsselt. Es öffnet sich nichts,
was zu bleiben hatte.

Was macOS ohne Signaturzertifikat angeht: dort nimmt der Schlüsselspeicher
gar nichts an. `keyStoreAccepts()` probiert das mit einem Wegwerfwert aus,
statt es zu behaupten, und die Einstellungskarte sagt es — vorher bot sie
eine Umstellung an, die beim Erzeugen des Schlüssels gescheitert wäre und
mit einer Aufforderung zum Neustart für nichts geendet hätte.


### Eine Warnung, die nirgendwohin führte

`hazard_response_lists.dart` ordnet den Ereignistyp einer Warnung der
Liste zu, die dazu gehört. Drei Dinge daran sind Absicht.

**Schlüsselwörter statt einer Tabelle.** Der Wortlaut gehört dem Dienst:
der DWD allein sagt „Sturmböen", „Schwere Sturmböen", „Orkanartige Böen"
und „Orkanböen" für dasselbe Wetter. Eine Tabelle wäre am Tag nach der
nächsten Textänderung still falsch.

**Die Wörter stehen gefaltet da.** `foldForSearch` macht aus `ö` ein `o`,
nicht `oe`. Ein Schlüsselwort in deutscher Schreibung träfe nie — und ein
nicht getroffenes Schlüsselwort sieht genauso aus wie eine Warnung, zu der
es keine Liste gibt.

**Kein Treffer ist eine Antwort.** Glatteis, Nebel, ein Gefahrstoff: die
Karte bietet nichts an, statt das Nächstbeste vorzuschlagen. Ein Angebot,
das nicht passt, ist auf diesem Bildschirm schlechter als keines.
„Sturmflut" steht deshalb bei Hochwasser und nicht bei Sturm, obwohl das
Wort mit „Sturm" anfängt: was hereinkommt, ist Wasser.


### Sprechen kann nicht jede Plattform

`core/speech_capabilities.dart` hat dieselbe Form wie
`notification_capabilities.dart`, aus demselben Grund: `flutter_tts`
liefert keine Linux-Umsetzung, und es gibt nichts, worauf es dort
ausweichen könnte. Eine Schaltfläche, die nichts tut, ist schlechter als
keine.

Dass das Plugin für eine Plattform existiert, heißt aber noch nicht, dass
auf dem Gerät eine Stimme liegt. Deshalb zwei Tore: die Plattform wird
statisch beantwortet, das Gerät wird gefragt (`StepSpeech.isAvailable`).
Die Schaltfläche erscheint einen Frame später als der Rest des
Bildschirms — besser als eine, die sich als wirkungslos herausstellt.

Auf Android braucht es dafür seit Version 11 einen `<queries>`-Eintrag für
`android.intent.action.TTS_SERVICE`. Ohne ihn ist die Sprachausgabe für
die App unsichtbar, und jedes Gerät meldet, es könne nicht sprechen.

**Ungeprüft:** ob auf Android, iOS, macOS und Windows tatsächlich eine
deutsche Stimme vorliegt, ist hier nicht festzustellen. Der Code ist so
gebaut, dass die Antwort „nein" nichts kostet.


## Conventions

Comments explain *why*, not *what* — the existing ones are the model to match,
including their density. Prefer extending an existing service over adding a
parallel one.

### Resource and interaction limits

- `HomeShell` creates destinations on first use and preserves their navigation
  state afterwards. `FeatureActivity` releases a map renderer a minute after
  the map leaves the screen (`BaseMapLayer.releaseGrace`), not the instant it
  does: reading and decoding a screenful of 48 tiles out of a country extract
  is 117 ms, and dropping the cache on every tab switch paid that again on
  every return. Memory pressure ends the grace period early. Map camera
  state stays in the screen. Shelter search requests location only after a user
  action.
- Vector map caches have a 16 MiB tile budget on mobile and 48 MiB on desktop,
  with 32/80 parsed entries and 2/4–8 render workers. Memory pressure recreates
  the renderer with 8 MiB, 16 entries and one worker. These are cache budgets,
  not a bound on total process memory.
- ZIM clusters are limited to 64 MiB stored and decompressed. The LRU cluster
  cache holds at most four clusters and 32 MiB in total. Larger permitted
  clusters are returned uncached. Memory pressure clears the open archive's
  cache. Zlib/XZ output is bounded while decoding; Zstandard frame windows,
  content sizes and conservative block expansion bounds are checked before the
  native decoder is called. Archives requiring larger clusters are refused.
- `ShelterSearch` starts both sources together and publishes partial results.
  Timeouts produce a source failure, not an empty successful search. A generation
  counter rejects responses to superseded or canceled searches. Geocoding has
  a 15-second timeout; WWBOTA and Overpass requests have 20/30-second timeouts.
- Inventory search combines terms across name, barcode, location and notes.
  Category, location and status filters can be combined; sorting supports name,
  expiry and attention. Expiry filters use calendar dates (today remains valid)
  and a seven-day upcoming window. Search and filters leave supply totals intact.
- Leaving an edited inventory form requires discarding the changes explicitly.
  Original photos survive until a successful save; abandoned temporary photos
  are removed. Delete offers eight seconds to undo. Undo restores the latest
  stored fields with a new dirty version so the restoration synchronizes too.
- The overview offers a direct first-item action for an empty household,
  visibly marks cards as links, and uses two columns on wide screens when text
  size permits. Displayed supply quantities follow the selected locale.
