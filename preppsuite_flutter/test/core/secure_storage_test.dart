import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/secure_storage.dart';

/// A failed read must not delete the key to the household (#335).
void main() {
  test('a keystore error does not reset the store', () {
    expect(appSecureStorage.aOptions.toMap()['resetOnError'], 'false');
  });

  test('nothing in the app builds a store of its own', () {
    final others = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.endsWith('core/secure_storage.dart') &&
            entity.readAsStringSync().contains(
              RegExp(r'\bFlutterSecureStorage\('),
            ))
          entity.path,
    ];
    expect(others, isEmpty);
  });
}
