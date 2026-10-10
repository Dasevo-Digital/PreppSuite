import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_text.dart';
import '../../../core/save_file.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/shopping_list_export.dart';

/// Hands a shopping file on (#155, #149).
///
/// On a phone through the share sheet, which offers "Save to Files" and
/// any app that takes the file. On a computer there is no such sheet on
/// every system, so the save dialog asks where it goes.
Future<void> shareShoppingFile(
  BuildContext context, {
  required String content,
  required DateTime now,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final name = shoppingListFileName(now);
  try {
    if (Platform.isIOS || Platform.isAndroid) {
      final file = File(
        '${(await getTemporaryDirectory()).path}'
        '${Platform.pathSeparator}$name',
      );
      await file.writeAsString(content, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: l10n.shoppingListTitle,
        ),
      );
      return;
    }
    final saved = await saveFileWithPicker(
      dialogTitle: l10n.shoppingListExportDialogTitle,
      fileName: name,
      extension: 'json',
      bytes: utf8.encode(content),
    );
    if (!saved) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.shoppingListExported)));
  } on Object catch (error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.csvExportErrorMessage} ${describeError(l10n, error)}',
          ),
        ),
      );
  }
}
