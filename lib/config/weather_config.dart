import 'api_keys.dart';

class WeatherConfig {
  // OpenWeatherMap API Configuration
  // Get your free API key from: https://openweathermap.org/api
  
  // SECURITY: API key is now stored in a separate file (api_keys.dart)
  // Make sure to:
  // 1. Add your actual API key to lib/config/api_keys.dart
  // 2. Add api_keys.dart to .gitignore
  // 3. Never commit API keys to version control
  
  static const String openWeatherMapApiKey = ApiKeys.openWeatherMapApiKey;
  
  // API Configuration
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String units = 'metric'; // Celsius
  static const int timeoutSeconds = 10;
  
  // Fallback Configuration
  static const bool useFallbackData = true; // Use improved simulation when API fails
  static const bool showApiStatus = true; // Show whether real or simulated data is being used
}
