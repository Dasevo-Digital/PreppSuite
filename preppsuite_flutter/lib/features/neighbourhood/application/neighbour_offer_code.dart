/// An offer to the neighbours as it travels: a QR code of plain text (#152).
///
/// **Readable without this app.** Any phone's camera shows a QR code's text,
/// and most neighbours will not have PreppSuite. So the code is not a blob
/// for the app to unpack but the offer itself, in the words and the
/// language of whoever made it, with one line at the end for the app:
///
/// ```text
/// Wasser: 20 l Trinkwasser, abzugeben
/// Kontakt: Haus 4, 2. Stock
/// PreppSuite-Angebot/1 water 2026-10-10
/// ```
///
/// The first line is the kind and the offer, the second -- only if its
/// author gave one -- how to reach them. The labels before the colon are
/// the author's language and the reader does not need them: everything
/// up to the first ": " is dropped, so a German code reads the same in a
/// Spanish app. The last line carries what a label cannot: the format
/// version, the kind as a fixed word, and the day it was offered.
///
/// Nothing else goes in. No household id, no position, nothing from the
/// inventory: what the screen showed is all anybody who films it gets.
library;

/// What an offer is about, for the icon and for sorting a list by it.
/// Deliberately few: the text says what it really is.
enum NeighbourOfferKind { water, food, energy, tools, care, help, other }

/// The kind written as [name], or [NeighbourOfferKind.other] for one this
/// version does not know -- a newer app's kind, read on an older one.
NeighbourOfferKind neighbourOfferKindOf(String name) =>
    NeighbourOfferKind.values.asNameMap()[name] ?? NeighbourOfferKind.other;

/// Long enough for "20 l Trinkwasser, 6 Flaschen, bis Freitag abzuholen",
/// short enough that the code stays small enough for an old phone's camera
/// to read off a screen across a doorway.
const neighbourOfferBodyLimit = 200;
const neighbourOfferContactLimit = 120;

class NeighbourOfferCode {
  const NeighbourOfferCode({
    required this.kind,
    required this.body,
    required this.offeredOn,
    this.contact,
  });

  static const _marker = 'PreppSuite-Angebot';

  /// What this version writes. A code with a higher one is refused with
  /// that said, rather than half read.
  static const version = 1;

  final NeighbourOfferKind kind;
  final String body;
  final String? contact;

  /// A day, not a moment: the code says when, not at what time.
  final DateTime offeredOn;

  /// The text of the QR code, with [kindLabel] and [contactLabel] in the
  /// author's language.
  String encode({required String kindLabel, required String contactLabel}) {
    final day = offeredOn.toUtc();
    final date =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final reach = contact;
    return [
      '$kindLabel: $body',
      if (reach != null && reach.isNotEmpty) '$contactLabel: $reach',
      '$_marker/$version ${kind.name} $date',
    ].join('\n');
  }

  static final _footer = RegExp(
    r'^PreppSuite-Angebot/(\d+) ([a-z]+) (\d{4})-(\d{2})-(\d{2})$',
  );

  /// [raw] read back, or why not.
  static NeighbourOfferDecoded decode(String raw) {
    final lines = [
      for (final line in raw.split(RegExp(r'\r?\n')))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    if (lines.length < 2 || lines.length > 3) {
      return const NotANeighbourOffer();
    }
    final footer = _footer.firstMatch(lines.last);
    if (footer == null) return const NotANeighbourOffer();
    if (int.parse(footer[1]!) > version) return const NeighbourOfferTooNew();

    final offeredOn = DateTime.utc(
      int.parse(footer[3]!),
      int.parse(footer[4]!),
      int.parse(footer[5]!),
    );
    final body = _afterLabel(lines[0]);
    if (body.isEmpty) return const NotANeighbourOffer();
    final contact = lines.length == 3 ? _afterLabel(lines[1]) : null;

    return ReadNeighbourOffer(
      NeighbourOfferCode(
        kind: neighbourOfferKindOf(footer[2]!),
        body: cleanNeighbourOfferText(body, neighbourOfferBodyLimit),
        contact: contact == null || contact.isEmpty
            ? null
            : cleanNeighbourOfferText(contact, neighbourOfferContactLimit),
        offeredOn: offeredOn,
      ),
    );
  }

  /// Everything after the label -- the author's word for "water" or
  /// "contact", in a language the reader may not speak.
  static String _afterLabel(String line) {
    final colon = line.indexOf(': ');
    return (colon < 0 ? line : line.substring(colon + 2)).trim();
  }
}

/// One line, at most [limit] characters: an offer is a line of text, and
/// a line break inside one would read as the next field of the code.
String cleanNeighbourOfferText(String text, int limit) {
  final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return line.length <= limit ? line : line.substring(0, limit).trimRight();
}

sealed class NeighbourOfferDecoded {
  const NeighbourOfferDecoded();
}

class ReadNeighbourOffer extends NeighbourOfferDecoded {
  const ReadNeighbourOffer(this.offer);

  final NeighbourOfferCode offer;
}

/// Some other QR code: a link, a household transfer, a ticket.
class NotANeighbourOffer extends NeighbourOfferDecoded {
  const NotANeighbourOffer();
}

/// An offer in a format a newer version wrote.
class NeighbourOfferTooNew extends NeighbourOfferDecoded {
  const NeighbourOfferTooNew();
}
