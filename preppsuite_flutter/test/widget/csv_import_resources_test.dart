import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_csv_import_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

base class _File extends PlatformFile {
  _File(this.bytes);
  final Uint8List bytes;
  @override
  String get name => 'stock.csv';
  @override
  Uri get uri => Uri.parse('file:///stock.csv');
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => bytes.length;
  @override
  Future<int?> length() async => throw StateError('No eager size probe');
  @override
  Future<Uint8List> readAsBytes() async => throw StateError('No eager read');
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

class _Picker extends Fake
    with MockPlatformInterfaceMixin
    implements FilePickerPlatform {
  _Picker(this.file);
  final PlatformFile file;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #pickFile) {
      return Future<PlatformFile?>.value(file);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  testWidgets('large previews build only visible rows and use streaming reads', (
    tester,
  ) async {
    final previous = FilePickerPlatform.instance;
    addTearDown(() => FilePickerPlatform.instance = previous);
    FilePickerPlatform.instance = _Picker(
      _File(
        Uint8List.fromList(
          utf8.encode(
            'name,category,quantity,unit,storageLocation\n${List.generate(2000, (i) => 'Article$i,food,1,kg,box').join('\n')}',
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InventoryCsvImportScreen(householdId: 'test'),
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InventoryCsvImportScreen)),
    )!;
    await tester.ensureVisible(find.text(l10n.csvImportPickFileButton));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.csvImportPickFileButton));
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.csvImportSummary(2000, 2000)),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .join(' | '),
    );
    expect(find.text('Article1999'), findsNothing);
    expect(find.byType(ListTile).evaluate().length, lessThan(30));
    expect(tester.takeException(), isNull);
  });
}
