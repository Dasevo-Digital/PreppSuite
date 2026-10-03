import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/item_package.dart';

void main() {
  group('a package', () {
    test('needs both a name and a size above zero', () {
      expect(ItemPackage.from('Glas', 370), isNotNull);
      expect(ItemPackage.from('  ', 370), isNull);
      expect(ItemPackage.from(null, 370), isNull);
      expect(ItemPackage.from('Glas', null), isNull);
      expect(ItemPackage.from('Glas', 0), isNull);
      expect(ItemPackage.from('Glas', -1), isNull);
      expect(ItemPackage.from('Glas', double.nan), isNull);
    });

    test('keeps the name as typed, without the spaces around it', () {
      expect(ItemPackage.from(' Dose ', 400)!.name, 'Dose');
    });

    test('converts both ways', () {
      const jar = ItemPackage(name: 'Glas', size: 370);
      expect(jar.toUnits(2), 740);
      expect(jar.toPackages(185), 0.5);
    });
  });

  group('how many packages a stock is', () {
    const jar = ItemPackage(name: 'Glas', size: 370);

    test('whole jars are exact', () {
      expect(packageCount(1110, jar), (count: 3.0, exact: true));
    });

    test('anything else is rounded to one decimal and says so', () {
      expect(packageCount(1000, jar), (count: 2.7, exact: false));
    });

    test('a half jar that is exactly half is exact', () {
      expect(packageCount(185, jar), (count: 0.5, exact: true));
    });
  });
}
