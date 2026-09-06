import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/german_states.dart';

void main() {
  group('german states', () {
    test('every state is found again by its own BBK code', () {
      for (final state in germanStates) {
        expect(
          germanStateByBbkCode(state.bbkCode),
          same(state),
          reason: state.nameDe,
        );
      }
    });

    test('every state is found again by a Kreisschlüssel of its own', () {
      for (final state in germanStates) {
        expect(
          germanStateForKreisSchluessel('${state.arsPrefix}000'),
          same(state),
          reason: state.nameDe,
        );
      }
    });

    // The settings dialog used to ask for a Bundesland in the field meant
    // for a Kreisschlüssel and rejected every answer: a state is two
    // digits ("03" for Niedersachsen) or two letters ("NI"), never the
    // five digits that field validates.
    test('no state identifier passes as a Kreisschlüssel', () {
      final fiveDigits = RegExp(r'^\d{5}$');
      for (final state in germanStates) {
        expect(fiveDigits.hasMatch(state.arsPrefix), isFalse);
        expect(fiveDigits.hasMatch(state.bbkCode), isFalse);
      }
    });

    test('the sixteen states have distinct codes', () {
      expect(germanStates, hasLength(16));
      expect(
        {for (final state in germanStates) state.bbkCode},
        hasLength(16),
      );
      expect(
        {for (final state in germanStates) state.arsPrefix},
        hasLength(16),
      );
    });
  });
}
