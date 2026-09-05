import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';

/// A [SyncFolder] held in a map, so the merge can be tested without a
/// filesystem — and so several "devices" can share one folder inside a
/// single test.
class InMemorySyncFolder implements SyncFolder {
  final Map<String, String> deviceFiles = {};
  String? householdFile;

  bool writable = true;

  /// How many times a device snapshot has been written. The tests use it
  /// to assert that a quiet run really is quiet: every write here would
  /// be an upload and a wake-up on every other device.
  int deviceWrites = 0;

  @override
  Future<bool> isWritable() async => writable;

  @override
  Future<List<String>> listDeviceIds() async => deviceFiles.keys.toList();

  @override
  Future<String?> readDeviceFile(String deviceId) async =>
      deviceFiles[deviceId];

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) async {
    deviceWrites++;
    deviceFiles[deviceId] = contents;
  }

  @override
  Future<String?> readHouseholdFile() async => householdFile;

  @override
  Future<void> writeHouseholdFile(String contents) async {
    householdFile = contents;
  }
}
