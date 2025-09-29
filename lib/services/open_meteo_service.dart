import 'package:dio/dio.dart';

class OpenMeteoService {
  OpenMeteoService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<OpenMeteoDaily> fetchDaily({required double lat, required double lon}) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: <String, dynamic>{
        'latitude': lat,
        'longitude': lon,
        'daily': 'precipitation_sum,et0_fao_evapotranspiration',
        'timezone': 'auto',
      },
    );
    return OpenMeteoDaily.fromJson(res.data as Map<String, dynamic>);
  }
}

class OpenMeteoDaily {
  OpenMeteoDaily({required this.dates, required this.precipMm, required this.et0Mm});

  final List<String> dates;
  final List<double> precipMm;
  final List<double> et0Mm;

  factory OpenMeteoDaily.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> daily = json['daily'] as Map<String, dynamic>;
    final List<dynamic> time = daily['time'] as List<dynamic>;
    final List<dynamic> precip = daily['precipitation_sum'] as List<dynamic>;
    final List<dynamic> et0 = daily['et0_fao_evapotranspiration'] as List<dynamic>;
    return OpenMeteoDaily(
      dates: time.cast<String>(),
      precipMm: precip.map((dynamic v) => (v as num?)?.toDouble() ?? 0.0).toList(),
      et0Mm: et0.map((dynamic v) => (v as num?)?.toDouble() ?? 0.0).toList(),
    );
  }
}


