import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;

double computePolygonAreaSquareMeters(List<LatLng> points) {
  if (points.length < 3) return 0.0;
  final List<mt.LatLng> mtPoints = points
      .map((LatLng p) => mt.LatLng(p.latitude, p.longitude))
      .toList(growable: false);
  final num area = mt.SphericalUtil.computeArea(mtPoints);
  return area.toDouble();
}


