import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/neighbourhood/application/neighbour_offer_code.dart';

/// The offer as it travels (#152): a QR code of plain text that a
/// neighbour's camera app can read without PreppSuite, and PreppSuite can
/// read back whatever language it was written in.
void main() {
  final water = NeighbourOfferCode(
    kind: NeighbourOfferKind.water,
    body: '20 l Trinkwasser, abzugeben',
    contact: 'Haus 4, 2. Stock',
    offeredOn: DateTime.utc(2026, 10, 10),
  );

  String german(NeighbourOfferCode offer) =>
      offer.encode(kindLabel: 'Wasser', contactLabel: 'Kontakt');

  NeighbourOfferCode read(String text) =>
      (NeighbourOfferCode.decode(text) as ReadNeighbourOffer).offer;

  test('the code is the offer, readable as it stands', () {
    expect(
      german(water),
      'Wasser: 20 l Trinkwasser, abzugeben\n'
      'Kontakt: Haus 4, 2. Stock\n'
      'PreppSuite-Angebot/1 water 2026-10-10',
    );
  });

  test('and reads back whole', () {
    final back = read(german(water));

    expect(back.kind, NeighbourOfferKind.water);
    expect(back.body, water.body);
    expect(back.contact, water.contact);
    expect(back.offeredOn, water.offeredOn);
  });

  test('the labels are the author\'s language and the reader skips them', () {
    // A Spanish phone reading a German neighbour's code.
    final back = read(
      water.encode(kindLabel: 'Agua', contactLabel: 'Contacto'),
    );
    expect(back.body, water.body);
    expect(back.contact, water.contact);
  });

  test('a colon in the offer itself survives', () {
    final offer = NeighbourOfferCode(
      kind: NeighbourOfferKind.help,
      body: 'Kinderbetreuung: Samstag vormittags',
      offeredOn: DateTime.utc(2026, 10, 10),
    );
    expect(read(german(offer)).body, 'Kinderbetreuung: Samstag vormittags');
  });

  test('without a contact there is no contact line', () {
    final offer = NeighbourOfferCode(
      kind: NeighbourOfferKind.tools,
      body: 'Stromerzeuger zum Ausleihen',
      offeredOn: DateTime.utc(2026, 10, 10),
    );
    final text = german(offer);

    expect(text.split('\n'), hasLength(2));
    expect(read(text).contact, isNull);
  });

  test('a kind this version does not know reads as "other"', () {
    final back = read(
      'Boot: Schlauchboot\nPreppSuite-Angebot/1 boat 2026-10-10',
    );
    expect(back.kind, NeighbourOfferKind.other);
    expect(back.body, 'Schlauchboot');
  });

  test('a newer format is refused as such, not half read', () {
    expect(
      NeighbourOfferCode.decode(
        'Wasser: 20 l\nPreppSuite-Angebot/2 water 2026-10-10',
      ),
      isA<NeighbourOfferTooNew>(),
    );
  });

  test('anything else is not an offer', () {
    for (final text in [
      'https://example.org',
      '',
      'Wasser: 20 l',
      'PreppSuite-Angebot/1 water 2026-10-10',
      'Wasser: 20 l\nPreppSuite-Angebot/1 water 10.10.2026',
      'a\nb\nc\nPreppSuite-Angebot/1 water 2026-10-10',
    ]) {
      expect(
        NeighbourOfferCode.decode(text),
        isA<NotANeighbourOffer>(),
        reason: text,
      );
    }
  });

  test('line endings from another system do not matter', () {
    final back = read(german(water).replaceAll('\n', '\r\n'));
    expect(back.contact, water.contact);
  });

  test('an offer is one line, and no longer than the limit', () {
    expect(cleanNeighbourOfferText('20 l\nWasser  ', 200), '20 l Wasser');
    expect(
      cleanNeighbourOfferText('x' * 300, neighbourOfferBodyLimit),
      hasLength(neighbourOfferBodyLimit),
    );
  });
}
