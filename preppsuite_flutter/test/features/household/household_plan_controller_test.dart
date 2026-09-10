import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_plan_controller.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Saving the household's plan.
///
/// Written for the municipality's contact point, which had to be threaded
/// through four places — the form, the draft, the save and the printed
/// sheet — and where dropping it in any one of them would look like it
/// saved and quietly lose it.
void main() {
  late AppDatabase db;
  late HouseholdPlanController controller;

  const householdId = 'household-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = HouseholdPlanController(
      database: db,
      householdId: householdId,
    );
  });
  tearDown(() => db.close());

  Future<HouseholdPlan?> stored() => db.watchHouseholdPlan(householdId).first;

  test('the contact point survives the save', () async {
    await controller.save(
      const HouseholdPlanDraft(
        localContactPoint: 'Grundschule Nordstadt, Turnhalle',
      ),
    );

    expect(
      (await stored())!.localContactPoint,
      'Grundschule Nordstadt, Turnhalle',
    );
  });

  test('it is stored beside the meeting points, not instead of them', () async {
    // The two are different errands and the plan has to hold both: where
    // the household gathers, and where it goes for help.
    await controller.save(
      const HouseholdPlanDraft(
        meetingPointNear: 'Vor der Garage',
        localContactPoint: 'Feuerwache 3',
      ),
    );

    final plan = await stored();
    expect(plan!.meetingPointNear, 'Vor der Garage');
    expect(plan.localContactPoint, 'Feuerwache 3');
  });

  test('whitespace is stored as nothing at all', () async {
    // Empty is null and not "", so the printed sheet can tell "nobody
    // filled this in" from "somebody typed a space".
    await controller.save(
      const HouseholdPlanDraft(
        meetingPointNear: 'Vor der Garage',
        localContactPoint: '   ',
      ),
    );

    expect((await stored())!.localContactPoint, isNull);
  });

  test('a plan holding only the contact point is not empty', () async {
    // `isEmpty` guards against saving a blank plan over a real one, so a
    // field missing from that list would make its own value unsaveable.
    const draft = HouseholdPlanDraft(localContactPoint: 'Feuerwache 3');

    expect(draft.isEmpty, isFalse);
    expect(const HouseholdPlanDraft().isEmpty, isTrue);
  });

  test('every field of the draft counts towards emptiness', () async {
    // Catches the next field added to the plan and forgotten in isEmpty.
    const filled = [
      HouseholdPlanDraft(meetingPointNear: 'x'),
      HouseholdPlanDraft(meetingPointFar: 'x'),
      HouseholdPlanDraft(contactName: 'x'),
      HouseholdPlanDraft(contactPhone: 'x'),
      HouseholdPlanDraft(localContactPoint: 'x'),
      HouseholdPlanDraft(kitLocation: 'x'),
      HouseholdPlanDraft(shutoffLocation: 'x'),
      HouseholdPlanDraft(notes: 'x'),
    ];

    for (final draft in filled) {
      expect(draft.isEmpty, isFalse);
    }
  });
}
