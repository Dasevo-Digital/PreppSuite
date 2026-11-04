/// Household amounts must be finite and non-negative on every input path.
bool isNonNegativeFinite(double value) => value.isFinite && value >= 0;

double? readNonNegativeNumber(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  return value != null && isNonNegativeFinite(value) ? value : null;
}

/// [text], a number written with a decimal point, with the decimal comma
/// where the language of [localeName] writes one (#279): what goes into
/// a field the household types over. No thousands separator, which a
/// reader would take for a decimal point; [readNonNegativeNumber] reads
/// either mark back. The forms put "1.5" and "12.50" in front of a German
/// reader, who writes "1,5" and saw "1,5" everywhere else in the app.
String localiseDecimal(String text, String localeName) =>
    localeName.startsWith('en') ? text : text.replaceAll('.', ',');

/// The most a money field takes, in whole units of its currency.
///
/// A billion is more than any household spends on one thing, and in cents
/// it is far inside the range an `int` and a JSON number both hold
/// exactly, so neither a total nor the snapshot can lose a digit.
const maximumMoneyAmount = 1000000000;

/// A price or an amount as typed, in cents: with a decimal comma or a
/// point, finite, not negative and at most [maximumMoneyAmount]. Null
/// for anything else (#245).
///
/// The budget read its amount with `double.tryParse` alone, which takes
/// no comma, so "12,50" from a German keyboard was "not a number"; and
/// both money forms let "Infinity" or "1e400" through to a `round()`
/// that throws, which ended the save half way.
int? readMoneyCents(String raw) {
  final value = readNonNegativeNumber(raw);
  if (value == null || value > maximumMoneyAmount) return null;
  return (value * 100).round();
}
