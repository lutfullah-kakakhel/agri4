import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/weather_config.dart';

class RealWeatherService {
  final Dio _dio = Dio();
  
  // Use API key from configuration
  static const String _apiKey = WeatherConfig.openWeatherMapApiKey;
  static const String _baseUrl = WeatherConfig.baseUrl;
  
  RealWeatherService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Get current weather data from OpenWeatherMap
  Future<Map<String, dynamic>> getCurrentWeather(double latitude, double longitude) async {
    try {
      // If no API key or demo key, return fallback data
      if (_apiKey == 'demo_key_replace_with_your_key') {
        return _getFallbackWeather(latitude, longitude);
      }

      final response = await _dio.get('/weather', queryParameters: {
        'lat': latitude,
        'lon': longitude,
        'appid': _apiKey,
        'units': WeatherConfig.units,
      });

      if (response.statusCode == 200) {
        return _parseCurrentWeather(response.data);
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Weather API error: $e');
      // Return fallback data on error
      return _getFallbackWeather(latitude, longitude);
    }
  }

  /// Get weather forecast from OpenWeatherMap
  Future<Map<String, dynamic>> getWeatherForecast(double latitude, double longitude) async {
    try {
      // If no API key or demo key, return fallback data
      if (_apiKey == 'demo_key_replace_with_your_key') {
        return _getFallbackForecast();
      }

      final response = await _dio.get('/forecast', queryParameters: {
        'lat': latitude,
        'lon': longitude,
        'appid': _apiKey,
        'units': WeatherConfig.units,
      });

      if (response.statusCode == 200) {
        return _parseForecast(response.data);
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Weather forecast API error: $e');
      // Return fallback data on error
      return _getFallbackForecast();
    }
  }

  /// Parse current weather data from API response
  Map<String, dynamic> _parseCurrentWeather(Map<String, dynamic> data) {
    final main = data['main'] ?? {};
    final weather = data['weather']?[0] ?? {};
    final wind = data['wind'] ?? {};
    final rain = data['rain'] ?? {};
    final clouds = data['clouds'] ?? {};

    return {
      'temperature': (main['temp'] ?? 25.0).toDouble(),
      'humidity': (main['humidity'] ?? 50.0).toDouble(),
      'rainfall': _parseRainfall(rain),
      'wind_speed': (wind['speed'] ?? 0.0).toDouble(),
      'condition': weather['main']?.toString().toLowerCase() ?? 'clear',
      'description': weather['description'] ?? 'clear sky',
      'pressure': (main['pressure'] ?? 1013.0).toDouble(),
      'visibility': (data['visibility'] ?? 10000) / 1000.0, // Convert to km
      'cloudiness': (clouds['all'] ?? 0.0).toDouble(),
      'timestamp': DateTime.now().toIso8601String(),
      'location': data['name'] ?? 'Unknown',
      'country': data['sys']?['country'] ?? 'Unknown',
    };
  }

  /// Parse forecast data from API response
  Map<String, dynamic> _parseForecast(Map<String, dynamic> data) {
    final forecast = data['list'] ?? [];
    final parsedForecast = <Map<String, dynamic>>[];

    // Process 5-day forecast (every 8 hours = 40 data points)
    // Group by day and take the daily summary
    final Map<String, List<Map<String, dynamic>>> dailyData = {};
    
    for (var item in forecast) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch((item['dt'] ?? 0) * 1000);
      final dateKey = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      
      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = [];
      }
      
      final main = item['main'] ?? {};
      final weather = item['weather']?[0] ?? {};
      final rain = item['rain'] ?? {};
      
      dailyData[dateKey]!.add({
        'date': dateTime.toIso8601String(),
        'temperature': (main['temp'] ?? 25.0).toDouble(),
        'humidity': (main['humidity'] ?? 50.0).toDouble(),
        'rainfall': _parseRainfall(rain),
        'condition': weather['main']?.toString().toLowerCase() ?? 'clear',
        'description': weather['description'] ?? 'clear sky',
        'time': '${dateTime.hour.toString().padLeft(2, '0')}:00',
      });
    }

    // Create daily summaries
    for (var entry in dailyData.entries) {
      final dayData = entry.value;
      if (dayData.isNotEmpty) {
        // Calculate daily averages
        final avgTemp = dayData.map((e) => e['temperature']).reduce((a, b) => a + b) / dayData.length;
        final avgHumidity = dayData.map((e) => e['humidity']).reduce((a, b) => a + b) / dayData.length;
        final totalRainfall = dayData.map((e) => e['rainfall']).reduce((a, b) => a + b);
        
        // Get most common condition
        final conditions = dayData.map((e) => e['condition']).toList();
        final mostCommonCondition = conditions.fold<Map<String, int>>({}, (map, condition) {
          map[condition] = (map[condition] ?? 0) + 1;
          return map;
        }).entries.reduce((a, b) => a.value > b.value ? a : b).key;

        parsedForecast.add({
          'date': DateTime.parse(entry.key).toIso8601String(),
          'temperature': avgTemp,
          'humidity': avgHumidity,
          'rainfall': totalRainfall,
          'condition': mostCommonCondition,
          'description': dayData.first['description'],
          'day_name': _getDayName(DateTime.parse(entry.key)),
        });
      }
    }

    return {
      'forecast': parsedForecast,
      'generated_at': DateTime.now().toIso8601String(),
      'location': data['city']?['name'] ?? 'Unknown',
      'country': data['city']?['country'] ?? 'Unknown',
    };
  }

  /// Parse rainfall from rain object
  double _parseRainfall(Map<String, dynamic> rain) {
    // OpenWeatherMap provides rainfall in mm for the last 1-3 hours
    final rain1h = rain['1h']?.toDouble() ?? 0.0;
    final rain3h = rain['3h']?.toDouble() ?? 0.0;
    
    // Return the most recent rainfall data
    return rain1h > 0 ? rain1h : rain3h;
  }

  /// Get day name from date
  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Fallback weather data when API is not available
  Map<String, dynamic> _getFallbackWeather(double latitude, double longitude) {
    return {
      'temperature': 25.0,
      'humidity': 60.0,
      'rainfall': 0.0,
      'wind_speed': 5.0,
      'condition': 'clear',
      'description': 'clear sky',
      'pressure': 1013.0,
      'visibility': 10.0,
      'cloudiness': 20.0,
      'timestamp': DateTime.now().toIso8601String(),
      'location': 'Demo Location',
      'country': 'Demo',
      'note': 'Using demo data - get API key for real weather',
    };
  }

  /// Fallback forecast data when API is not available
  Map<String, dynamic> _getFallbackForecast() {
    final forecast = <Map<String, dynamic>>[];
    
    for (int i = 1; i <= 5; i++) {
      final date = DateTime.now().add(Duration(days: i));
      forecast.add({
        'date': date.toIso8601String(),
        'temperature': 25.0 + (i * 2),
        'humidity': 60.0 - (i * 5),
        'rainfall': 0.0,
        'condition': 'clear',
        'description': 'clear sky',
        'day_name': _getDayName(date),
      });
    }
    
    return {
      'forecast': forecast,
      'generated_at': DateTime.now().toIso8601String(),
      'location': 'Demo Location',
      'country': 'Demo',
      'note': 'Using demo data - get API key for real weather',
    };
  }
}
