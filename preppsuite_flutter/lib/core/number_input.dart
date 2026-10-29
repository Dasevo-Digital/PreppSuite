/// Household amounts must be finite and non-negative on every input path.
bool isNonNegativeFinite(double value) => value.isFinite && value >= 0;

double? readNonNegativeNumber(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  return value != null && isNonNegativeFinite(value) ? value : null;
}
