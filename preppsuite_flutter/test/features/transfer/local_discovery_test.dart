import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/transfer/application/local_discovery.dart';

void main() {
  final address = InternetAddress.loopbackIPv4;
  final now = DateTime.utc(2026, 9, 16, 12);

  test('accepts only the anonymous, versioned local presence format', () {
    final found = LocalTransferPresence.decode(
      'PSLD1:0123456789abcdef',
      address: address,
      seenAt: now,
    );

    expect(found, isNotNull);
    expect(found!.sessionId, '0123456789abcdef');
    expect(found.address, address);
    expect(found.seenAt, now);
  });

  test('rejects anything that could be mistaken for an invitation', () {
    for (final raw in [
      'PSLD1:short',
      'PSLD1:0123456789abcdef:extra',
      'PSL1:0123456789abcdef',
      'PSLD1:0123456789abcdef:household',
      'PSLD1:0123456789ABCDEf',
    ]) {
      expect(
        LocalTransferPresence.decode(raw, address: address, seenAt: now),
        isNull,
        reason: raw,
      );
    }
  });
}
