import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';

/// What the shared folder gives away, and what it does not.
void main() {
  // Argon2id at the real work factors costs about a second per call, and
  // several tests need a key. Deriving once keeps the suite usable; the
  // production factors are covered by their own test below.
  final fast = VaultParameters.testing;

  late FolderKey key;
  late FolderKey otherKey;

  setUpAll(() async {
    key = await deriveFolderKey('richtig', fast);
    otherKey = await deriveFolderKey('falsch', fast);
  });

  test('what goes in comes back out', () async {
    final sealed = await encryptForFolder('{"inventory":[]}', key);

    expect(await decryptFromFolder(sealed, key), '{"inventory":[]}');
  });

  test('the plaintext is not in the file', () async {
    // The whole point. A grep through a Nextcloud folder must not turn up
    // what a household keeps in its cellar.
    final sealed = await encryptForFolder('Jodtabletten', key);

    expect(sealed.contains('Jodtabletten'), isFalse);
    expect(base64Decode(jsonDecode(sealed)['data'] as String), isNotEmpty);
  });

  test('umlauts survive the round trip', () async {
    final sealed = await encryptForFolder('Grüße, Öl, Straße', key);

    expect(await decryptFromFolder(sealed, key), 'Grüße, Öl, Straße');
  });

  test('the same text twice gives different files', () async {
    // A fresh nonce each time. Otherwise an observer watching the folder
    // learns that nothing changed between two syncs, which is itself
    // information about a household.
    final a = await encryptForFolder('gleich', key);
    final b = await encryptForFolder('gleich', key);

    expect(a, isNot(b));
    expect(await decryptFromFolder(b, key), 'gleich');
  });

  group('refusing to open', () {
    test('the wrong key returns nothing rather than rubbish', () async {
      final sealed = await encryptForFolder('geheim', key);

      expect(await decryptFromFolder(sealed, otherKey), isNull);
    });

    test('an altered ciphertext is refused, not decrypted', () async {
      // Without the tag check a cloud provider could flip bits in a
      // household's supplies and the app would merge the result.
      final sealed = await encryptForFolder('geheim', key);
      final json = jsonDecode(sealed) as Map<String, Object?>;
      final data = base64Decode(json['data'] as String);
      data[0] ^= 0xFF;
      json['data'] = base64Encode(data);

      expect(await decryptFromFolder(jsonEncode(json), key), isNull);
    });

    test('an altered nonce is refused', () async {
      final sealed = await encryptForFolder('geheim', key);
      final json = jsonDecode(sealed) as Map<String, Object?>;
      final nonce = base64Decode(json['nonce'] as String);
      nonce[0] ^= 0xFF;
      json['nonce'] = base64Encode(nonce);

      expect(await decryptFromFolder(jsonEncode(json), key), isNull);
    });

    test('plain JSON from an older device is not an envelope', () async {
      // A folder holds both while devices are being switched over, and
      // the reader has to tell them apart without a key.
      const plain = '{"version":1,"deviceId":"a","inventoryItems":[]}';

      expect(looksEncrypted(plain), isFalse);
      expect(await decryptFromFolder(plain, key), isNull);
    });

    test('a truncated download is not an envelope', () async {
      final sealed = await encryptForFolder('geheim', key);

      expect(looksEncrypted(sealed.substring(0, sealed.length ~/ 2)), isFalse);
    });

    test('an envelope from a future version is refused', () async {
      final json =
          jsonDecode(await encryptForFolder('x', key)) as Map<String, Object?>;
      json['v'] = 2;

      expect(looksEncrypted(jsonEncode(json)), isFalse);
    });
  });

  group('the passphrase check', () {
    test('accepts the passphrase the folder was set up with', () async {
      final check = await buildCheckValue(key);

      expect(await checkFolderKey(key, check), isTrue);
    });

    test('rejects any other', () async {
      final check = await buildCheckValue(key);

      expect(await checkFolderKey(otherKey, check), isFalse);
    });

    test('rejects a check value that is not an envelope', () async {
      expect(await checkFolderKey(key, 'kaputt'), isFalse);
    });
  });

  group('key derivation', () {
    test('the same passphrase and salt give the same key', () async {
      final a = await deriveFolderKey('gemeinsam', fast);
      final b = await deriveFolderKey('gemeinsam', fast);

      expect(a.bytes, b.bytes);
    });

    test('a different salt gives a different key', () async {
      // Two households on one passphrase must not share a key, and a
      // rainbow table must not span folders.
      final other = VaultParameters(
        salt: Uint8List.fromList(List.filled(saltLength, 9)),
        memory: fast.memory,
        iterations: fast.iterations,
        parallelism: fast.parallelism,
      );
      final a = await deriveFolderKey('gemeinsam', fast);
      final b = await deriveFolderKey('gemeinsam', other);

      expect(a.bytes, isNot(b.bytes));
    });

    test('the key is 256 bits', () async {
      expect(key.bytes.length, 32);
    });
  });

  group('the parameters travel with the folder', () {
    test('a round trip keeps every work factor', () {
      final restored = VaultParameters.fromJson(fast.toJson());

      expect(restored!.salt, fast.salt);
      expect(restored.memory, fast.memory);
      expect(restored.iterations, fast.iterations);
      expect(restored.parallelism, fast.parallelism);
    });

    test('an unknown KDF is refused rather than assumed', () {
      final json = fast.toJson()..['kdf'] = 'scrypt';

      expect(VaultParameters.fromJson(json), isNull);
    });

    test('a work factor that would hang the device is refused', () {
      // A folder claiming 8 GB of Argon2 memory is either broken or
      // hostile. Either way it must not be attempted.
      final json = fast.toJson()..['memory'] = 8 * 1024 * 1024;

      expect(VaultParameters.fromJson(json), isNull);
    });

    test('a missing salt is refused', () {
      final json = fast.toJson()..remove('salt');

      expect(VaultParameters.fromJson(json), isNull);
    });
  });

  test('a fresh salt is not the same twice', () {
    expect(newSalt(), isNot(newSalt()));
    expect(newSalt().length, saltLength);
  });

  test('the shipped work factors are the ones OWASP asks for', () {
    // Pinned so lowering them takes a deliberate edit here, not a
    // convenient one in passing while a phone feels slow.
    expect(argon2Memory, 65536);
    expect(argon2Iterations, 3);
    expect(argon2Parallelism, 1);
  });

  test('a stored key survives being written down and read back', () async {
    final restored = FolderKey.decode(key.encode());

    expect(restored?.bytes, key.bytes);
  });

  test('a key of the wrong length is refused', () {
    expect(FolderKey.decode(base64Encode(List.filled(16, 0))), isNull);
    expect(FolderKey.decode('nicht base64!'), isNull);
    expect(FolderKey.decode(null), isNull);
  });
}
