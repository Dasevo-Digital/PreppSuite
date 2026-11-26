import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_day.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_day_scheduler.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The reminder for Germany's warning day, and only Germany's (#396).
void main() {
  const warningDayId = 90408;

  /// What the scheduler left planned under the warning day's id: the
  /// moment, or null when it cancelled or never planned one.
  late DateTime? planned;
  late bool cancelled;

  setUp(() {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    planned = null;
    cancelled = false;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'zonedSchedule':
          final arguments = Map<String, dynamic>.from(call.arguments as Map);
          if (arguments['id'] == warningDayId) {
            planned = DateTime.parse(
              arguments['scheduledDateTimeISO8601'] as String,
            ).toLocal();
          }
          return null;
        case 'cancel':
          if ((call.arguments as Map)['id'] == warningDayId) {
            planned = null;
            cancelled = true;
          }
          return null;
        case 'pendingNotificationRequests':
          return const <Object>[];
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  });

  Widget app(String countryCode) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WarningDayScheduler(countryCode: countryCode)),
    ),
  );

  /// Nine on the next warning day, or null on the day itself after nine,
  /// when there is nothing left to remind of.
  DateTime? nineOnTheDay() {
    final day = nextFederalWarningDay();
    final nine = DateTime(day.year, day.month, day.day, 9);
    return nine.isAfter(DateTime.now()) ? nine : null;
  }

  testWidgets('a household in Germany is reminded', (tester) async {
    await tester.pumpWidget(app('DE'));
    await tester.pumpAndSettle();

    expect(planned, nineOnTheDay());
  });

  testWidgets('a household elsewhere is not, and anything planned goes', (
    tester,
  ) async {
    await tester.pumpWidget(app('AT'));
    await tester.pumpAndSettle();

    expect(planned, isNull);
    expect(cancelled, isTrue);
  });

  testWidgets('moving out of Germany takes the reminder back', (tester) async {
    await tester.pumpWidget(app('DE'));
    await tester.pumpAndSettle();
    cancelled = false;

    await tester.pumpWidget(app('CH'));
    await tester.pumpAndSettle();

    expect(planned, isNull);
    expect(cancelled, isTrue);
  });
}
