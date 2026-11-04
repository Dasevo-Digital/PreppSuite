import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/name_order.dart';

/// Names in the order a person looks them up in (#283).
void main() {
  List<String> sorted(List<String> names) => sortedByName(names, (n) => n);

  test('umlauts and capitals no longer go to the end', () {
    // What `compareTo` made of it: apfelmus, Nudeln, Zucker, Äpfel, Öl,
    // Übertopf.
    expect(
      sorted(['Zucker', 'Öl', 'apfelmus', 'Übertopf', 'Nudeln', 'Äpfel']),
      [
        'Äpfel',
        'apfelmus',
        'Nudeln',
        'Öl',
        'Übertopf',
        'Zucker',
      ],
    );
  });

  test('ß is ss, and the accents of the other languages drop away', () {
    expect(nameSortKey('Maßband'), 'massband');
    expect(nameSortKey('  Crème fraîche '), 'creme fraiche');
    expect(nameSortKey('Café'), nameSortKey('cafe'));
    expect(sorted(['Muskat', 'Müsli', 'Mus']), ['Mus', 'Muskat', 'Müsli']);
  });

  test('ñ is a letter of its own, after n and before o', () {
    expect(sorted(['pino', 'piña', 'pinza', 'pizza']), [
      'pino',
      'pinza',
      'piña',
      'pizza',
    ]);
    expect(sorted(['ñame', 'nuez', 'oca']), ['nuez', 'ñame', 'oca']);
  });

  test('marks written as characters of their own fold the same way', () {
    // "Äpfel" and "piña" as macOS writes a file name: letter, then mark.
    expect(nameSortKey('Äpfel'), nameSortKey('Äpfel'));
    expect(nameSortKey('piña'), nameSortKey('piña'));
  });

  test('names that fold alike still come out in one fixed order', () {
    expect(sorted(['müsli', 'Müsli', 'Musli']), ['Musli', 'Müsli', 'müsli']);
    expect(compareNames('Müsli', 'müsli'), lessThan(0));
    expect(compareNames('Öl', 'Öl'), 0);
  });
}
