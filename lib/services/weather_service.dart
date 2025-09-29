import 'dart:math';

class WeatherService {
  final Random _random = Random();

  /// Get current weather data (simulated)
  Future<Map<String, dynamic>> getCurrentWeather(double latitude, double longitude) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate simulated weather data based on location
    final baseTemp = _getBaseTemperature(latitude, longitude);
    final variation = (_random.nextDouble() - 0.5) * 10; // ±5°C variation
    final temperature = baseTemp + variation;
    
    return {
      'temperature': temperature,
      'humidity': 40 + _random.nextDouble() * 40, // 40-80%
      'rainfall': _random.nextDouble() * 25, // 0-25mm
      'wind_speed': _random.nextDouble() * 20, // 0-20 km/h
      'condition': _getRandomCondition(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get weather forecast (simulated)
  Future<Map<String, dynamic>> getWeatherForecast(double latitude, double longitude) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    final baseTemp = _getBaseTemperature(latitude, longitude);
    final forecast = <Map<String, dynamic>>[];
    
    // Generate 7-day forecast
    for (int i = 1; i <= 7; i++) {
      final dayTemp = baseTemp + (_random.nextDouble() - 0.5) * 8;
      forecast.add({
        'date': DateTime.now().add(Duration(days: i)).toIso8601String(),
        'temperature': dayTemp,
        'humidity': 40 + _random.nextDouble() * 40,
        'rainfall': _random.nextDouble() * 20,
        'wind_speed': _random.nextDouble() * 15,
        'condition': _getRandomCondition(),
      });
    }
    
    return {
      'forecast': forecast,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get base temperature based on latitude (rough approximation)
  double _getBaseTemperature(double latitude, double longitude) {
    // Pakistan is roughly between 24°N and 37°N
    // Base temperature decreases with latitude
    final baseTemp = 35 - (latitude - 24) * 0.5; // Rough approximation
    
    // Adjust for longitude (Pakistan is roughly 60°E to 75°E)
    // Coastal areas (western Pakistan) tend to be cooler
    final longitudeAdjustment = (longitude - 60) * 0.1;
    
    return (baseTemp - longitudeAdjustment).clamp(10.0, 40.0);
  }

  /// Get random weather condition
  String _getRandomCondition() {
    final conditions = ['sunny', 'cloudy', 'rainy', 'clear', 'overcast'];
    return conditions[_random.nextInt(conditions.length)];
  }
}
