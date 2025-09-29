import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

class FieldStorage {
  FieldStorage(this._box);

  final Box _box;

  static FieldStorage of(Box box) => FieldStorage(box);

  Future<String> saveField({required String name, required List<LatLng> polygon}) async {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> feature = _polygonToGeoJsonFeature(id: id, name: name, polygon: polygon);
    await _box.put(id, jsonEncode(feature));
    return id;
  }

  Future<void> deleteField(String id) async {
    await _box.delete(id);
  }

  List<StoredField> listFields() {
    return _box.keys.map((dynamic k) {
      final String id = k.toString();
      final String raw = _box.get(k) as String;
      final Map<String, dynamic> feature = jsonDecode(raw) as Map<String, dynamic>;
      final String name = (feature['properties'] as Map<String, dynamic>)['name'] as String? ?? 'Field';
      final List<dynamic> coords = (feature['geometry'] as Map<String, dynamic>)['coordinates'] as List<dynamic>;
      final List<LatLng> polygon = (coords.first as List<dynamic>)
          .map((dynamic p) {
            final List<dynamic> pair = p as List<dynamic>;
            final double lon = (pair[0] as num).toDouble();
            final double lat = (pair[1] as num).toDouble();
            return LatLng(lat, lon);
          })
          .toList();
      return StoredField(id: id, name: name, polygon: polygon);
    }).toList();
  }

  Map<String, dynamic> _polygonToGeoJsonFeature({required String id, required String name, required List<LatLng> polygon}) {
    return <String, dynamic>{
      'type': 'Feature',
      'id': id,
      'properties': <String, dynamic>{'name': name},
      'geometry': <String, dynamic>{
        'type': 'Polygon',
        'coordinates': <List<List<double>>>[
          polygon.map((LatLng p) => <double>[p.longitude, p.latitude]).toList(),
        ],
      },
    };
  }
}

class StoredField {
  StoredField({required this.id, required this.name, required this.polygon});

  final String id;
  final String name;
  final List<LatLng> polygon;
}


