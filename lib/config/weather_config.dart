class WeatherConfig {
  // OpenWeatherMap API Configuration
  // Get your free API key from: https://openweathermap.org/api
  
  // IMPORTANT: Replace this with your actual OpenWeatherMap API key
  static const String openWeatherMapApiKey = '2b92acfdb08bac9746248ed2051558a1';
  
  // Alternative: Use environment variable (recommended for production)
  // static const String openWeatherMapApiKey = String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: 'demo_key_replace_with_your_key');
  
  // API Configuration
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String units = 'metric'; // Celsius
  static const int timeoutSeconds = 10;
  
  // Fallback Configuration
  static const bool useFallbackData = true; // Use improved simulation when API fails
  static const bool showApiStatus = true; // Show whether real or simulated data is being used
}
