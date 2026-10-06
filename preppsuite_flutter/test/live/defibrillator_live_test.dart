import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/defibrillators.dart';

/// Against the real Overpass API. Skipped unless PREPPSUITE_TEST_NETWORK
/// is set.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real Overpass API'
      : null;

  test('Braunschweig has defibrillators with a location', () async {
    final client = DefibrillatorClient();
    addTearDown(client.close);
    final found = await client.near(52.2689, 10.5268);
    stdout.writeln('${found.length} Defibrillatoren');
    // Eighteen when this was written.
    expect(found.length, greaterThan(5));
    expect(found.where((d) => d.locationIn('de') != null), isNotEmpty);
  }, skip: reason);
}
