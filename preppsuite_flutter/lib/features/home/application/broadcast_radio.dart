/// Which public radio programmes to tune to when the internet is gone
/// (#267).
///
/// When the network and the mobile network fail, the radio is what is
/// left, and official warnings reach it: the federal Modular Warning
/// System passes them to the broadcasters. A household with a battery or
/// crank radio needs to know which programme to look for. That is what
/// this says, per Land: the state broadcaster's programme for it, and its
/// news programme where it has one, with Deutschlandfunk everywhere.
///
/// **Names, not frequencies.** The names are taken from the broadcasters'
/// own list of their programmes, which they publish in the official
/// gazettes under § 29 (4) of the Medienstaatsvertrag (state of
/// 1 February 2022, Amtsblatt Bremen 2022 Nr. 35), together with whether
/// each goes out on UKW and DAB+. Frequencies are a different matter:
/// every programme has dozens of transmitters, each broadcaster publishes
/// its own list, and none of those lists could be read automatically to
/// be checked here. A frequency this app got wrong is a radio tuned to
/// nothing in the one hour it matters. So the household writes down the
/// frequency where it lives, once, while the network works -- off the
/// broadcaster's page or off the radio -- and it travels with the
/// household. A radio that scans finds the programme by its name in any
/// case (RDS on UKW, the station list on DAB+).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/number_input.dart';

enum BroadcastRole {
  /// The state broadcaster's programme for this Land.
  state,

  /// A programme of news and information.
  news,

  /// The same everywhere in Germany.
  national,
}

class BroadcastProgramme {
  const BroadcastProgramme({
    required this.id,
    required this.name,
    required this.broadcaster,
    required this.website,
    required this.role,
    this.ukwOnlyIn,
  });

  /// What a household's frequency for it is stored under. Never shown.
  final String id;

  /// As the broadcaster spells it in its published list.
  final String name;

  final String broadcaster;

  /// The broadcaster's home page, where its frequencies are listed under
  /// reception. The front page and not a deeper link: those move.
  final String website;

  final BroadcastRole role;

  /// Where a programme that goes out on DAB+ is on UKW only in one
  /// place: SWR Aktuell, on one frequency in Stuttgart.
  final String? ukwOnlyIn;
}

const _ndr = ('NDR', 'https://www.ndr.de');
const _wdr = ('WDR', 'https://www1.wdr.de');
const _br = ('BR', 'https://www.br.de');
const _swr = ('SWR', 'https://www.swr.de');
const _hr = ('hr', 'https://www.hr.de');
const _mdr = ('MDR', 'https://www.mdr.de');
const _rbb = ('rbb', 'https://www.rbb-online.de');
const _sr = ('SR', 'https://www.sr.de');
const _rb = ('Radio Bremen', 'https://www.radiobremen.de');

BroadcastProgramme _programme(
  String id,
  String name,
  (String, String) broadcaster,
  BroadcastRole role, {
  String? ukwOnlyIn,
}) => BroadcastProgramme(
  id: id,
  name: name,
  broadcaster: broadcaster.$1,
  website: broadcaster.$2,
  role: role,
  ukwOnlyIn: ukwOnlyIn,
);

const _state = BroadcastRole.state;
const _news = BroadcastRole.news;

final _ndrInfo = _programme('ndr-info', 'NDR Info', _ndr, _news);
final _mdrAktuell = _programme('mdr-aktuell', 'MDR AKTUELL', _mdr, _news);
final _inforadio = _programme('rbb-inforadio', 'Inforadio', _rbb, _news);
final _swrAktuell = _programme(
  'swr-aktuell',
  'SWR Aktuell',
  _swr,
  _news,
  ukwOnlyIn: 'Stuttgart',
);

/// Per Land, by its two-letter code (`GermanState.bbkCode`).
final broadcastProgrammesByState = <String, List<BroadcastProgramme>>{
  'SH': [
    _programme('ndr1-welle-nord', 'NDR 1 Welle Nord', _ndr, _state),
    _ndrInfo,
  ],
  'HH': [_programme('ndr-903', 'NDR 90,3', _ndr, _state), _ndrInfo],
  'NI': [
    _programme('ndr1-niedersachsen', 'NDR 1 Niedersachsen', _ndr, _state),
    _ndrInfo,
  ],
  'HB': [
    _programme('bremen-eins', 'Bremen Eins', _rb, _state),
    _programme('bremen-zwei', 'Bremen Zwei', _rb, _news),
  ],
  'NW': [
    _programme('wdr2', 'WDR 2', _wdr, _state),
    _programme('wdr5', 'WDR 5', _wdr, _news),
  ],
  'HE': [
    _programme('hr4', 'hr4', _hr, _state),
    _programme('hr-info', 'hr-iNFO', _hr, _news),
  ],
  'RP': [
    _programme('swr4-rp', 'SWR4 Rheinland-Pfalz', _swr, _state),
    _programme('swr1-rp', 'SWR1 Rheinland-Pfalz', _swr, _state),
    _swrAktuell,
  ],
  'BW': [
    _programme('swr4-bw', 'SWR4 Baden-Württemberg', _swr, _state),
    _programme('swr1-bw', 'SWR1 Baden-Württemberg', _swr, _state),
    _swrAktuell,
  ],
  'BY': [
    _programme('bayern1', 'BAYERN 1', _br, _state),
    _programme('br24', 'BR24', _br, _news),
  ],
  'SL': [_programme('sr3', 'SR 3 Saarlandwelle', _sr, _state)],
  'BE': [_programme('rbb-888', 'rbb 88,8', _rbb, _state), _inforadio],
  'BB': [
    _programme('antenne-brandenburg', 'Antenne Brandenburg', _rbb, _state),
    _inforadio,
  ],
  'MV': [_programme('ndr1-radio-mv', 'NDR 1 Radio MV', _ndr, _state), _ndrInfo],
  'SN': [_programme('mdr-sachsen', 'MDR SACHSEN', _mdr, _state), _mdrAktuell],
  'ST': [
    _programme('mdr-sachsen-anhalt', 'MDR SACHSEN-ANHALT', _mdr, _state),
    _mdrAktuell,
  ],
  'TH': [
    _programme('mdr-thueringen', 'MDR THÜRINGEN', _mdr, _state),
    _mdrAktuell,
  ],
};

const deutschlandfunk = BroadcastProgramme(
  id: 'deutschlandfunk',
  name: 'Deutschlandfunk',
  broadcaster: 'Deutschlandradio',
  website: 'https://www.deutschlandfunk.de',
  role: BroadcastRole.national,
);

/// A UKW frequency as typed, in MHz, or null.
///
/// The band is 87.5 to 108 MHz, and German transmitters sit on a grid of
/// 50 kHz -- 95.85 is a frequency, 95.83 is a slip of the finger.
double? parseUkwFrequency(String raw) {
  final value = readNonNegativeNumber(raw);
  if (value == null || value < 87.5 || value > 108) return null;
  final steps = value * 20;
  if ((steps - steps.round()).abs() > 1e-6) return null;
  return steps.round() / 20;
}

/// The frequencies a household wrote down, by programme id.
///
/// One of the household's settings: it is in one place, and a frequency
/// typed on the telephone is the one the radio in the kitchen needs.
class BroadcastFrequencyStore {
  const BroadcastFrequencyStore();

  static const key = 'radioFrequencies';

  Future<Map<String, double>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final MapEntry(key: id, value: mhz) in decoded.entries)
          if (id is String && mhz is num) id: ?parseUkwFrequency('$mhz'),
      };
    } on Object {
      return const {};
    }
  }

  /// Sets [programme]'s frequency, or removes it with null, on what is
  /// stored -- another device's frequency for another programme may have
  /// arrived since this one was read (see `RereadOnSettingsArrival`).
  Future<Map<String, double>> set(String programme, double? mhz) async {
    final updated = {...await load()};
    if (mhz == null) {
      updated.remove(programme);
    } else {
      updated[programme] = mhz;
    }
    final prefs = await SharedPreferences.getInstance();
    if (updated.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(updated));
    }
    return updated;
  }
}
