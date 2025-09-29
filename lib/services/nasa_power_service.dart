import 'package:dio/dio.dart';

class NasaPowerService {
  NasaPowerService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Fetch last [days] days (default 7) of daily data for given lat/lon.
  Future<NasaPowerDaily> fetchDaily({required double lat, required double lon, int days = 7}) async {
    final DateTime end = DateTime.now().toUtc();
    final DateTime start = end.subtract(Duration(days: days - 1));
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

    final Response<dynamic> res = await _dio.get<dynamic>(
      'https://power.larc.nasa.gov/api/temporal/daily/point',
      queryParameters: <String, dynamic>{
        'parameters': 'T2M_MAX,T2M_MIN,PRECTOTCORR,ALLSKY_SFC_SW_DWN',
        'start': fmt(start),
        'end': fmt(end),
        'latitude': lat,
        'longitude': lon,
        'community': 'AG',
        'format': 'JSON',
      },
    );
    return NasaPowerDaily.fromJson(res.data as Map<String, dynamic>);
  }
}

class NasaPowerDaily {
  NasaPowerDaily({required this.dates, required this.tmaxC, required this.tminC, required this.precipMm, required this.solarMJm2});

  final List<String> dates;
  final List<double> tmaxC;
  final List<double> tminC;
  final List<double> precipMm;
  final List<double> solarMJm2;

  factory NasaPowerDaily.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> properties = json['properties'] as Map<String, dynamic>;
    final Map<String, dynamic> parameter = properties['parameter'] as Map<String, dynamic>;
    List<String> orderedDatesFrom(Map<String, dynamic> m) {
      final List<String> keys = m.keys.map((Object k) => k.toString()).toList()..sort();
      return keys;
    }

    final Map<String, dynamic> tmax = (parameter['T2M_MAX'] as Map<String, dynamic>);
    final Map<String, dynamic> tmin = (parameter['T2M_MIN'] as Map<String, dynamic>);
    final Map<String, dynamic> prec = (parameter['PRECTOTCORR'] as Map<String, dynamic>);
    final Map<String, dynamic> solar = (parameter['ALLSKY_SFC_SW_DWN'] as Map<String, dynamic>);

    final List<String> dates = orderedDatesFrom(tmax);
    double toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return NasaPowerDaily(
      dates: dates,
      tmaxC: dates.map((String d) => toDouble(tmax[d])).toList(),
      tminC: dates.map((String d) => toDouble(tmin[d])).toList(),
      precipMm: dates.map((String d) => toDouble(prec[d])).toList(),
      solarMJm2: dates.map((String d) => toDouble(solar[d])).toList(),
    );
  }
}


