import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/agricultural_database_service.dart';

class UrduReportScreen extends StatefulWidget {
  final String cropName;
  final String? locationName;
  final Map<String, dynamic>? agriculturalZone;
  final dynamic position;

  const UrduReportScreen({
    super.key,
    required this.cropName,
    this.locationName,
    this.agriculturalZone,
    this.position,
  });

  @override
  State<UrduReportScreen> createState() => _UrduReportScreenState();
}

class _UrduReportScreenState extends State<UrduReportScreen> {
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();
  
  Map<String, dynamic>? _cropInfo;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCropInfo();
  }

  Future<void> _loadCropInfo() async {
    try {
      final cropInfo = await _dbService.getCropByName(widget.cropName);
      if (cropInfo != null) {
        setState(() {
          _cropInfo = cropInfo;
          _recommendations = _generateRecommendations(cropInfo);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('رپورٹ لوڈ کرنے میں خرابی: $e');
    }
  }

  List<Map<String, dynamic>> _generateRecommendations(Map<String, dynamic> cropInfo) {
    final recommendations = <Map<String, dynamic>>[];
    
    // Planting season recommendation
    final plantingMonths = jsonDecode(cropInfo['planting_months'] as String) as List;
    final currentMonth = DateTime.now().month;
    final currentMonthName = _getMonthName(currentMonth);
    
    if (plantingMonths.contains(currentMonthName)) {
      recommendations.add({
        'type': 'planting',
        'title': 'بونے کا وقت',
        'message': 'یہ ${cropInfo['name_urdu']} بونے کا صحیح وقت ہے',
        'priority': 'high',
        'icon': Icons.schedule,
        'color': Colors.green,
      });
    } else {
      final nextPlantingMonth = plantingMonths.first;
      recommendations.add({
        'type': 'planting',
        'title': 'بونے کا وقت',
        'message': 'اگلی بونے کا وقت: $nextPlantingMonth',
        'priority': 'medium',
        'icon': Icons.schedule,
        'color': Colors.orange,
      });
    }

    // Soil requirements
    recommendations.add({
      'type': 'soil',
      'title': 'مٹی کی ضرورت',
      'message': 'یقینی بنائیں کہ مٹی ${cropInfo['soil_requirements']} ہے',
      'priority': 'high',
      'icon': Icons.terrain,
      'color': Colors.brown,
    });

    // Water requirements
    recommendations.add({
      'type': 'water',
      'title': 'پانی کی ضرورت',
      'message': 'پانی کی ضرورت: ${cropInfo['water_requirements']}',
      'priority': 'medium',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    });

    // Yield information
    if (cropInfo['yield_per_acre'] != null) {
      recommendations.add({
        'type': 'yield',
        'title': 'متوقع پیداوار',
        'message': 'فی ایکڑ پیداوار: ${cropInfo['yield_per_acre']}',
        'priority': 'medium',
        'icon': Icons.analytics,
        'color': Colors.purple,
      });
    }

    // Growing period
    if (cropInfo['growing_period_days'] != null) {
      recommendations.add({
        'type': 'period',
        'title': 'بڑھنے کا دورانیہ',
        'message': 'یہ فصل ${cropInfo['growing_period_days']} دن میں تیار ہوتی ہے',
        'priority': 'low',
        'icon': Icons.timeline,
        'color': Colors.teal,
      });
    }

    return recommendations;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _parseMonths(String monthsJson) {
    try {
      final months = List<String>.from(json.decode(monthsJson));
      return months.join(', ');
    } catch (e) {
      return monthsJson;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'زرعی رپورٹ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cropInfo == null
              ? const Center(
                  child: Text(
                    'رپورٹ دستیاب نہیں',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.agriculture,
                                    size: 32,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _cropInfo!['name_urdu'],
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_cropInfo!['scientific_name'] != null)
                                          Text(
                                            '(${_cropInfo!['scientific_name']})',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (widget.locationName != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'جگہ: ${widget.locationName}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (widget.agriculturalZone != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.map, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'زرعی علاقہ: ${widget.agriculturalZone!['zone_name_urdu']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Basic Information Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'بنیادی معلومات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              if (_cropInfo!['planting_months'] != null) ...[
                                _buildInfoRow(
                                  Icons.schedule,
                                  'بونے کا وقت',
                                  _parseMonths(_cropInfo!['planting_months']),
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (_cropInfo!['harvest_months'] != null) ...[
                                _buildInfoRow(
                                  Icons.grass,
                                  'کٹائی کا وقت',
                                  _parseMonths(_cropInfo!['harvest_months']),
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (_cropInfo!['growing_period_days'] != null) ...[
                                _buildInfoRow(
                                  Icons.timeline,
                                  'بڑھنے کا دورانیہ',
                                  '${_cropInfo!['growing_period_days']} دن',
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (_cropInfo!['yield_per_acre'] != null) ...[
                                _buildInfoRow(
                                  Icons.analytics,
                                  'متوقع پیداوار',
                                  _cropInfo!['yield_per_acre'],
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (_cropInfo!['soil_requirements'] != null) ...[
                                _buildInfoRow(
                                  Icons.terrain,
                                  'مٹی کی ضرورت',
                                  _cropInfo!['soil_requirements'],
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (_cropInfo!['water_requirements'] != null) ...[
                                _buildInfoRow(
                                  Icons.water_drop,
                                  'پانی کی ضرورت',
                                  _cropInfo!['water_requirements'],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Recommendations Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'زرعی تجاویز',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              ..._recommendations.map((rec) => 
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
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('واپس جائیں'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to advice screen
                                Navigator.of(context).pushNamed('/urdu-advice', arguments: {
                                  'crop': widget.cropName,
                                  'location': widget.locationName,
                                  'agriculturalZone': widget.agriculturalZone,
                                  'position': widget.position,
                                });
                              },
                              icon: const Icon(Icons.lightbulb),
                              label: const Text('مشورہ لیں'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
