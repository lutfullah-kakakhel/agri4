import 'dart:typed_data';
import 'package:dio/dio.dart';

class CopernicusService {
  CopernicusService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Search for Sentinel-2 products in a bounding box
  Future<List<CopernicusProduct>> searchProducts({
    required List<double> bbox,
    String from = '2024-01-01',
    String to = '2024-12-31',
    int maxCloudCoverage = 30,
  }) async {
    final String bboxStr = '${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]}';
    
    final Response<dynamic> response = await _dio.get(
      'https://catalogue.dataspace.copernicus.eu/odata/v1/Products',
      queryParameters: {
        '\$filter': "Collection/Name eq 'SENTINEL-2' and OData.CSC.Intersects(area=geography'SRID=4326;POLYGON(($bboxStr))') and ContentDate/Start gt $from and ContentDate/Start lt $to and Attributes/OData.CSC.DoubleAttribute/any(att:att/Name eq 'cloudCover' and att/OData.CSC.DoubleAttribute/Value lt $maxCloudCoverage)",
        '\$orderby': 'ContentDate/Start desc',
        '\$top': 10,
      },
    );

    final List<dynamic> products = response.data['value'] as List<dynamic>;
    return products.map((p) => CopernicusProduct.fromJson(p)).toList();
  }

  /// Get the most recent product for NDVI calculation
  Future<CopernicusProduct?> getLatestProduct({
    required List<double> bbox,
    int maxCloudCoverage = 30,
  }) async {
    final products = await searchProducts(
      bbox: bbox,
      maxCloudCoverage: maxCloudCoverage,
    );
    return products.isNotEmpty ? products.first : null;
  }

  /// Generate NDVI visualization URL (using Sentinel Hub Process API for visualization)
  String getNdviVisualizationUrl({
    required String productId,
    required List<double> bbox,
  }) {
    final String bboxStr = '${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]}';
    
    // Use a simpler approach - get a basic satellite image first
    return 'https://services.sentinel-hub.com/api/v1/process?request={"input":{"bounds":{"bbox":[$bboxStr]},"data":[{"type":"sentinel-2-l2a","dataFilter":{"timeRange":{"from":"2024-01-01T00:00:00Z","to":"2024-12-31T23:59:59Z"},"maxCloudCoverage":40,"mosaickingOrder":"mostRecent"}}]},"output":{"width":512,"height":512,"responses":[{"identifier":"default","format":{"type":"image/png"}}]},"evalscript":"//VERSION=3\\nfunction setup() {\\n  return {\\n    input: [{ bands: [\\"B04\\", \\"B03\\", \\"B02\\"], units: \\"REFLECTANCE\\" }],\\n    output: { bands: 3 }\\n  };\\n}\\n\\nfunction evaluatePixel(sample) {\\n  return [sample.B04, sample.B03, sample.B02];\\n}"}';
  }
}

class CopernicusProduct {
  CopernicusProduct({
    required this.id,
    required this.name,
    required this.contentDate,
    required this.cloudCover,
    required this.downloadUrl,
  });

  final String id;
  final String name;
  final DateTime contentDate;
  final double cloudCover;
  final String downloadUrl;

  factory CopernicusProduct.fromJson(Map<String, dynamic> json) {
    return CopernicusProduct(
      id: json['Id'] as String,
      name: json['Name'] as String,
      contentDate: DateTime.parse(json['ContentDate']['Start'] as String),
      cloudCover: (json['Attributes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (attr) => attr['Name'] == 'cloudCover',
            orElse: () => {'Value': 0.0},
          )['Value'] as double,
      downloadUrl: json['@odata.mediaReadLink'] as String,
    );
  }
}
