/// "+49 (0)171 2345678" as it is written in Germany, without the "(0)"
/// (#251).
///
/// The bracketed zero is the trunk prefix: dialled from inside the country
/// and never after the country code. Kept, the number became
/// "+4901712345678", which reaches nobody -- from a call button on an
/// emergency card, or as the recipient of a sign of life. Only removed
/// where a country code comes first: "(0531) 4700" is a national number
/// with its area code in brackets and keeps every digit.
String withoutTrunkPrefix(String number) {
  final trimmed = number.trim();
  if (!trimmed.startsWith('+') && !trimmed.startsWith('00')) return trimmed;
  return trimmed.replaceFirst(RegExp(r'\(\s*0\s*\)'), '');
}
