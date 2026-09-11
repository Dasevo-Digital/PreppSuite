import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_level.dart';

/// Cut from the real answers of the Umweltbundesamt's interface on
/// 2026-09-11. Every row is keyed by position, not by name, which is what
/// these tests pin down: a shifted column would otherwise put a station
/// in the wrong state and a reading in the wrong class.
const _stations = '''
{"request":{"use":"airquality"},
 "indices":["station id","station code","station name","station city",
   "station synonym","station active from","station active to",
   "station longitude","station latitude","network id",
   "station setting id","station type id","network code","network name",
   "station setting name","station setting short name","station type name",
   "station street","station street nr","station zip"],
 "data":{
   "21":["21","DEBB021","Potsdam-Zentrum","Potsdam","PDBA","2009-04-15",null,
     "13.0602","52.4014","4","1","1","BB","Brandenburg",
     "städtisches Gebiet","städtisch","Hintergrund","Am Bassinplatz","","14467"],
   "513":["513","DENI063","Braunschweig","Braunschweig","BRAU","1990-01-01",
     null,"10.5268","52.2733","9","1","1","NI","Niedersachsen",
     "städtisches Gebiet","städtisch","Hintergrund","","","38100"]}}
''';

/// Two hours from station 513: ozone climbing out of the best class into
/// the second, with nitrogen dioxide alongside it.
const _reading = '''
{"data":{"513":{
  "2026-09-04 07:00:00":["2026-09-04 08:00:00",0,1,[3,52,0,"0.867"],[5,9,0,"0.45"]],
  "2026-09-04 08:00:00":["2026-09-04 09:00:00",1,1,[3,67,1,"1.102"],[5,5,0,"0.25"]]}},
 "count":1}
''';

/// Ozone and nitrogen dioxide, hourly, classic index — with rows from
/// other scopes and the revised index mixed in, exactly as the interface
/// sends them.
const _thresholds = '''
{"count":6,
 "indices":["threshold id","component id","scope id","threshold type",
   "threshold min","threshold max","threshold index"],
 "1":["1","3","2","aq","0","60","0"],
 "2":["2","3","2","aq","61","120","1"],
 "3":["3","3","2","aq","121","180","2"],
 "4":["4","3","2","aq4","0","24","0"],
 "5":["5","3","4","me","0","12","0"],
 "6":["6","5","2","aq","0","20","0"]}
''';

void main() {
  test('a station keeps its name, its state and where it stands', () {
    final stations = AirQualityClient.parseStations(_stations);

    expect(stations.map((s) => s.name), ['Braunschweig', 'Potsdam-Zentrum']);
    final braunschweig = stations.first;
    expect(braunschweig.id, '513');
    expect(braunschweig.state, 'Niedersachsen');
    expect(braunschweig.setting, 'städtisches Gebiet');
    expect(braunschweig.latitude, closeTo(52.2733, 0.0001));
    expect(braunschweig.longitude, closeTo(10.5268, 0.0001));
    // The city repeats the name here, so it is not shown twice.
    expect(braunschweig.city, isNull);
    expect(stations.last.city, 'Potsdam');
  });

  test('the newest hour wins, with the class the UBA gave it', () {
    final reading = AirQualityClient.parseReading(_reading, '513')!;

    expect(reading.measuredAt, DateTime(2026, 9, 4, 9));
    expect(reading.level, AirQualityClass.good);
    expect(reading.incomplete, isTrue);
    expect(reading.components.map((c) => c.code), ['O₃', 'NO₂']);
    expect(reading.components.first.value, 67);
    expect(reading.components.first.level, AirQualityClass.good);
    expect(reading.components.last.level, AirQualityClass.veryGood);
  });

  test('the pollutant behind the class is named', () {
    final reading = AirQualityClient.parseReading(_reading, '513')!;

    // The index is the worst of the components, so saying which one it
    // was is the difference between "moderate" and "moderate because of
    // ozone on a summer afternoon".
    expect(reading.leading?.code, 'O₃');
  });

  test('a station that reported nothing yields nothing', () {
    expect(AirQualityClient.parseReading('{"data":{}}', '513'), isNull);
  });

  test('only the hourly classic index is taken from the thresholds', () {
    final thresholds = AirQualityClient.parseThresholds(_thresholds);

    // The revised index (aq4) and the daily scopes are on the same
    // endpoint; mixing them would put a reading in the wrong class.
    expect(thresholds.keys.toSet(), {3, 5});
    final ozone = thresholds[3]!;
    expect(ozone.length, 3);
    expect(ozone.first.level, AirQualityClass.veryGood);
    expect(ozone.first.max, 60);
    expect(ozone.last.level, AirQualityClass.moderate);
    expect(ozone.last.min, 121);
  });

  test('an index the interface does not give is not invented', () {
    expect(AirQualityClass.fromIndex(null), AirQualityClass.unknown);
    expect(AirQualityClass.fromIndex(-1), AirQualityClass.unknown);
    expect(AirQualityClass.fromIndex(5), AirQualityClass.unknown);
    expect(AirQualityClass.fromIndex(4), AirQualityClass.veryPoor);
    expect(AirQualityClass.unknown.step, isNull);
    expect(AirQualityClass.veryPoor.step, 4);
  });

  test('an hour old is current, four hours old is not', () {
    // Hourly data, published once the hour is complete, so the newest
    // value is routinely an hour old with everything working.
    final reading = AirQualityClient.parseReading(_reading, '513')!;

    expect(
      reading.isStaleAt(DateTime(2026, 9, 4, 10)),
      isFalse,
      reason: 'an hour after the hour it covers',
    );
    expect(reading.isStaleAt(DateTime(2026, 9, 4, 13)), isTrue);
  });
}
