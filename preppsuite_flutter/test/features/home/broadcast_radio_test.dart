import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/broadcast_radio.dart';
import 'package:preppsuite_flutter/features/household/application/german_states.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The radio programmes to tune to without the internet (#267).
void main() {
  group('the table', () {
    test('every Land has its programmes', () {
      for (final state in germanStates) {
        expect(
          broadcastProgrammesByState[state.bbkCode],
          isNotEmpty,
          reason: state.nameDe,
        );
      }
      expect(broadcastProgrammesByState.keys.toSet(), {
        for (final state in germanStates) state.bbkCode,
      });
    });

    test('each Land has its own state programme first', () {
      for (final MapEntry(key: state, value: programmes)
          in broadcastProgrammesByState.entries) {
        expect(programmes.first.role, BroadcastRole.state, reason: state);
      }
    });

    test('an id names one programme, wherever it is listed', () {
      final names = <String, String>{};
      for (final programme in [
        for (final list in broadcastProgrammesByState.values) ...list,
        deutschlandfunk,
      ]) {
        expect(
          names.putIfAbsent(programme.id, () => programme.name),
          programme.name,
          reason: programme.id,
        );
        expect(Uri.parse(programme.website).scheme, 'https');
      }
    });

    test('SWR Aktuell is on UKW only in Stuttgart', () {
      final swr = broadcastProgrammesByState['BW']!.firstWhere(
        (programme) => programme.id == 'swr-aktuell',
      );
      expect(swr.ukwOnlyIn, 'Stuttgart');
    });
  });

  group('a UKW frequency', () {
    test('as typed, with a comma or a point', () {
      expect(parseUkwFrequency('95,6'), 95.6);
      expect(parseUkwFrequency('101.35'), 101.35);
      expect(parseUkwFrequency(' 87,5 '), 87.5);
      expect(parseUkwFrequency('108'), 108);
    });

    test('outside the band, off the grid, or no number at all', () {
      for (final input in [
        '87,4',
        '108,05',
        '95,63',
        '1450',
        'NaN',
        'Infinity',
        '',
        'NDR',
      ]) {
        expect(parseUkwFrequency(input), isNull, reason: input);
      }
    });
  });

  group('the household\'s frequencies', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('travel with the household, always', () {
      expect(
        carriedSettings[BroadcastFrequencyStore.key],
        (kind: CarriedKind.text, when: CarriedWhen.always),
      );
    });

    test('are set and removed on what is stored', () async {
      const store = BroadcastFrequencyStore();
      await store.set('ndr1-niedersachsen', 95.6);
      // Another device's frequency arrives between two edits here.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        BroadcastFrequencyStore.key,
        '{"ndr1-niedersachsen": 95.6, "deutschlandfunk": 101.6}',
      );

      expect(await store.set('ndr-info', 92.2), {
        'ndr1-niedersachsen': 95.6,
        'deutschlandfunk': 101.6,
        'ndr-info': 92.2,
      });
      await store.set('ndr-info', null);
      await store.set('ndr1-niedersachsen', null);
      expect(await store.load(), {'deutschlandfunk': 101.6});
      await store.set('deutschlandfunk', null);
      expect(prefs.getString(BroadcastFrequencyStore.key), isNull);
    });

    test('anything unreadable in what arrived is left out', () async {
      SharedPreferences.setMockInitialValues({
        BroadcastFrequencyStore.key:
            '{"a": 95.6, "b": 1e400, "c": "95,6", "d": 200, "e": 95.63}',
      });
      expect(await const BroadcastFrequencyStore().load(), {'a': 95.6});
    });
  });
}
