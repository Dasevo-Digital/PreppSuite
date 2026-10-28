import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'personal_document_store.dart';

final _documentChangesProvider = StreamProvider.autoDispose<int>(
  (ref) => PersonalDocumentStore.changes,
);

final personalDocumentsProvider = FutureProvider<List<PersonalDocument>>((ref) {
  ref.watch(_documentChangesProvider);
  return const PersonalDocumentStore().load();
});
