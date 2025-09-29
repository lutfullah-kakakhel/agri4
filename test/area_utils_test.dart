import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:agri4_app/geo/area_utils.dart';

void main() {
  test('computePolygonAreaSquareMeters returns ~ area for ~100m square', () {
    // Approx 0.0009 deg ~ 100m at equator (rough)
    final List<LatLng> square = <LatLng>[
      const LatLng(0.0, 0.0),
      const LatLng(0.0, 0.0009),
      const LatLng(0.0009, 0.0009),
      const LatLng(0.0009, 0.0),
    ];
    final double area = computePolygonAreaSquareMeters(square);
    expect(area, greaterThan(8000));
    expect(area, lessThan(12000));
  });
}
