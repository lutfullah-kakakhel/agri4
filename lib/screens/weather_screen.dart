import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  final dynamic position;
  final String? locationName;
  final String? districtName;
  final String? provinceName;
  final Map<String, dynamic>? agriculturalZone;
  final Map<String, dynamic>? locationDetails;
  final String? selectedCrop;
  final Map<String, dynamic>? cropInfo;

  const WeatherScreen({
    super.key,
    required this.position,
    this.locationName,
    this.districtName,
    this.provinceName,
    this.agriculturalZone,
    this.locationDetails,
    this.selectedCrop,
    this.cropInfo,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _forecast;
  List<Map<String, dynamic>> _weatherRecommendations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.position != null) {
        // Load current weather
        _currentWeather = await _weatherService.getCurrentWeather(
          widget.position.latitude,
          widget.position.longitude,
        );
        
        // Load weather forecast
        _forecast = await _weatherService.getWeatherForecast(
          widget.position.latitude,
          widget.position.longitude,
        );
        
        // Generate weather recommendations for the selected crop
        _weatherRecommendations = _generateWeatherRecommendations();
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'موسمی معلومات لوڈ کرنے میں خرابی: $e';
      });
    }
  }

  List<Map<String, dynamic>> _generateWeatherRecommendations() {
    final recommendations = <Map<String, dynamic>>[];
    
    if (_currentWeather == null || widget.cropInfo == null) return recommendations;
    
    final temperature = _currentWeather!['temperature'] as double?;
    final humidity = _currentWeather!['humidity'] as double?;
    final rainfall = _currentWeather!['rainfall'] as double?;
    final windSpeed = _currentWeather!['wind_speed'] as double?;
    
    // Temperature recommendations
    if (temperature != null) {
      if (temperature < 10) {
        recommendations.add({
          'type': 'temperature',
          'title': 'کم درجہ حرارت',
          'message': 'درجہ حرارت کم ہے۔ فصل کی حفاظت کا خیال رکھیں۔',
          'priority': 'high',
          'icon': Icons.thermostat,
          'color': Colors.blue,
        });
      } else if (temperature > 35) {
        recommendations.add({
          'type': 'temperature',
          'title': 'زیادہ درجہ حرارت',
          'message': 'درجہ حرارت زیادہ ہے۔ اضافی پانی دیں اور سایہ فراہم کریں۔',
          'priority': 'high',
          'icon': Icons.wb_sunny,
          'color': Colors.red,
        });
      } else {
        recommendations.add({
          'type': 'temperature',
          'title': 'موافق درجہ حرارت',
          'message': 'درجہ حرارت آپ کی فصل کے لیے موافق ہے۔',
          'priority': 'low',
          'icon': Icons.thermostat,
          'color': Colors.green,
        });
      }
    }
    
    // Humidity recommendations
    if (humidity != null) {
      if (humidity > 80) {
        recommendations.add({
          'type': 'humidity',
          'title': 'زیادہ نمی',
          'message': 'نمی زیادہ ہے۔ بیماریوں سے بچاؤ کا خیال رکھیں۔',
          'priority': 'medium',
          'icon': Icons.water_drop,
          'color': Colors.blue,
        });
      } else if (humidity < 30) {
        recommendations.add({
          'type': 'humidity',
          'title': 'کم نمی',
          'message': 'نمی کم ہے۔ پانی کی مقدار بڑھائیں۔',
          'priority': 'medium',
          'icon': Icons.water_drop,
          'color': Colors.orange,
        });
      }
    }
    
    // Rainfall recommendations
    if (rainfall != null) {
      if (rainfall > 20) {
        recommendations.add({
          'type': 'rainfall',
          'title': 'زیادہ بارش',
          'message': 'زیادہ بارش ہو رہی ہے۔ نکاسی آب کا خیال رکھیں۔',
          'priority': 'high',
          'icon': Icons.cloud,
          'color': Colors.blue,
        });
      } else if (rainfall == 0 && widget.cropInfo!['water_requirements'] == 'High') {
        recommendations.add({
          'type': 'rainfall',
          'title': 'پانی کی کمی',
          'message': 'بارش نہیں ہو رہی۔ آپ کی فصل کو اضافی پانی کی ضرورت ہے۔',
          'priority': 'high',
          'icon': Icons.water_drop,
          'color': Colors.red,
        });
      }
    }
    
    // Wind recommendations
    if (windSpeed != null && windSpeed > 15) {
      recommendations.add({
        'type': 'wind',
        'title': 'تیز ہوا',
        'message': 'تیز ہوا چل رہی ہے۔ پودوں کی حفاظت کا خیال رکھیں۔',
        'priority': 'medium',
        'icon': Icons.air,
        'color': Colors.grey,
      });
    }
    
    return recommendations;
  }

  String _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rainy':
      case 'rain':
        return '🌧️';
      case 'stormy':
        return '⛈️';
      case 'snowy':
        return '❄️';
      case 'foggy':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  String _getTemperatureColor(double temperature) {
    if (temperature < 10) return 'سرد';
    if (temperature < 20) return 'ٹھنڈا';
    if (temperature < 30) return 'موافق';
    if (temperature < 35) return 'گرم';
    return 'بہت گرم';
  }

  void _proceedToSatellite() {
    // Navigate to satellite data screen
    Navigator.of(context).pushNamed('/satellite', arguments: {
      'position': widget.position,
      'locationName': widget.locationName,
      'districtName': widget.districtName,
      'provinceName': widget.provinceName,
      'agriculturalZone': widget.agriculturalZone,
      'locationDetails': widget.locationDetails,
      'selectedCrop': widget.selectedCrop,
      'cropInfo': widget.cropInfo,
      'currentWeather': _currentWeather,
      'forecast': _forecast,
      'weatherRecommendations': _weatherRecommendations,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'موسمی معلومات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'موسمی معلومات لوڈ ہو رہی ہے...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildWeatherScreen(),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'موسمی معلومات دستیاب نہیں',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadWeatherData,
              icon: const Icon(Icons.refresh),
              label: const Text('دوبارہ کوشش کریں'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _getWeatherIcon(_currentWeather?['condition']),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'موجودہ موسم',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.locationName ?? 'نامعلوم جگہ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current Weather Card
          if (_currentWeather != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'موجودہ موسمی حالات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildWeatherInfo(
                            Icons.thermostat,
                            'درجہ حرارت',
                            '${_currentWeather!['temperature']?.toStringAsFixed(1) ?? 'نامعلوم'}°C',
                            _getTemperatureColor(_currentWeather!['temperature'] ?? 0),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildWeatherInfo(
                            Icons.water_drop,
                            'نمی',
                            '${_currentWeather!['humidity']?.toStringAsFixed(0) ?? 'نامعلوم'}%',
                            _currentWeather!['humidity'] != null 
                                ? (_currentWeather!['humidity'] > 70 ? 'زیادہ' : 'موافق')
                                : 'نامعلوم',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildWeatherInfo(
                            Icons.cloud,
                            'بارش',
                            '${_currentWeather!['rainfall']?.toStringAsFixed(1) ?? '0'}mm',
                            _currentWeather!['rainfall'] != null 
                                ? (_currentWeather!['rainfall'] > 10 ? 'زیادہ' : 'کم')
                                : 'نامعلوم',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildWeatherInfo(
                            Icons.air,
                            'ہوا کی رفتار',
                            '${_currentWeather!['wind_speed']?.toStringAsFixed(1) ?? 'نامعلوم'} km/h',
                            _currentWeather!['wind_speed'] != null 
                                ? (_currentWeather!['wind_speed'] > 15 ? 'تیز' : 'موافق')
                                : 'نامعلوم',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Weather Recommendations
          if (_weatherRecommendations.isNotEmpty) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'موسمی تجاویز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._weatherRecommendations.map((rec) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (rec['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (rec['color'] as Color).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              rec['icon'],
                              color: rec['color'],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: rec['color'],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rec['message'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: rec['priority'] == 'high' 
                                    ? Colors.red.shade100 
                                    : rec['priority'] == 'medium'
                                        ? Colors.orange.shade100
                                        : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rec['priority'] == 'high' 
                                    ? 'اہم' 
                                    : rec['priority'] == 'medium'
                                        ? 'درمیانی'
                                        : 'عام',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: rec['priority'] == 'high' 
                                      ? Colors.red.shade700 
                                      : rec['priority'] == 'medium'
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('واپس جائیں'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _proceedToSatellite,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('آگے بڑھیں'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}



