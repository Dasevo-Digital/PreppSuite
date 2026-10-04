/// An emergency card as a lock-screen picture (#103).
///
/// A paramedic does not unlock a stranger's phone. What they can read is
/// the lock screen, so a picture there is the one place a card is seen
/// when its owner cannot hand it over. iOS has the Medical ID for this,
/// but only for the phone's owner and only if it was filled in; this works
/// for every card in the household and on any phone.
///
/// The trade-off is stated on the screen and decided per field: anybody
/// who holds the phone can read the picture. Nothing is chosen for the
/// person except a cautious default -- name, blood type, allergies and whom
/// to call -- and medication and conditions stay off until ticked.
///
/// Drawn here with `dart:ui` and nothing else, so it needs no network, no
/// widget tree and no plugin, and a test can look at the result.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../local_db/database.dart';
import 'card_people.dart';

/// What can go onto the picture, in the order it is printed.
enum LockScreenField {
  name,
  birthYear,
  bloodType,
  allergies,
  medication,
  conditions,
  careNeeds,
  contacts,
}

/// Ticked unless somebody unticks them. Medication and conditions say a
/// great deal about a person to whoever finds the phone, so they wait for
/// a deliberate tick.
const defaultLockScreenFields = {
  LockScreenField.name,
  LockScreenField.bloodType,
  LockScreenField.allergies,
  LockScreenField.contacts,
};

/// The fields this card has anything in. An empty one is not offered.
List<LockScreenField> availableLockScreenFields(HouseholdMember card) => [
  for (final field in LockScreenField.values)
    if (_value(card, field) case final value? when value.isNotEmpty) field,
];

/// One printed line: a label and what follows it.
typedef LockScreenLine = ({String label, String value});

/// The lines for [fields], in the enum's order, labelled by [label].
List<LockScreenLine> lockScreenLines(
  HouseholdMember card,
  Set<LockScreenField> fields, {
  required String Function(LockScreenField field) label,
}) => [
  for (final field in LockScreenField.values)
    if (fields.contains(field))
      if (_value(card, field) case final value? when value.isNotEmpty)
        (label: label(field), value: value),
];

String? _value(HouseholdMember card, LockScreenField field) => switch (field) {
  LockScreenField.name => card.name.trim(),
  LockScreenField.birthYear => card.birthYear?.toString(),
  LockScreenField.bloodType => card.bloodType?.trim(),
  LockScreenField.allergies => card.allergies?.trim(),
  LockScreenField.medication => card.medication?.trim(),
  LockScreenField.conditions => card.conditions?.trim(),
  LockScreenField.careNeeds => card.careNeeds?.trim(),
  LockScreenField.contacts => [
    for (final person in parseCardPeople(card.emergencyContact))
      [
        if (person.name.isNotEmpty) person.name,
        if (person.role.isNotEmpty) '(${person.role})',
        if (person.phone.isNotEmpty) person.phone,
      ].join(' '),
  ].where((line) => line.isNotEmpty).join('\n'),
};

/// Draws the picture and returns it as PNG.
///
/// [size] is in physical pixels, the phone's own screen. The text starts
/// below the top third, where the clock and the date sit on every lock
/// screen, and it is large: it is read at arm's length, often by torch.
Future<Uint8List> renderLockScreenCard({
  required String heading,
  required List<LockScreenLine> lines,
  required Size size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);
  final unit = size.width / 100;

  canvas.drawRect(
    Offset.zero & size,
    Paint()..color = const Color(0xFF111418),
  );

  var y = size.height * 0.36;
  final margin = unit * 7;
  final width = size.width - 2 * margin;

  // The band: red, and the one word anybody looks for.
  final band = TextPainter(
    text: TextSpan(
      text: heading,
      style: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: unit * 6.5,
        fontWeight: FontWeight.w800,
        letterSpacing: unit * 0.4,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final bandHeight = band.height + unit * 5;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, y, width, bandHeight),
      Radius.circular(unit * 2.5),
    ),
    Paint()..color = const Color(0xFFC62828),
  );
  band.paint(canvas, Offset(margin + unit * 4, y + unit * 2.5));
  y += bandHeight + unit * 5;

  for (final line in lines) {
    final label = TextPainter(
      text: TextSpan(
        text: line.label.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFFB0B8C1),
          fontSize: unit * 3.4,
          fontWeight: FontWeight.w600,
          letterSpacing: unit * 0.15,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final value = TextPainter(
      text: TextSpan(
        text: line.value,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: unit * 5.2,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '…',
    )..layout(maxWidth: width);
    // Stops before the bottom edge, where the lock screen keeps its own
    // buttons; what does not fit is left off rather than drawn under them.
    if (y + label.height + value.height > size.height * 0.9) break;
    label.paint(canvas, Offset(margin, y));
    y += label.height + unit;
    value.paint(canvas, Offset(margin, y));
    y += value.height + unit * 4;
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.round(),
    size.height.round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}
