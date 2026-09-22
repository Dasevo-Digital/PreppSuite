import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/settings_sync.dart';

/// Keeping the household's settings in step without a device shouting
/// over another one.
void main() {
  final monday = DateTime.utc(2026, 9, 21, 9);
  final tuesday = DateTime.utc(2026, 9, 22, 9);

  group('stamping on publish', () {
    test('a value that has not moved keeps the time it had', () {
      final previous = {'pegelStation': (value: 'DRESDEN', at: monday)};

      final stamped = stampSettings(
        current: {'pegelStation': 'DRESDEN'},
        previous: previous,
        now: tuesday,
      );

      expect(stamped['pegelStation']!.at, monday);
    });

    test('a value that changed carries the moment it went out', () {
      final stamped = stampSettings(
        current: {'pegelStation': 'MAGDEBURG'},
        previous: {'pegelStation': (value: 'DRESDEN', at: monday)},
        now: tuesday,
      );

      expect(stamped['pegelStation']!.value, 'MAGDEBURG');
      expect(stamped['pegelStation']!.at, tuesday);
    });

    test('a value nobody holds any more is dropped', () {
      // A setting that has been cleared is not a setting to argue over.
      final stamped = stampSettings(
        current: const {},
        previous: {'pegelStation': (value: 'DRESDEN', at: monday)},
        now: tuesday,
      );

      expect(stamped, isEmpty);
    });

    test('a list is compared by contents, not by identity', () {
      // JSON gives a string list back as List<dynamic>. Comparing with
      // == would call that a change, restamp it, and start two devices
      // that agree arguing with each other.
      final stamped = stampSettings(
        current: {
          'energyDraws': <String>['a', 'b'],
        },
        previous: {
          'energyDraws': (value: <dynamic>['a', 'b'], at: monday),
        },
        now: tuesday,
      );

      expect(stamped['energyDraws']!.at, monday);
    });
  });

  group('merging', () {
    test('the later change wins', () {
      final merged = mergeSettings(
        local: {'pegelStation': (value: 'DRESDEN', at: monday)},
        incoming: {'pegelStation': (value: 'MAGDEBURG', at: tuesday)},
      );

      expect(merged['pegelStation']!.value, 'MAGDEBURG');
    });

    test('an older one is ignored, however often it arrives', () {
      final local = {'pegelStation': (value: 'MAGDEBURG', at: tuesday)};
      final incoming = {'pegelStation': (value: 'DRESDEN', at: monday)};

      expect(
        mergeSettings(local: local, incoming: incoming)['pegelStation']!.value,
        'MAGDEBURG',
      );
      expect(
        mergeSettings(
          local: mergeSettings(local: local, incoming: incoming),
          incoming: incoming,
        )['pegelStation']!.value,
        'MAGDEBURG',
      );
    });

    test('a tie stays where it is', () {
      // The ordinary case: both sides carrying the same value since the
      // floor. Moving on a tie would make the answer depend on who
      // happened to speak last.
      final merged = mergeSettings(
        local: {'pegelStation': (value: 'DRESDEN', at: settingsEpoch)},
        incoming: {'pegelStation': (value: 'MAGDEBURG', at: settingsEpoch)},
      );

      expect(merged['pegelStation']!.value, 'DRESDEN');
    });

    test('something only the other side has is taken', () {
      final merged = mergeSettings(
        local: const {},
        incoming: {'radiationStation': (value: 'BS', at: monday)},
      );

      expect(merged['radiationStation']!.value, 'BS');
    });
  });

  group('the floor', () {
    test('two devices that upgrade on the same day do not fight', () {
      // Both start at the floor, so neither overwrites the other until
      // somebody actually changes something.
      final phone = stampSettings(
        current: {'pegelStation': 'DRESDEN'},
        previous: {'pegelStation': (value: 'DRESDEN', at: settingsEpoch)},
        now: monday,
      );
      final desktop = stampSettings(
        current: {'pegelStation': 'DRESDEN'},
        previous: {'pegelStation': (value: 'DRESDEN', at: settingsEpoch)},
        now: tuesday,
      );

      expect(phone['pegelStation']!.at, settingsEpoch);
      expect(desktop['pegelStation']!.at, settingsEpoch);
      expect(
        mergeSettings(local: phone, incoming: desktop)['pegelStation']!.at,
        settingsEpoch,
      );
    });

    test('and the first real change beats both of them', () {
      final changed = stampSettings(
        current: {'pegelStation': 'MAGDEBURG'},
        previous: {'pegelStation': (value: 'DRESDEN', at: settingsEpoch)},
        now: monday,
      );

      expect(
        mergeSettings(
          local: {'pegelStation': (value: 'DRESDEN', at: settingsEpoch)},
          incoming: changed,
        )['pegelStation']!.value,
        'MAGDEBURG',
      );
    });
  });

  group('writing back only what moved', () {
    test('a merge that changed nothing touches nothing', () {
      expect(
        changedBy(
          current: {'pegelStation': 'DRESDEN'},
          merged: {'pegelStation': (value: 'DRESDEN', at: tuesday)},
        ),
        isEmpty,
      );
    });

    test('and one that did names only that', () {
      expect(
        changedBy(
          current: {'pegelStation': 'DRESDEN', 'expiryLeadDays': 7},
          merged: {
            'pegelStation': (value: 'MAGDEBURG', at: tuesday),
            'expiryLeadDays': (value: 7, at: tuesday),
          },
        ),
        {'pegelStation': 'MAGDEBURG'},
      );
    });
  });

  group('crossing the wire', () {
    test('a stamped set survives being written out and read back', () {
      final settings = {
        'pegelStation': (value: 'DRESDEN', at: monday),
        'expiryLeadDays': (value: 7, at: tuesday),
        'energyDraws': (value: <String>['a', 'b'], at: monday),
      };

      final there = decodeStampedSettings(
        encodeStampedSettings(settings),
      );

      expect(there['pegelStation']!.value, 'DRESDEN');
      expect(there['expiryLeadDays']!.value, 7);
      expect(there['energyDraws']!.value, ['a', 'b']);
      expect(there['pegelStation']!.at, monday);
    });

    test('one unreadable entry costs that entry and no more', () {
      // The far side may be a newer or an older version of the app, and
      // a sync must not fail over a setting.
      final there = decodeStampedSettings({
        'good': {'v': 'ja', 'at': monday.toIso8601String()},
        'noTime': {'v': 'ja'},
        'noValue': {'at': monday.toIso8601String()},
        'nonsense': 42,
      });

      expect(there.keys, ['good']);
    });

    test('and anything that is not a set at all is empty', () {
      expect(decodeStampedSettings(null), isEmpty);
      expect(decodeStampedSettings('nope'), isEmpty);
    });
  });
}
