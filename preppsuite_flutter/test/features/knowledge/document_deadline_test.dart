import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/document_deadline.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

PersonalDocument document({
  String id = 'one',
  DateTime? until,
  DateTime? remind,
  DateTime? reviewed,
}) => PersonalDocument(
  id: id,
  location: '/documents/plan.md',
  label: 'Plan.md',
  addedAt: DateTime.utc(2026),
  validUntil: until,
  remindOn: remind,
  reviewedOn: reviewed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('old documents remain readable without deadline metadata', () {
    final old = PersonalDocument.fromJson({
      'id': 'one',
      'location': '/documents/plan.md',
      'label': 'Plan.md',
      'addedAt': '2026-01-01T00:00:00Z',
    })!;
    expect(old.validUntil, isNull);
    expect(old.remindOn, isNull);
    expect(old.originalLocation, isEmpty);
  });

  test('calendar dates survive serialization without timezone conversion', () {
    final source = document(
      until: DateTime.utc(2026, 10, 25, 23),
      remind: DateTime(2026, 3, 29),
    );
    expect(source.toJson()['validUntil'], '2026-10-25');
    final restored = PersonalDocument.fromJson(source.toJson())!;
    expect(restored.validUntil, DateTime(2026, 10, 25));
    expect(restored.remindOn, DateTime(2026, 3, 29));
  });

  test('invalid metadata loses only its date, never the document', () {
    final restored = PersonalDocument.fromJson({
      ...document().toJson(),
      'validUntil': '2026-02-30',
      'remindOn': 'not a date',
      'reviewedOn': 42,
    })!;
    expect(restored.id, 'one');
    expect(restored.validUntil, isNull);
    expect(restored.remindOn, isNull);
    expect(readDocumentDate('2026-03-01T23:00:00Z'), isNull);
  });

  test('valid through its calendar day, expired on the following day', () {
    final d = document(until: DateTime(2026, 10, 25));
    expect(
      documentDeadlineStatus(d, now: DateTime(2026, 10, 25, 23, 59)),
      DocumentDeadlineStatus.expiresToday,
    );
    expect(
      documentDeadlineStatus(d, now: DateTime(2026, 10, 26)),
      DocumentDeadlineStatus.expired,
    );
  });

  test(
    'reviewing dismisses a reminder but never renews an expired document',
    () {
      final d = document(remind: DateTime(2026, 10, 25));
      expect(
        documentDeadlineStatus(d, now: DateTime(2026, 10, 26)),
        DocumentDeadlineStatus.reminderDue,
      );
      expect(
        documentDeadlineStatus(
          d.copyWith(reviewedOn: DateTime(2026, 10, 26)),
          now: DateTime(2026, 10, 26),
        ),
        DocumentDeadlineStatus.current,
      );
      expect(
        documentDeadlineStatus(
          d.copyWith(
            validUntil: DateTime(2026, 10, 24),
            reviewedOn: DateTime(2026, 10, 26),
          ),
          now: DateTime(2026, 10, 26),
        ),
        DocumentDeadlineStatus.expired,
      );
    },
  );

  test('reminders keep the nearest dates within the shared budget', () {
    final planned = planDocumentReminders(
      [
        document(id: 'later', remind: DateTime(2026, 11, 2)),
        document(id: 'first', remind: DateTime(2026, 10, 25)),
        document(
          id: 'reviewed',
          remind: DateTime(2026, 10, 26),
          reviewed: DateTime(2026, 10, 26),
        ),
        document(id: 'past', remind: DateTime(2026, 10, 20)),
      ],
      now: DateTime(2026, 10, 24),
      limit: 1,
    );
    expect(planned.map((r) => r.documentId), ['first']);
    expect(planned.single.fireAt, DateTime(2026, 10, 25, 9));
    expect(
      planDocumentReminders(
        [document(remind: DateTime(2026, 10, 25))],
        now: DateTime(2026, 10, 24),
        limit: 0,
      ),
      isEmpty,
    );
  });

  test('concurrent index, reading-position and deadline writes preserve each other', () async {
    const store = PersonalDocumentStore();
    final id = (await store.add(
      location: '/documents/plan.md',
      label: 'Plan.md',
    )).single.id;
    await Future.wait([
      store.updateIndex(
        id,
        status: 'ready',
        characters: 123,
        fingerprint: 'new',
      ),
      store.updateDeadline(
        id,
        validUntil: DateTime(2027, 1, 1),
        remindOn: DateTime(2026, 12, 1),
        reviewedOn: DateTime(2026, 10, 28),
        originalLocation: '  Ordner A  ',
      ),
      store.updateReaderOffset(id, 42),
    ]);
    await store.relocate(id, '/documents/new.md');
    final d = (await store.load()).single;
    expect(d.indexStatus, 'ready');
    expect(d.readerOffset, 42);
    expect(d.sourceFingerprint, 'new');
    expect(d.location, '/documents/new.md');
    expect(d.originalLocation, 'Ordner A');
    expect(d.validUntil, DateTime(2027, 1, 1));
    expect(d.remindOn, DateTime(2026, 12, 1));
    await store.clearIndex();
    expect((await store.load()).single.validUntil, DateTime(2027, 1, 1));
  });

  test('clearing dates is persisted and a later edit does not resurrect a removed document', () async {
    const store = PersonalDocumentStore();
    final id = (await store.add(
      location: '/documents/a.md',
      label: 'A.md',
    )).single.id;
    await store.updateDeadline(
      id,
      validUntil: DateTime(2027),
      remindOn: null,
      reviewedOn: null,
      originalLocation: 'A',
    );
    await store.updateDeadline(
      id,
      validUntil: null,
      remindOn: null,
      reviewedOn: null,
      originalLocation: '',
    );
    expect((await store.load()).single.validUntil, isNull);
    await Future.wait([
      store.remove(id),
      store.updateDeadline(
        id,
        validUntil: DateTime(2028),
        remindOn: null,
        reviewedOn: null,
        originalLocation: 'B',
      ),
    ]);
    expect(await store.load(), isEmpty);
  });
}
