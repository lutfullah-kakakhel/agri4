import 'dart:typed_data';

import 'package:dio/dio.dart';

class SentinelHubService {
  SentinelHubService({required this.accessToken, Dio? dio}) : _dio = dio ?? Dio();

  final String accessToken;
  final Dio _dio;

  /// Fetch NDVI PNG for bounding box at given date.
  /// bbox: [minLon, minLat, maxLon, maxLat]
  Future<Uint8List> fetchNdviPng({required List<double> bbox, String from = '2024-01-01', String to = '2024-12-31'}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'input': <String, dynamic>{
        'bounds': <String, dynamic>{
          'bbox': bbox,
        },
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'sentinel-2-l2a',
            'dataFilter': <String, dynamic>{
              'timeRange': <String, String>{'from': '${from}T00:00:00Z', 'to': '${to}T23:59:59Z'},
              'maxCloudCoverage': 40,
              'mosaickingOrder': 'mostRecent',
            },
          },
        ],
      },
      'output': <String, dynamic>{
        'width': 512,
        'height': 512,
        'responses': <Map<String, dynamic>>[
          <String, dynamic>{'identifier': 'default', 'format': <String, String>{'type': 'image/png'}},
        ],
      },
      'evalscript': _ndviEvalscript,
    };
    try {
      final Response<List<int>> res = await _dio.post<List<int>>(
        'https://services.sentinel-hub.com/api/v1/process',
        data: body,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'image/png',
          },
          responseType: ResponseType.bytes,
        ),
      );
      return Uint8List.fromList(res.data ?? <int>[]);
    } on DioException catch (e) {
      final String details = e.response?.data is List<int>
          ? String.fromCharCodes(e.response!.data as List<int>)
          : e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      throw Exception('SentinelHub NDVI failed: ${e.response?.statusCode} $details');
    }
  }
}

const String _ndviEvalscript = '''//VERSION=3
function setup() {
  return {
    input: [{ bands: ["B04", "B08"], units: "REFLECTANCE" }],
    output: { bands: 4 }
  };
}

function evaluatePixel(sample) {
  let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04 + 1e-6);
  // Color ramp: brown(-1) -> red(0) -> yellow(0.3) -> green(0.8+)
  let r = 0.0, g = 0.0, b = 0.0;
  if (ndvi < 0) { r = 0.6; g = 0.3; b = 0.2; }
  else if (ndvi < 0.3) { r = 1.0; g = ndvi/0.3; b = 0.0; }
  else if (ndvi < 0.8) { r = 1.0 - (ndvi-0.3)/0.5; g = 1.0; b = 0.0; }
  else { r = 0.0; g = 0.8; b = 0.0; }
  return [r, g, b, 0.8];
}
''';


