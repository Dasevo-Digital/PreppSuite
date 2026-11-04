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

  test('a figure for a field is written as its language writes it (#279)', () {
    expect(localiseDecimal('12.50', 'de'), '12,50');
    expect(localiseDecimal('1.5', 'es'), '1,5');
    expect(localiseDecimal('1.5', 'en'), '1.5');
    expect(localiseDecimal('30', 'de'), '30');
    // And it reads back as it was.
    expect(readMoneyCents(localiseDecimal('12.50', 'de')), 1250);
    expect(readNonNegativeNumber(localiseDecimal('1.5', 'de')), 1.5);
  });
}
