import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../services/agricultural_database_service.dart';
import '../widgets/simple_map_widget.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();
  
  bool _isLoading = true;
  bool _locationDetected = false;
  Position? _currentPosition;
  String? _currentLocationName;
  String? _districtName;
  String? _provinceName;
  Map<String, dynamic>? _agriculturalZone;
  Map<String, dynamic>? _locationDetails;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Initialize database
      await _dbService.initialize();
      
      // Request location permission
      await _requestLocationPermission();
      
      // Get current location
      await _getCurrentLocation();
      
      // Get location details
      await _getLocationDetails();
      
      setState(() {
        _isLoading = false;
        _locationDetected = true;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'جگہ کا تعین کرنے میں خرابی: $e';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      throw Exception('جگہ کی اجازت نہیں ملی۔ برائے کرم اجازت دیں۔');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      throw Exception('GPS سے جگہ کا تعین نہیں ہو سکا۔ انٹرنیٹ کنکشن چیک کریں۔');
    }
  }

  Future<void> _getLocationDetails() async {
    if (_currentPosition == null) return;
    
    try {
      // Get agricultural zone
      _agriculturalZone = await _dbService.getAgriculturalZone(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      // Get detailed location information
      _locationDetails = await _dbService.getLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (_locationDetails != null) {
        _currentLocationName = _locationDetails!['region_name_urdu'] ?? 
                              _locationDetails!['region_name'] ?? 
                              'نامعلوم علاقہ';
        _districtName = _locationDetails!['district_urdu'] ?? 
                       _locationDetails!['district'] ?? 
                       'نامعلوم ضلع';
        _provinceName = _locationDetails!['province_urdu'] ?? 
                       _locationDetails!['province'] ?? 
                       'نامعلوم صوبہ';
      } else {
        // Fallback to coordinates if no detailed location found
        _currentLocationName = 'جگہ: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
        _districtName = 'نامعلوم ضلع';
        _provinceName = 'نامعلوم صوبہ';
      }
      
    } catch (e) {
      // If database lookup fails, use coordinates
      _currentLocationName = 'جگہ: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
      _districtName = 'نامعلوم ضلع';
      _provinceName = 'نامعلوم صوبہ';
    }
  }

  void _confirmLocation() {
    if (_currentPosition == null) return;
    
    // Navigate to crop selection screen
    Navigator.of(context).pushNamed('/crop-selection', arguments: {
      'position': _currentPosition,
      'locationName': _currentLocationName,
      'districtName': _districtName,
      'provinceName': _provinceName,
      'agriculturalZone': _agriculturalZone,
      'locationDetails': _locationDetails,
    });
  }

  void _retryLocation() {
    _initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'جگہ کا تعین',
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
                    'آپ کی جگہ کا تعین ہو رہا ہے...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'GPS اور انٹرنیٹ کنکشن کا انتظار کر رہے ہیں',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildLocationConfirmationScreen(),
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
              Icons.location_off,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'جگہ کا تعین نہیں ہو سکا',
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
              onPressed: _retryLocation,
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

  Widget _buildLocationConfirmationScreen() {
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
                    Icons.location_on,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'آپ کی جگہ کا تعین ہو گیا ہے',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'برائے کرم تصدیق کریں کہ یہ صحیح جگہ ہے',
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
          
          // Map Widget
          if (_currentPosition != null)
            SimpleMapWidget(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              locationName: _currentLocationName,
              height: 200,
            ),
          
          if (_currentPosition != null) const SizedBox(height: 24),
          
          // Location Details Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جگہ کی تفصیلات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLocationRow(
                    Icons.location_city,
                    'علاقہ',
                    _currentLocationName ?? 'نامعلوم',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLocationRow(
                    Icons.map,
                    'ضلع',
                    _districtName ?? 'نامعلوم',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLocationRow(
                    Icons.flag,
                    'صوبہ',
                    _provinceName ?? 'نامعلوم',
                  ),
                  const SizedBox(height: 16),
                  
                  if (_agriculturalZone != null) ...[
                    _buildLocationRow(
                      Icons.agriculture,
                      'زرعی علاقہ',
                      _agriculturalZone!['zone_name_urdu'] ?? 
                      _agriculturalZone!['zone_name'] ?? 'نامعلوم',
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildLocationRow(
                    Icons.gps_fixed,
                    'GPS کوآرڈینیٹس',
                    '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Agricultural Zone Information
          if (_agriculturalZone != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'زرعی علاقے کی معلومات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_agriculturalZone!['soil_type'] != null) ...[
                      _buildInfoRow('مٹی کی قسم', _agriculturalZone!['soil_type']),
                      const SizedBox(height: 12),
                    ],
                    
                    if (_agriculturalZone!['climate_zone'] != null) ...[
                      _buildInfoRow('موسمی زون', _agriculturalZone!['climate_zone']),
                      const SizedBox(height: 12),
                    ],
                    
                    if (_agriculturalZone!['suitable_crops'] != null) ...[
                      _buildInfoRow(
                        'موزوں فصلیں',
                        _parseJsonArray(_agriculturalZone!['suitable_crops']),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retryLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('دوبارہ کوشش کریں'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                    side: BorderSide(color: Colors.blue.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmLocation,
                  icon: const Icon(Icons.check),
                  label: const Text('یہ صحیح ہے'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Help Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'معلومات',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'اگر جگہ غلط ہے تو "دوبارہ کوشش کریں" پر کلک کریں۔ اگر جگہ صحیح ہے تو "یہ صحیح ہے" پر کلک کرکے آگے بڑھیں۔',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  String _parseJsonArray(String jsonString) {
    try {
      final List<dynamic> list = json.decode(jsonString);
      return list.join(', ');
    } catch (e) {
      return jsonString;
    }
  }
}
