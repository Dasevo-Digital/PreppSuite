import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/bounded_input.dart';
import 'package:preppsuite_flutter/core/worker_job.dart';
import 'package:preppsuite_flutter/core/resource_limits.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_csv_import.dart';
import 'package:preppsuite_flutter/features/maps/application/place_exchange.dart';

int _busy(SendPort port) {
  while (true) {
    port.send(1);
    sleep(const Duration(milliseconds: 10));
  }
}

int _answer(int value) => value + 1;
int _fail(int value) => throw const FormatException('invalid');

void main() {
  test('actual chunks are bounded and the reader is cancelled', () async {
    var aborted = false;
    var cancelled = false;
    final source = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    final reading = readBoundedBytes(
      source.stream,
      maxBytes: 4,
      onAbort: () => aborted = true,
    );
    final check = expectLater(reading, throwsA(isA<InputTooLarge>()));
    source.add([1, 2, 3]);
    source.add([4, 5]);
    await check;
    expect(aborted && cancelled, isTrue);
    await source.close();
  });
  test('declared size rejected without subscribing', () async {
    var listened = false;
    final source = StreamController<List<int>>(onListen: () => listened = true);
    await expectLater(
      readBoundedBytes(source.stream, maxBytes: 4, declaredLength: 5),
      throwsA(isA<InputTooLarge>()),
    );
    expect(listened, isFalse);
  });
  test('silent readers stop on cancellation and deadline', () async {
    for (final cancel in [true, false]) {
      var stopped = false;
      final source = StreamController<List<int>>(
        onCancel: () => stopped = true,
      );
      final token = CancellationToken();
      final reading = readBoundedBytes(
        source.stream,
        maxBytes: 4,
        cancellation: token,
        timeout: const Duration(milliseconds: 10),
      );
      final check = expectLater(
        reading,
        throwsA(cancel ? isA<OperationCancelled>() : isA<TimeoutException>()),
      );
      if (cancel) token.cancel();
      await check;
      expect(stopped, isTrue);
      await source.close();
    }
  });
  test('worker results and errors cross the isolate boundary', () async {
    expect(await runInWorker(2, _answer), 3);
    await expectLater(runInWorker(2, _fail), throwsA(isA<FormatException>()));
  });
  test('cancellation kills a worker that never yields', () async {
    final port = ReceivePort();
    final token = CancellationToken();
    var beats = 0;
    final sub = port.listen((_) {
      beats++;
      token.cancel();
    });
    await expectLater(
      runInWorker(port.sendPort, _busy, cancellation: token),
      throwsA(isA<OperationCancelled>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final stopped = beats;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(beats, stopped);
    expect(beats, greaterThan(0));
    await sub.cancel();
    port.close();
  });
  test('worker deadline kills a noncooperative computation', () async {
    final port = ReceivePort();
    await expectLater(
      runInWorker(
        port.sendPort,
        _busy,
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
    port.close();
  });
  test('expensive KDF parameters rejected before deriving', () async {
    final valid = VaultParameters(salt: Uint8List(16));
    expect(VaultParameters.fromJson(valid.toJson()), isNotNull);
    expect(
      VaultParameters.fromJson(VaultParameters.testing.toJson()),
      isNotNull,
    );
    for (final change in [
      {'memory': 1048576},
      {'iterations': 64},
      {'parallelism': 16},
      {'memory': 131072, 'iterations': 6},
      {'salt': 'AA==' * 100},
    ]) {
      expect(VaultParameters.fromJson({...valid.toJson(), ...change}), isNull);
    }
    await expectLater(
      deriveFolderKey(
        'test',
        VaultParameters(salt: Uint8List(16), memory: 1048576),
      ),
      throwsA(isA<FormatException>()),
    );
    final token = CancellationToken()..cancel();
    await expectLater(
      deriveFolderKey('test', VaultParameters.testing, cancellation: token),
      throwsA(isA<OperationCancelled>()),
    );
  });
  test('CSV rejects nonfinite numbers and impossible dates', () {
    for (final number in ['Infinity', '-Infinity', 'NaN', '1e999', '-1']) {
      expect(parseCsvNumber(number), isNull);
    }
    expect(parseCsvNumber('2,5'), 2.5);
    for (final date in [
      '31.02.2027',
      '2027-02-31',
      '29.02.2027',
      '32.01.2027',
    ]) {
      expect(parseCsvDate(date), isNull, reason: date);
    }
    expect(parseCsvDate('29.02.2028'), DateTime(2028, 2, 29));
  });
  test('CSV and XML have byte, row and nesting budgets', () {
    expect(
      () => parseInventoryCsv('x' * (maxImportBytes + 1)),
      throwsA(isA<InputTooLarge>()),
    );
    expect(
      () => parseInventoryCsv(
        'name,category,quantity,unit,storageLocation\n'
        '${'a,food,1,kg,box\n' * (maxImportRows + 1)}',
      ),
      throwsA(isA<InputTooLarge>()),
    );
    expect(
      () => placesFromXml(
        '<gpx>${'<wpt lat="1" lon="2"/>' * (maxImportRows + 1)}</gpx>',
      ),
      throwsA(isA<InputTooLarge>()),
    );
    expect(
      () => placesFromXml('${'<a>' * 65}${'</a>' * 65}'),
      throwsA(isA<InputTooLarge>()),
    );
    expect(
      () => placesFromXml('<!DOCTYPE gpx [<!ENTITY a "x">]><gpx/>'),
      throwsA(isA<InputTooLarge>()),
    );
  });
}
