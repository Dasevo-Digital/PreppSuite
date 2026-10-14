import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/tour/application/app_tour.dart';
import 'package:preppsuite_flutter/features/tour/application/app_tour_l10n.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('stops', () {
    test('each opens a destination of its own, and none is the overview', () {
      final destinations = [
        for (final stop in TourStop.values) stop.destination,
      ];
      expect(destinations.toSet(), hasLength(destinations.length));
      expect(destinations, isNot(contains(ShellDestination.overview)));
    });

    for (final locale in AppLocalizations.supportedLocales) {
      test('every text names what its screen labels '
          '(${locale.languageCode})', () {
        final l10n = lookupAppLocalizations(locale);
        for (final stop in TourStop.values) {
          final body = tourStopBody(l10n, stop);
          expect(tourStopTitle(l10n, stop), isNotEmpty);
          for (final anchor in tourStopAnchors(l10n, stop)) {
            expect(
              body,
              contains(anchor),
              reason: '${stop.name} should name "$anchor" by its label',
            );
          }
        }
      });
    }
  });

  group('the tour', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    AppTourController tour() => container.read(appTourProvider.notifier);
    TourStop? at() => container.read(appTourProvider);

    test('is not running until started', () {
      expect(at(), isNull);
    });

    test('goes through every stop in order and then ends', () {
      tour().start();
      final seen = <TourStop>[];
      for (var stop = at(); stop != null; stop = at()) {
        seen.add(stop);
        tour().next();
      }
      expect(seen, TourStop.values);
    });

    test('goes back one stop, and not before the first', () {
      tour().start();
      tour().back();
      expect(at(), TourStop.values.first);
      tour().next();
      tour().next();
      tour().back();
      expect(at(), TourStop.values[1]);
    });

    test('can be ended anywhere', () {
      tour().start();
      tour().next();
      tour().end();
      expect(at(), isNull);
      // And does nothing afterwards until started again.
      tour().next();
      tour().back();
      expect(at(), isNull);
    });

    test('starting it answers the offer, on this device', () async {
      container.listen(tourOfferProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(tourOfferProvider), isTrue);

      tour().start();
      await pumpEventQueue();

      expect(container.read(tourOfferProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('appTourOfferAnswered'), isTrue);
    });
  });
}
