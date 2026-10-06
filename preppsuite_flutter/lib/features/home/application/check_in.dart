import 'dart:convert';

import '../../../core/private_preferences.dart';

/// A sign of life, sent by text message (#116).
///
/// After a disaster the mobile data network is the first thing to choke
/// and a text message often still gets through: it is small, it is
/// stored and forwarded, and it does not need both ends to be reachable
/// at the same moment. The American Red Cross's "Family Safe" and the
/// Turkish rescue service AKUT's "IamSafe" are built on that. So is this,
/// without a server: the message is composed here and handed to the
/// phone's own messaging app, one contact at a time, or to any other app
/// through the share sheet.
enum CheckInStatus { safe, needHelp, onMyWay }

/// Somebody the household tells that it is alive.
class CheckInContact {
  const CheckInContact({required this.name, required this.phone});

  final String name;
  final String phone;

  Map<String, String> toJson() => {'name': name, 'phone': phone};

  static CheckInContact? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final phone = json['phone'];
    if (name is! String || phone is! String) return null;
    final number = normalisePhone(phone);
    if (number == null) return null;
    return CheckInContact(name: name.trim(), phone: number);
  }
}

/// The digits of a phone number and a leading plus, or null when what
/// is left is too short to dial.
///
/// Spaces, slashes, dashes and brackets are what people type into a
/// number and what an `sms:` link does not want.
String? normalisePhone(String raw) {
  final trimmed = raw.trim();
  final plus = trimmed.startsWith('+') || trimmed.startsWith('00');
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final national = trimmed.startsWith('00') ? digits.substring(2) : digits;
  if (national.length < 4) return null;
  return plus ? '+$national' : national;
}

/// Phone numbers inside free text -- the emergency contact on a member's
/// card is one line like "Mama, 0171 2345678".
List<String> phoneNumbersIn(String text) => [
  for (final match in RegExp(
    r'(\+|00)?[0-9][0-9 /()\-]{5,}[0-9]',
  ).allMatches(text))
    ?normalisePhone(match.group(0)!),
];

/// The `sms:` link for one recipient with the text filled in.
///
/// iOS reads the body after `&`, everything else after `?`. Both encode
/// a space as `%20`; a `+` would arrive as a plus sign.
Uri smsUri(String phone, String body, {required bool ios}) =>
    Uri.parse('sms:$phone${ios ? '&' : '?'}body=${Uri.encodeComponent(body)}');

/// The status text and what follows it, in one message short enough to
/// survive as a single text where it can.
String composeCheckIn({
  required String status,
  required String time,
  String? location,
  String? note,
}) {
  final parts = [
    status,
    time,
    if (location != null && location.isNotEmpty) location,
    if (note != null && note.trim().isNotEmpty) note.trim(),
  ];
  return parts.join('\n');
}

/// Where a position is, in a form every phone can open: the numbers for
/// somebody to read out, and a map link for somebody to tap.
String describePosition(
  double latitude,
  double longitude, {
  double? accuracyMetres,
}) {
  final lat = latitude.toStringAsFixed(5);
  final lon = longitude.toStringAsFixed(5);
  final accuracy = accuracyMetres == null
      ? ''
      : ' (±${accuracyMetres.round()} m)';
  return '$lat, $lon$accuracy\n'
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon';
}

/// The contacts, encrypted: a list of who matters to a household is
/// exactly the kind of thing that does not belong on a disk in the clear.
class CheckInContactStore {
  const CheckInContactStore();

  static const _key = 'checkInContacts.v1';

  Future<List<CheckInContact>> load() async {
    try {
      final raw = await const PrivatePreferences().getString(_key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?CheckInContact.fromJson(item)];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<CheckInContact> contacts) async {
    if (contacts.isEmpty) {
      await const PrivatePreferences().remove(_key);
      return;
    }
    await const PrivatePreferences().setString(
      _key,
      jsonEncode([for (final contact in contacts) contact.toJson()]),
    );
  }
}
