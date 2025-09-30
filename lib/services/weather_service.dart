import 'dart:math';
import 'real_weather_service.dart';
import 'package:flutter/foundation.dart';

class WeatherService {
  final Random _random = Random();
  final RealWeatherService _realWeatherService = RealWeatherService();

  /// Get current weather data (real data with fallback)
  Future<Map<String, dynamic>> getCurrentWeather(double latitude, double longitude) async {
    try {
      // Try to get real weather data first
      final realWeather = await _realWeatherService.getCurrentWeather(latitude, longitude);
      
      // If we got real data (not fallback), use it
      if (!realWeather.containsKey('note')) {
        return realWeather;
      }
      
      // If real API failed, use improved simulation based on location
      return _getSimulatedWeather(latitude, longitude);
    } catch (e) {
      debugPrint('Weather service error: $e');
      return _getSimulatedWeather(latitude, longitude);
    }
  }

  /// Get weather forecast (real data with fallback)
  Future<Map<String, dynamic>> getWeatherForecast(double latitude, double longitude) async {
    try {
      // Try to get real weather forecast first
      final realForecast = await _realWeatherService.getWeatherForecast(latitude, longitude);
      
      // If we got real data (not fallback), use it
      if (!realForecast.containsKey('note')) {
        return realForecast;
      }
      
      // If real API failed, use improved simulation
      return _getSimulatedForecast(latitude, longitude);
    } catch (e) {
      debugPrint('Weather forecast service error: $e');
      return _getSimulatedForecast(latitude, longitude);
    }
  }

  /// Improved simulated weather based on location
  Map<String, dynamic> _getSimulatedWeather(double latitude, double longitude) {
    final baseTemp = _getBaseTemperature(latitude, longitude);
    final variation = (_random.nextDouble() - 0.5) * 6; // Reduced variation
    final temperature = baseTemp + variation;
    
    // More realistic rainfall based on season and location
    final rainfall = _getRealisticRainfall(latitude, longitude);
    
    return {
      'temperature': temperature,
      'humidity': 45 + _random.nextDouble() * 35, // 45-80%
      'rainfall': rainfall,
      'wind_speed': 2 + _random.nextDouble() * 12, // 2-14 km/h
      'condition': _getRealisticCondition(rainfall),
      'description': _getWeatherDescription(rainfall),
      'timestamp': DateTime.now().toIso8601String(),
      'location': 'Simulated Location',
      'source': 'simulation',
    };
  }

  /// Improved simulated forecast
  Map<String, dynamic> _getSimulatedForecast(double latitude, double longitude) {
    final baseTemp = _getBaseTemperature(latitude, longitude);
    final forecast = <Map<String, dynamic>>[];
    
    // Generate 5-day forecast with more realistic patterns
    for (int i = 1; i <= 5; i++) {
      final dayTemp = baseTemp + (_random.nextDouble() - 0.5) * 6;
      final dayRainfall = _getRealisticRainfall(latitude, longitude);
      
      final date = DateTime.now().add(Duration(days: i));
      forecast.add({
        'date': date.toIso8601String(),
        'temperature': dayTemp,
        'humidity': 50 + _random.nextDouble() * 30,
        'rainfall': dayRainfall,
        'condition': _getRealisticCondition(dayRainfall),
        'description': _getWeatherDescription(dayRainfall),
        'day_name': _getDayName(date),
      });
    }
    
    return {
      'forecast': forecast,
      'generated_at': DateTime.now().toIso8601String(),
      'location': 'Simulated Location',
      'source': 'simulation',
    };
  }

  /// Get base temperature based on latitude and season
  double _getBaseTemperature(double latitude, double longitude) {
    final now = DateTime.now();
    final month = now.month;
    
    // Seasonal adjustment for Pakistan
    double seasonalAdjustment = 0;
    if (month >= 3 && month <= 5) {
      seasonalAdjustment = 5; // Spring
    } else if (month >= 6 && month <= 8) {
      seasonalAdjustment = 8; // Summer
    } else if (month >= 9 && month <= 11) {
      seasonalAdjustment = 2; // Autumn
    } else {
      seasonalAdjustment = -3; // Winter
    }
    
    // Base temperature based on latitude
    final baseTemp = 32 - (latitude - 24) * 0.4;
    
    // Adjust for longitude (coastal areas are cooler)
    final longitudeAdjustment = (longitude - 60) * 0.05;
    
    return (baseTemp - longitudeAdjustment + seasonalAdjustment).clamp(5.0, 45.0);
  }

  /// Get realistic rainfall based on location and season
  double _getRealisticRainfall(double latitude, double longitude) {
    // For now, return 0 rainfall (no rain) to match reality
    // This will be replaced with real API data once you get the API key
    return 0.0;
  }

  /// Get realistic weather condition based on rainfall
  String _getRealisticCondition(double rainfall) {
    // Since we're setting rainfall to 0, always return clear weather
    if (rainfall > 1) {
      return 'rainy';
    } else {
      return 'clear';
    }
  }

  /// Get weather description
  String _getWeatherDescription(double rainfall) {
    // Since we're setting rainfall to 0, always return clear sky
    if (rainfall > 1) {
      return 'rain';
    } else {
      return 'clear sky';
    }
  }

  /// Get day name from date
  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}


