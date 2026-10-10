/// The built-in lists in the reader's language (#108).
///
/// The built-in templates are seeded in German, and once a row is in the
/// database it is the household's: they tick it, delete it, and on a
/// shared folder another device merges it. Rewriting those rows in the
/// reader's language would be an edit nobody made -- and two devices in
/// two languages would rewrite each other's rows on every sync.
///
/// So the translation happens on the way to the screen and never in the
/// database. A row whose text is still exactly what `built_in_templates.dart`
/// ships is shown in the reader's language; a row somebody changed, or one
/// still carrying an older wording than the one shipped now, is shown as
/// it stands. Nothing is written, so the merge has nothing to argue about,
/// and switching the language back shows the German rows untouched.
library;

import '../../../local_db/database.dart';
import 'built_in_templates.dart';
import 'built_in_templates_en.dart';
import 'built_in_templates_es.dart';

/// Every shipped German text, by clientId.
final Map<String, String> _shippedGerman = {
  for (final template in builtInTemplates) ...{
    template.clientId: template.title,
    for (final item in template.items) item.clientId: item.title,
  },
};

const _translations = <String, Map<String, String>>{
  'en': builtInChecklistsEn,
  'es': builtInChecklistsEs,
};

/// [stored] in [languageCode], when the row behind [clientId] is a
/// built-in one still saying what was shipped; otherwise [stored].
///
/// German, and any language without a translation, is always [stored]:
/// the rows are German already, and for a reader of a language nobody
/// translated German is what the rest of the app's content falls back to
/// as well.
String builtInChecklistText(
  String clientId,
  String stored,
  String languageCode,
) {
  final translations = _translations[languageCode];
  if (translations == null) return stored;
  if (_shippedGerman[clientId] != stored) return stored;
  return translations[clientId] ?? stored;
}

extension ChecklistTemplateText on ChecklistTemplate {
  /// The title as the reader should see it; see [builtInChecklistText].
  String titleIn(String languageCode) =>
      builtInChecklistText(clientId, title, languageCode);
}

extension ChecklistItemText on ChecklistItem {
  /// The text as the reader should see it; see [builtInChecklistText].
  String titleIn(String languageCode) =>
      builtInChecklistText(clientId, title, languageCode);
}
