import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/model/household_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The undo behind a failed join during first-run setup.
///
/// The gate lets the app through as soon as a profile exists. A join that
/// created one and then could not attach it to the folder would leave
/// somebody inside a household with a fresh id — one that can never merge
/// with the household they were trying to join, and no screen that says
/// so. Clearing it puts them back on the choice screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const store = HouseholdProfileStore();

  test('a stored profile can be taken back', () async {
    await store.save(
      const HouseholdProfile(
        id: 'household-1',
        name: 'Familie Muster',
        countryCode: 'DE',
      ),
    );
    expect((await store.load())?.name, 'Familie Muster');

    await store.clear();

    expect(await store.load(), isNull);
  });

  test('clearing a profile that was never there is not an error', () async {
    await store.clear();
    expect(await store.load(), isNull);
  });
}
