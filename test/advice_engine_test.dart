import 'package:flutter_test/flutter_test.dart';
import 'package:agri4_app/services/open_meteo_service.dart';
import 'package:agri4_app/services/nasa_power_service.dart';
import 'package:agri4_app/services/advice_engine.dart';

void main() {
  test('AdviceEngine increases irrigation when ET0 exceeds rainfall', () {
    final OpenMeteoDaily om = OpenMeteoDaily(
      dates: <String>['2025-01-01','2025-01-02','2025-01-03','2025-01-04','2025-01-05','2025-01-06','2025-01-07'],
      precipMm: <double>[0, 0, 0, 1, 0, 0, 0],
      et0Mm: <double>[4, 4, 4, 4, 4, 4, 4],
    );
    final NasaPowerDaily pw = NasaPowerDaily(
      dates: om.dates,
      tmaxC: <double>[30,31,32,33,34,35,36],
      tminC: <double>[20,20,21,21,22,22,23],
      precipMm: <double>[0, 0, 0, 1, 0, 0, 0],
      solarMJm2: <double>[15,16,17,18,19,20,21],
    );

    final AdviceResult res = AdviceEngine().generate(openMeteo: om, power: pw);
    expect(res.irrigationMmNext3Days, greaterThan(0));
    expect(res.messages.isNotEmpty, isTrue);
  });
}
