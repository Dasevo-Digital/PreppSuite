import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// The built-in lists are seeded by `clientId` and merged across devices by
/// it, so a duplicate or a malformed one would not fail loudly — it would
/// quietly drop a list, or overwrite one somebody had ticked off.
void main() {
  test('every id is a well-formed UUID and appears once', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    final ids = <String>[];
    for (final template in builtInTemplates) {
      ids.add(template.clientId);
      ids.addAll(template.items.map((item) => item.clientId));
    }

    for (final id in ids) {
      expect(pattern.hasMatch(id), isTrue, reason: id);
    }
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('no list is empty and no title is', () {
    for (final template in builtInTemplates) {
      expect(template.items, isNotEmpty, reason: template.title);
      expect(template.title.trim(), isNotEmpty);
      for (final item in template.items) {
        expect(item.title.trim(), isNotEmpty, reason: template.title);
      }
    }
  });

  /// The branches BBK's own Vorsorge guide runs, checked as a set rather
  /// than by title: the point is that none of them is missing again.
  test('the natural hazards, shelter and wellbeing branches are covered', () {
    final categories = builtInTemplates.map((t) => t.category).toSet();

    expect(categories, contains(ChecklistCategory.hazards));
    expect(categories, contains(ChecklistCategory.wellbeing));
    expect(categories, contains(ChecklistCategory.safety));

    final hazards = builtInTemplates
        .where((t) => t.category == ChecklistCategory.hazards)
        .map((t) => t.title)
        .toList();

    // Flood, heat and storm/cold — the three the guide separates.
    expect(hazards, hasLength(3));
  });
}
