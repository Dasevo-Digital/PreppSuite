import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/portable_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  setUp(() => workspace = Directory.systemTemp.createTempSync('portable'));
  tearDown(() => workspace.deleteSync(recursive: true));

  /// Lays out a program the way a release actually unpacks, and returns
  /// the path of the executable inside it.
  String unpacked({required int depth, bool withDataFolder = true}) {
    var directory = Directory('${workspace.path}/PreppSuite-x64')
      ..createSync(recursive: true);
    final root = directory;
    for (var level = 0; level < depth; level++) {
      directory = Directory('${directory.path}/level$level')
        ..createSync(recursive: true);
    }
    final executable = File('${directory.path}/PreppSuite')
      ..writeAsStringSync('');
    if (withDataFolder) {
      Directory('${root.path}/$portableFolderName').createSync();
    }
    return executable.path;
  }

  test(
    'no folder beside the program is an ordinary installation',
    () async {
      final location = await resolvePortableLocation(
        environment: const {},
        executablePath: unpacked(depth: 0, withDataFolder: false),
        searchBesideProgram: true,
      );

      expect(location.isPortable, isFalse);
      expect(location.source, PortableSource.installed);
    },
  );

  test('a folder beside the program is found', () async {
    final location = await resolvePortableLocation(
      environment: const {},
      executablePath: unpacked(depth: 0),
      searchBesideProgram: true,
    );

    expect(location.isPortable, isTrue);
    expect(location.source, PortableSource.besideTheProgram);
    expect(location.directory!.path, endsWith(portableFolderName));
  });

  test(
    'a folder two levels above the program is found too',
    () async {
      // Which is the layout a Linux release actually has:
      // `PreppSuite-x64/bundle/PreppSuite`, so the folder somebody puts
      // beside what they unpacked is not beside the executable at all.
      final location = await resolvePortableLocation(
        environment: const {},
        executablePath: unpacked(depth: 2),
        searchBesideProgram: true,
      );

      expect(location.isPortable, isTrue);
    },
  );

  test('a folder far above the program is not dragged in', () async {
    // Four levels is already generous. Without a limit, a folder
    // anywhere up the tree — in somebody's home directory — would be
    // picked up by an installed copy that was never meant to be
    // portable.
    final location = await resolvePortableLocation(
      environment: const {},
      executablePath: unpacked(depth: 6),
      searchBesideProgram: true,
    );

    expect(location.isPortable, isFalse);
  });

  test(
    'macOS does not look beside the program, and that is deliberate',
    () {
      // The app runs sandboxed on purpose — that is what stops the system
      // asking for folder access again after every update — and a
      // sandboxed app may not read a directory next to its own bundle.
      // There the folder is chosen once through a panel instead.
      expect(findsPortableFolderByItself, !Platform.isMacOS);
      expect(supportsPortableData, isTrue);
    },
    skip: Platform.isAndroid || Platform.isIOS ? 'desktop only' : null,
  );

  test('the environment variable wins over everything', () async {
    final elsewhere = Directory('${workspace.path}/woanders')..createSync();

    final location = await resolvePortableLocation(
      environment: {portableEnvironmentVariable: elsewhere.path},
      executablePath: unpacked(depth: 0),
      searchBesideProgram: true,
    );

    expect(location.source, PortableSource.environment);
    expect(location.directory!.path, elsewhere.path);
  });

  test('a named folder that is not there falls through', () async {
    final location = await resolvePortableLocation(
      environment: {
        portableEnvironmentVariable: '${workspace.path}/gibtsnicht',
      },
      executablePath: unpacked(depth: 0, withDataFolder: false),
    );

    expect(location.isPortable, isFalse);
  });

  test(
    'a folder that cannot be written to is not used',
    () async {
      // A read-only stick, a mount without permission, a sandbox that
      // denies the path — all look like a perfectly good directory until
      // the first write, which would be half-way through opening a
      // database.
      final readOnly = Directory('${workspace.path}/schreibgeschuetzt')
        ..createSync();
      Process.runSync('chmod', ['500', readOnly.path]);
      addTearDown(() => Process.runSync('chmod', ['700', readOnly.path]));

      final location = await resolvePortableLocation(
        environment: {portableEnvironmentVariable: readOnly.path},
        executablePath: unpacked(depth: 0, withDataFolder: false),
      );

      expect(location.isPortable, isFalse);
    },
    skip: Platform.isWindows ? 'chmod is a POSIX idea' : null,
  );

  group('a chosen folder that is not there', () {
    /// Writes the pointer file the way choosing a folder does, and gives
    /// back the directory it lives in.
    Directory pointingAt(String path) {
      final support = Directory('${workspace.path}/support')
        ..createSync(recursive: true);
      File('${support.path}/portable-data.txt').writeAsStringSync(path);
      return support;
    }

    test('is reported rather than silently ignored', () async {
      // The case this exists for: the household is on an external disk
      // and the disk is not plugged in. Opening the other database
      // without a word is what makes it dangerous.
      final gone = '${workspace.path}/nicht-eingehaengt';

      final location = await resolvePortableLocation(
        environment: const {},
        executablePath: unpacked(depth: 0, withDataFolder: false),
        searchBesideProgram: true,
        pointerDirectory: pointingAt(gone),
      );

      expect(location.isPortable, isFalse, reason: 'it still starts');
      expect(location.choiceIsMissing, isTrue);
      expect(location.missingChoice, gone);
    });

    test('is still reported when some other folder is found instead', () async {
      // Worse than finding nothing: the app would come up on a different
      // household and look perfectly fine doing it.
      final executable = unpacked(depth: 0);

      final location = await resolvePortableLocation(
        environment: const {},
        executablePath: executable,
        searchBesideProgram: true,
        pointerDirectory: pointingAt('${workspace.path}/nicht-eingehaengt'),
      );

      expect(location.isPortable, isTrue);
      expect(location.source, PortableSource.besideTheProgram);
      expect(location.choiceIsMissing, isTrue);
    });

    test('a folder that is there is not reported as missing', () async {
      final there = Directory('${workspace.path}/eingehaengt')
        ..createSync(recursive: true);

      final location = await resolvePortableLocation(
        environment: const {},
        executablePath: unpacked(depth: 0, withDataFolder: false),
        searchBesideProgram: true,
        pointerDirectory: pointingAt(there.path),
      );

      expect(location.isPortable, isTrue);
      expect(location.source, PortableSource.chosen);
      expect(location.choiceIsMissing, isFalse);
    });

    test('never choosing one is not a missing choice', () async {
      // The two look the same to the code that opens the database and
      // are opposites to the person using it.
      final location = await resolvePortableLocation(
        environment: const {},
        executablePath: unpacked(depth: 0, withDataFolder: false),
        searchBesideProgram: true,
        pointerDirectory: Directory('${workspace.path}/support')
          ..createSync(recursive: true),
      );

      expect(location.choiceIsMissing, isFalse);
      expect(location.source, PortableSource.installed);
    });
  });

  test('the probe file it writes is cleaned up again', () async {
    final folder = Directory('${workspace.path}/daten')..createSync();

    await resolvePortableLocation(
      environment: {portableEnvironmentVariable: folder.path},
      executablePath: unpacked(depth: 0, withDataFolder: false),
    );

    expect(folder.listSync(), isEmpty);
  });
}
