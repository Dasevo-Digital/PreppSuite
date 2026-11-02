import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/number_input.dart';

/// Prices and amounts as people type them (#245).
void main() {
  test('a decimal comma and a point both read', () {
    expect(readMoneyCents('12,50'), 1250);
    expect(readMoneyCents('12.50'), 1250);
    expect(readMoneyCents(' 3,5 '), 350);
    expect(readMoneyCents('0'), 0);
  });

  test('cents are rounded, not cut off', () {
    expect(readMoneyCents('0,295'), 30);
    expect(readMoneyCents('19,99'), 1999);
  });

  test('nothing infinite, negative or absurd gets through', () {
    for (final typed in [
      '',
      'zwölf',
      '1e400',
      'Infinity',
      '-Infinity',
      'NaN',
      '-5',
      '1.000,50',
    ]) {
      expect(readMoneyCents(typed), isNull, reason: typed);
    }
  });

  test('the ceiling is a billion, and inside an exact JSON number', () {
    expect(readMoneyCents('$maximumMoneyAmount'), maximumMoneyAmount * 100);
    expect(readMoneyCents('${maximumMoneyAmount + 1}'), isNull);
    expect(maximumMoneyAmount * 100, lessThan(1 << 53));
  });
}
