import 'dart:convert';

import 'package:agri4_app/services/nasa_power_service.dart';
import 'package:agri4_app/services/open_meteo_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WeatherRepository {
  WeatherRepository(this._box, this._open, this._power);

  final Box _box;
  final OpenMeteoService _open;
  final NasaPowerService _power;

  static String _key(double lat, double lon) => 'weather:${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

  Future<(OpenMeteoDaily, NasaPowerDaily)> getWeather({required double lat, required double lon, bool refresh = false}) async {
    final String key = _key(lat, lon);
    if (!refresh && _box.containsKey(key)) {
      final Map<String, dynamic> cached = jsonDecode(_box.get(key) as String) as Map<String, dynamic>;
      return (OpenMeteoDaily.fromJson(cached['open'] as Map<String, dynamic>), NasaPowerDaily.fromJson(cached['power'] as Map<String, dynamic>));
    }
    final OpenMeteoDaily open = await _open.fetchDaily(lat: lat, lon: lon);
    final NasaPowerDaily power = await _power.fetchDaily(lat: lat, lon: lon, days: 7);
    await _box.put(key, jsonEncode(<String, dynamic>{'open': <String, dynamic>{'daily': <String, dynamic>{'time': open.dates, 'precipitation_sum': open.precipMm, 'et0_fao_evapotranspiration': open.et0Mm}}, 'power': _encodePower(power)}));
    return (open, power);
  }

  Map<String, dynamic> _encodePower(NasaPowerDaily p) {
    return <String, dynamic>{
      'properties': <String, dynamic>{
        'parameter': <String, dynamic>{
          'T2M_MAX': <String, dynamic>{for (int i = 0; i < p.dates.length; i++) p.dates[i]: i < p.tmaxC.length ? p.tmaxC[i] : 0},
          'T2M_MIN': <String, dynamic>{for (int i = 0; i < p.dates.length; i++) p.dates[i]: i < p.tminC.length ? p.tminC[i] : 0},
          'PRECTOTCORR': <String, dynamic>{for (int i = 0; i < p.dates.length; i++) p.dates[i]: i < p.precipMm.length ? p.precipMm[i] : 0},
          'ALLSKY_SFC_SW_DWN': <String, dynamic>{for (int i = 0; i < p.dates.length; i++) p.dates[i]: i < p.solarMJm2.length ? p.solarMJm2[i] : 0},
        }
      }
    };
  }
}


