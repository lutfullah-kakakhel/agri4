import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agri4_app/storage/settings_storage.dart';

class TokenService {
  TokenService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String?> getSentinelToken() async {
    final SettingsStorage settings = SettingsStorage.of(Hive.box('settings'));
    final String? backend = settings.backendBaseUrl;
    final String? manualToken = settings.sentinelHubToken;
    print('TokenService: backend URL = $backend');
    print('TokenService: manual token = ${manualToken?.substring(0, 20)}...');
    if (backend == null || backend.isEmpty) {
      print('TokenService: no backend, using manual token');
      return manualToken;
    }
    try {
      print('TokenService: calling backend $backend');
      final Response<dynamic> r = await _dio.post<dynamic>(
        backend.endsWith('/') ? '${backend}token' : '$backend/token',
      );
      final String? token = (r.data as Map<String, dynamic>)['access_token'] as String?;
      print('TokenService: got token from backend: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      print('TokenService: backend failed: $e, falling back to manual token');
      return manualToken;
    }
  }
}


