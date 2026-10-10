/// Reading and writing the household's offers to and from its neighbours
/// (#152).
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';
import 'neighbour_offer_code.dart';

final neighbourOffersProvider = StreamProvider.autoDispose
    .family<List<NeighbourOffer>, String>((ref, householdId) {
      return ref.watch(appDatabaseProvider).watchNeighbourOffers(householdId);
    });

final neighbourOfferControllerProvider = Provider.autoDispose
    .family<NeighbourOfferController, String>(
      (ref, householdId) => NeighbourOfferController(
        database: ref.watch(appDatabaseProvider),
        householdId: householdId,
      ),
    );

extension NeighbourOfferRow on NeighbourOffer {
  NeighbourOfferKind get offerKind => neighbourOfferKindOf(kind);

  /// The day it was offered, as the midnight-UTC instant it was stored
  /// as. The database hands it back in local time.
  DateTime get offeredDay {
    final utc = offeredOn.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  /// The row as the code it travels as.
  NeighbourOfferCode get code => NeighbourOfferCode(
    kind: offerKind,
    body: body,
    contact: contact,
    offeredOn: offeredDay,
  );
}

class NeighbourOfferController {
  const NeighbourOfferController({
    required AppDatabase database,
    required this.householdId,
  }) : _db = database;

  final AppDatabase _db;
  final String householdId;

  /// One of the household's own offers, new or changed. Changing one
  /// makes it a new offer as far as the code is concerned: today's date
  /// goes in, because whoever scans it again should not read "offered in
  /// March" for water that was counted this morning.
  Future<void> saveOwn({
    required NeighbourOfferKind kind,
    required String body,
    String? contact,
    NeighbourOffer? existing,
    DateTime? now,
  }) async {
    final today = _today(now ?? DateTime.now());
    final reach = cleanNeighbourOfferText(
      contact ?? '',
      neighbourOfferContactLimit,
    );
    await _db.upsertNeighbourOffer(
      NeighbourOffersCompanion.insert(
        clientId: existing?.clientId ?? const Uuid().v4(),
        householdId: householdId,
        kind: kind.name,
        body: cleanNeighbourOfferText(body, neighbourOfferBodyLimit),
        contact: Value(reach.isEmpty ? null : reach),
        offeredOn: today,
        updatedAt: DateTime.now().toUtc(),
        // Said, not left to the column default: on an edit the row
        // already exists, and a default only applies to an insert.
        dirty: const Value(true),
      ),
    );
  }

  /// A neighbour's offer, scanned or pasted. False, and nothing written,
  /// when the same offer is already in the list: one code filmed twice,
  /// or held up again a week later, is one offer.
  Future<bool> receive(NeighbourOfferCode offer) async {
    final held = await _db.watchNeighbourOffers(householdId).first;
    final known = held.any(
      (row) =>
          row.received &&
          row.kind == offer.kind.name &&
          row.body == offer.body &&
          row.contact == offer.contact &&
          _storedDay(row.offeredOn) == _storedDay(offer.offeredOn),
    );
    if (known) return false;

    await _db.upsertNeighbourOffer(
      NeighbourOffersCompanion.insert(
        clientId: const Uuid().v4(),
        householdId: householdId,
        received: const Value(true),
        kind: offer.kind.name,
        body: offer.body,
        contact: Value(offer.contact),
        offeredOn: _storedDay(offer.offeredOn),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
    return true;
  }

  /// A tombstone, like every other row, so the deletion reaches the
  /// household's other devices instead of the row coming back from them.
  Future<void> delete(NeighbourOffer offer) {
    return _db.upsertNeighbourOffer(
      offer
          .toCompanion(false)
          .copyWith(
            deletedAt: Value(DateTime.now().toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
    );
  }

  /// Today where the offer is made, as the midnight-UTC instant every
  /// offer's day is stored as -- a date, which is all an offer carries.
  static DateTime _today(DateTime now) {
    final local = now.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// A stored or decoded day back as that instant. The database hands
  /// times back in local time, and west of Greenwich midnight UTC is the
  /// evening before, so the day is read in UTC.
  static DateTime _storedDay(DateTime day) {
    final utc = day.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
