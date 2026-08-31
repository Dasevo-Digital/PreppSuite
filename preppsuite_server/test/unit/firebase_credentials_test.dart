import 'dart:io';

import 'package:preppsuite_server/src/notifications/services/firebase_credentials.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('fbcreds'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  String pathIn(String name) => '${tempDir.path}/$name';

  test('no password and no file means no credentials', () {
    // The normal state of a fresh install. Must be a plain "off", not an
    // error — the server has to boot and keep polling warnings.
    expect(
      resolveFirebaseServiceAccount(
        password: null,
        path: pathIn('missing.json'),
      ),
      isNull,
    );
  });

  test('the key file is read when there is no password', () {
    final path = pathIn('key.json');
    File(path).writeAsStringSync('{"project_id":"from-file"}');

    expect(
      resolveFirebaseServiceAccount(password: null, path: path),
      contains('from-file'),
    );
  });

  test('the password wins over the file', () {
    // Explicit configuration — which is also how an environment variable
    // arrives — must not be overruled by a file left in a container image.
    final path = pathIn('key.json');
    File(path).writeAsStringSync('{"project_id":"from-file"}');

    expect(
      resolveFirebaseServiceAccount(
        password: '{"project_id":"from-password"}',
        path: path,
      ),
      contains('from-password'),
    );
  });

  test('a blank password falls through to the file', () {
    // An env var set to the empty string is how a misconfigured container
    // usually presents itself; treating it as a credential would disable
    // push with no clue why.
    final path = pathIn('key.json');
    File(path).writeAsStringSync('{"project_id":"from-file"}');

    expect(
      resolveFirebaseServiceAccount(password: '   ', path: path),
      contains('from-file'),
    );
  });

  test('an empty key file counts as absent', () {
    final path = pathIn('key.json');
    File(path).writeAsStringSync('\n');

    expect(
      resolveFirebaseServiceAccount(password: null, path: path),
      isNull,
    );
  });
}
