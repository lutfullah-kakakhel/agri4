import 'package:hive_flutter/hive_flutter.dart';

class SettingsStorage {
  SettingsStorage(this._box);

  final Box _box;

  static SettingsStorage of(Box box) => SettingsStorage(box);

  String? get sentinelHubToken => _box.get('sentinel_token') as String?;
  Future<void> setSentinelHubToken(String token) async => _box.put('sentinel_token', token);
  String? get backendBaseUrl => _box.get('backend_base_url') as String?;
  Future<void> setBackendBaseUrl(String url) async => _box.put('backend_base_url', url);

  String get units => (_box.get('units') as String?) ?? 'acres';
  Future<void> setUnits(String value) async => _box.put('units', value);

  double get targetAreaAcres => (_box.get('target_area_acres') as num?)?.toDouble() ?? 2.0;
  Future<void> setTargetAreaAcres(double v) async => _box.put('target_area_acres', v);
}


