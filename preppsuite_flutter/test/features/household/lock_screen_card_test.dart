import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/card_people.dart';
import 'package:preppsuite_flutter/features/household/application/lock_screen_card.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The emergency card as a lock-screen picture (#103).
void main() {
  HouseholdMember card({
    String? medication = 'Ramipril 5 mg',
    String? allergies = 'Penicillin',
  }) => HouseholdMember(
    clientId: 'lena',
    householdId: 'h',
    name: 'Lena Beispiel',
    birthYear: 1985,
    bloodType: 'A+',
    allergies: allergies,
    medication: medication,
    emergencyContact: encodeCardPeople([
      const CardPerson(
        name: 'Tom Beispiel',
        role: 'Partner',
        phone: '0151 2345678',
      ),
    ]),
    sortOrder: 0,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  String label(LockScreenField field) => field.name;

  test('only filled-in fields are offered', () {
    final fields = availableLockScreenFields(card(medication: null));

    expect(fields, contains(LockScreenField.allergies));
    expect(fields, isNot(contains(LockScreenField.medication)));
    expect(fields, isNot(contains(LockScreenField.conditions)));
  });

  test('medication and conditions are not ticked unless chosen', () {
    expect(
      defaultLockScreenFields,
      isNot(contains(LockScreenField.medication)),
    );
    expect(
      defaultLockScreenFields,
      isNot(contains(LockScreenField.conditions)),
    );
    expect(defaultLockScreenFields, contains(LockScreenField.contacts));
  });

  test('the lines are what was chosen, in a fixed order', () {
    final lines = lockScreenLines(
      card(),
      {LockScreenField.contacts, LockScreenField.name},
      label: label,
    );

    expect(lines.map((l) => l.label), ['name', 'contacts']);
    expect(lines.last.value, 'Tom Beispiel (Partner) 0151 2345678');
  });

  testWidgets('the picture is a PNG of the requested size', (tester) async {
    late Uint8List png;
    await tester.runAsync(() async {
      png = await renderLockScreenCard(
        heading: 'IM NOTFALL',
        lines: lockScreenLines(card(), {
          ...defaultLockScreenFields,
          LockScreenField.medication,
        }, label: label),
        size: const Size(1179, 2556),
      );
    });

    // PNG signature, then width and height in the IHDR chunk.
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
    final header = ByteData.sublistView(png, 16, 24);
    expect(header.getUint32(0), 1179);
    expect(header.getUint32(4), 2556);

    final out = Platform.environment['LOCK_SCREEN_PREVIEW'];
    if (out != null) File(out).writeAsBytesSync(png);
  });
}
