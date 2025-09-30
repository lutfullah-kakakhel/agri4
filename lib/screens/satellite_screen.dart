import 'package:flutter/material.dart';
import 'dart:convert';

class SatelliteScreen extends StatefulWidget {
  final dynamic position;
  final String? locationName;
  final String? districtName;
  final String? provinceName;
  final Map<String, dynamic>? agriculturalZone;
  final Map<String, dynamic>? locationDetails;
  final String? selectedCrop;
  final Map<String, dynamic>? cropInfo;
  final Map<String, dynamic>? currentWeather;
  final Map<String, dynamic>? forecast;
  final List<Map<String, dynamic>>? weatherRecommendations;

  const SatelliteScreen({
    super.key,
    required this.position,
    this.locationName,
    this.districtName,
    this.provinceName,
    this.agriculturalZone,
    this.locationDetails,
    this.selectedCrop,
    this.cropInfo,
    this.currentWeather,
    this.forecast,
    this.weatherRecommendations,
  });

  @override
  State<SatelliteScreen> createState() => _SatelliteScreenState();
}

class _SatelliteScreenState extends State<SatelliteScreen> {
  Map<String, dynamic>? _ndviData;
  Map<String, dynamic>? _satelliteImagery;
  List<Map<String, dynamic>> _satelliteRecommendations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSatelliteData();
  }

  Future<void> _loadSatelliteData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulate loading satellite data
      await Future.delayed(const Duration(seconds: 3));
      
      // Generate simulated NDVI data
      _ndviData = _generateNDVIData();
      
      // Generate simulated satellite imagery data
      _satelliteImagery = _generateSatelliteImagery();
      
      // Generate satellite-based recommendations
      _satelliteRecommendations = _generateSatelliteRecommendations();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'سیٹلائٹ ڈیٹا لوڈ کرنے میں خرابی: $e';
      });
    }
  }

  Map<String, dynamic> _generateNDVIData() {
    // Simulate NDVI (Normalized Difference Vegetation Index) data
    final ndvi = 0.3 + (0.7 * (0.5 + (0.5 * (widget.position.latitude - 24) / 13)));
    final vegetationHealth = _getVegetationHealth(ndvi);
    
    return {
      'ndvi_value': ndvi,
      'vegetation_health': vegetationHealth,
      'crop_health_score': (ndvi * 100).round(),
      'soil_moisture': 0.4 + (ndvi * 0.4), // Correlate with NDVI
      'analysis_date': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _generateSatelliteImagery() {
    return {
      'image_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'resolution': '10m',
      'cloud_cover': 15.0,
      'image_quality': 'good',
      'processing_status': 'completed',
    };
  }

  List<Map<String, dynamic>> _generateSatelliteRecommendations() {
    final recommendations = <Map<String, dynamic>>[];
    
    if (_ndviData == null) return recommendations;
    
    final ndvi = _ndviData!['ndvi_value'] as double;
    final cropHealth = _ndviData!['crop_health_score'] as int;
    final soilMoisture = _ndviData!['soil_moisture'] as double;
    
    // NDVI-based recommendations
    if (ndvi < 0.3) {
      recommendations.add({
        'type': 'vegetation',
        'title': 'کمزور پودے',
        'message': 'NDVI کم ہے۔ پودوں کی صحت بہتر کرنے کے لیے کھاد اور پانی کا خیال رکھیں۔',
        'priority': 'high',
        'icon': Icons.eco,
        'color': Colors.red,
      });
    } else if (ndvi > 0.7) {
      recommendations.add({
        'type': 'vegetation',
        'title': 'اچھے پودے',
        'message': 'NDVI اچھا ہے۔ پودے صحت مند نظر آتے ہیں۔',
        'priority': 'low',
        'icon': Icons.eco,
        'color': Colors.green,
      });
    }
    
    // Soil moisture recommendations
    if (soilMoisture < 0.3) {
      recommendations.add({
        'type': 'soil',
        'title': 'مٹی خشک',
        'message': 'مٹی میں نمی کم ہے۔ پانی کی مقدار بڑھائیں۔',
        'priority': 'high',
        'icon': Icons.terrain,
        'color': Colors.orange,
      });
    } else if (soilMoisture > 0.8) {
      recommendations.add({
        'type': 'soil',
        'title': 'زیادہ نمی',
        'message': 'مٹی میں نمی زیادہ ہے۔ نکاسی آب کا خیال رکھیں۔',
        'priority': 'medium',
        'icon': Icons.terrain,
        'color': Colors.blue,
      });
    }
    
    // Crop-specific recommendations
    if (widget.cropInfo != null) {
      final cropName = widget.cropInfo!['name_urdu'] as String?;
      
      if (cropName == 'گندم' && ndvi < 0.4) {
        recommendations.add({
          'type': 'crop_specific',
          'title': 'گندم کی دیکھ بھال',
          'message': 'گندم کی صحت بہتر کرنے کے لیے نائٹروجن کھاد استعمال کریں۔',
          'priority': 'medium',
          'icon': Icons.agriculture,
          'color': Colors.brown,
        });
      } else if (cropName == 'چاول' && soilMoisture < 0.5) {
        recommendations.add({
          'type': 'crop_specific',
          'title': 'چاول کی دیکھ بھال',
          'message': 'چاول کو زیادہ پانی کی ضرورت ہے۔ کھیت میں پانی کی سطح بڑھائیں۔',
          'priority': 'high',
          'icon': Icons.agriculture,
          'color': Colors.blue,
        });
      }
    }
    
    return recommendations;
  }

  String _getVegetationHealth(double ndvi) {
    if (ndvi < 0.2) return 'بہت کمزور';
    if (ndvi < 0.3) return 'کمزور';
    if (ndvi < 0.4) return 'عام';
    if (ndvi < 0.6) return 'اچھا';
    if (ndvi < 0.8) return 'بہت اچھا';
    return 'بہترین';
  }

  String _getNDVIColor(double ndvi) {
    if (ndvi < 0.2) return 'بہت کمزور (سرخ)';
    if (ndvi < 0.3) return 'کمزور (نارنجی)';
    if (ndvi < 0.4) return 'عام (پیلا)';
    if (ndvi < 0.6) return 'اچھا (ہلکا سبز)';
    if (ndvi < 0.8) return 'بہت اچھا (سبز)';
    return 'بہترین (گہرا سبز)';
  }

  void _generateFinalReport() {
    // Navigate to final report screen
    Navigator.of(context).pushNamed('/final-report', arguments: {
      'position': widget.position,
      'locationName': widget.locationName,
      'districtName': widget.districtName,
      'provinceName': widget.provinceName,
      'agriculturalZone': widget.agriculturalZone,
      'locationDetails': widget.locationDetails,
      'selectedCrop': widget.selectedCrop,
      'cropInfo': widget.cropInfo,
      'currentWeather': widget.currentWeather,
      'forecast': widget.forecast,
      'weatherRecommendations': widget.weatherRecommendations,
      'ndviData': _ndviData,
      'satelliteImagery': _satelliteImagery,
      'satelliteRecommendations': _satelliteRecommendations,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سیٹلائٹ ڈیٹا',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade700,
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
                    'سیٹلائٹ ڈیٹا لوڈ ہو رہا ہے...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'یہ کچھ وقت لگ سکتا ہے',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildSatelliteScreen(),
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
              Icons.satellite_alt,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'سیٹلائٹ ڈیٹا دستیاب نہیں',
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
              onPressed: _loadSatelliteData,
              icon: const Icon(Icons.refresh),
              label: const Text('دوبارہ کوشش کریں'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatelliteScreen() {
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
                  Icon(
                    Icons.satellite_alt,
                    size: 48,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'سیٹلائٹ ڈیٹا تجزیہ',
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
          
          // NDVI Data Card
          if (_ndviData != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NDVI تجزیہ (پودوں کی صحت)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildNDVIInfo(
                            'NDVI ویلیو',
                            '${(_ndviData!['ndvi_value'] as double).toStringAsFixed(3)}',
                            '0.0 - 1.0',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNDVIInfo(
                            'صحت کا اسکور',
                            '${_ndviData!['crop_health_score']}%',
                            '0% - 100%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildNDVIInfo(
                            'پودوں کی صحت',
                            _ndviData!['vegetation_health'],
                            _getNDVIColor(_ndviData!['ndvi_value'] as double),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNDVIInfo(
                            'مٹی کی نمی',
                            '${((_ndviData!['soil_moisture'] as double) * 100).toStringAsFixed(1)}%',
                            '0% - 100%',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Satellite Imagery Card
          if (_satelliteImagery != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سیٹلائٹ تصاویر',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSatelliteInfo('تصویر کی تاریخ', _formatDate(_satelliteImagery!['image_date'])),
                    const SizedBox(height: 8),
                    _buildSatelliteInfo('رزلوشن', _satelliteImagery!['resolution']),
                    const SizedBox(height: 8),
                    _buildSatelliteInfo('بادلوں کا احاطہ', '${_satelliteImagery!['cloud_cover']}%'),
                    const SizedBox(height: 8),
                    _buildSatelliteInfo('تصویر کی کوالٹی', _satelliteImagery!['image_quality']),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Satellite Recommendations
          if (_satelliteRecommendations.isNotEmpty) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سیٹلائٹ کی بنیاد پر تجاویز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._satelliteRecommendations.map((rec) => 
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
                  onPressed: _generateFinalReport,
                  icon: const Icon(Icons.assessment),
                  label: const Text('رپورٹ بنائیں'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
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

  Widget _buildNDVIInfo(String label, String value, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}


