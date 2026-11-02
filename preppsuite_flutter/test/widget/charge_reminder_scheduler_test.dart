import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/charge_reminder_scheduler.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The household's equipment check while nobody has confirmed one (#244).
void main() {
  const chargeReminderId = 90407;

  /// Starts the scheduler as a start of the app does, and answers what it
  /// left pending under the equipment check's id.
  Future<DateTime?> scheduledOnStart(WidgetTester tester) async {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    DateTime? fireAt;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'zonedSchedule':
          final arguments = Map<String, dynamic>.from(call.arguments as Map);
          if (arguments['id'] == chargeReminderId) {
            fireAt = DateTime.parse(
              arguments['scheduledDateTimeISO8601'] as String,
            ).toLocal();
          }
          return null;
        case 'cancel':
          if ((call.arguments as Map)['id'] == chargeReminderId) fireAt = null;
          return null;
        case 'pendingNotificationRequests':
          return const <Object>[];
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ChargeReminderScheduler()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    return fireAt;
  }

  DateTime atTen(DateTime day, int plusDays) =>
      DateTime(day.year, day.month, day.day + plusDays, 10);

  testWidgets('a first start counts the interval from today and keeps that '
      'start', (tester) async {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    final today = DateTime.now();

    expect(await scheduledOnStart(tester), atTen(today, 90));

    final prefs = await SharedPreferences.getInstance();
    final kept = DateTime.parse(
      prefs.getString('chargeReminderCountingSince')!,
    ).toLocal();
    expect(DateUtils.dateOnly(kept), DateUtils.dateOnly(today));
  });

  testWidgets('a later start counts from the kept start, not from today '
      'again', (tester) async {
    final today = DateTime.now();
    final started = DateTime(today.year, today.month, today.day - 30, 8);
    SharedPreferences.setMockInitialValues({
      'notificationsEnabled': true,
      'chargeReminderCountingSince': started.toUtc().toIso8601String(),
    });

    // Sixty days from now, which is ninety from the start -- not ninety
    // from today, which is where every start of the app used to put it.
    expect(await scheduledOnStart(tester), atTen(started, 90));
  });

  testWidgets('an interval that has run out without a check is tomorrow '
      'morning', (tester) async {
    final today = DateTime.now();
    final started = DateTime(today.year, today.month, today.day - 120);
    SharedPreferences.setMockInitialValues({
      'notificationsEnabled': true,
      'chargeReminderCountingSince': started.toUtc().toIso8601String(),
    });

    expect(await scheduledOnStart(tester), atTen(today, 1));
  });

  testWidgets('a confirmed check counts from the check', (tester) async {
    final today = DateTime.now();
    final checked = DateTime(today.year, today.month, today.day - 10, 18);
    final started = DateTime(today.year, today.month, today.day - 80);
    SharedPreferences.setMockInitialValues({
      'notificationsEnabled': true,
      'chargeReminderLastChecked': checked.toUtc().toIso8601String(),
      'chargeReminderCountingSince': started.toUtc().toIso8601String(),
    });

    expect(await scheduledOnStart(tester), atTen(checked, 90));
  });

  testWidgets('switching the reminder off forgets the start', (tester) async {
    final today = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'notificationsEnabled': true,
      'chargeReminderDays': 0,
      'chargeReminderCountingSince': DateTime(
        today.year,
        today.month,
        today.day - 200,
      ).toUtc().toIso8601String(),
    });

    expect(await scheduledOnStart(tester), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('chargeReminderCountingSince'), isNull);
  });
}
