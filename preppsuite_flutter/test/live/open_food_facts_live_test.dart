import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/open_food_facts_service.dart';

/// Against the real Open Food Facts. Skipped unless PREPPSUITE_TEST_NETWORK
/// is set. What no fixture shows: whether API 3.5 still answers with the
/// packaging's own set as sold per 100 g.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real Open Food Facts'
      : null;

  test('a well-known spread reads with its label figures', () async {
    OpenFoodFactsService.configure();
    final product = await const OpenFoodFactsService().lookup('4008400402222');
    stdout.writeln('${product?.name}: ${product?.nutrition.kcal} kcal');
    expect(product, isNotNull);
    // 539 kcal and 30.9 g fat per 100 g on the jar when this was written.
    expect(product!.nutrition.kcal, closeTo(539, 30));
    expect(product.nutrition.fatGrams, closeTo(30.9, 3));
  }, skip: reason);
}
