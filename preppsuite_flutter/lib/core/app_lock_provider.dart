import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock.dart';

class AppLockController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => AppLockStore().isEnabled();

  Future<void> enable(String passphrase) async {
    await AppLockStore().enable(passphrase);
    state = const AsyncData(true);
  }

  Future<void> disable() async {
    await AppLockStore().disable();
    state = const AsyncData(false);
  }
}

final appLockProvider = AsyncNotifierProvider<AppLockController, bool>(
  AppLockController.new,
);
