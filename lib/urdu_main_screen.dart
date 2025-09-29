import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../services/agricultural_database_service.dart';

class UrduMainScreen extends StatefulWidget {
  const UrduMainScreen({super.key});

  @override
  State<UrduMainScreen> createState() => _UrduMainScreenState();
}

class _UrduMainScreenState extends State<UrduMainScreen> {
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();
  
  // UI State
  bool _isLoading = false;
  bool _locationDetected = false;
  
  // Location and Crop State
  Position? _currentPosition;
  String? _currentLocationName;
  Map<String, dynamic>? _agriculturalZone;
  List<Map<String, dynamic>> _availableCrops = [];
  String? _selectedCrop;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize database
      await _dbService.initialize();
      
      // Request location permission
      await _requestLocationPermission();
      
      // Get current location
      await _getCurrentLocation();
      
      // Load available crops
      await _loadAvailableCrops();
      
      setState(() {
        _isLoading = false;
        _locationDetected = true;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('ایپ شروع کرنے میں خرابی: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      throw Exception('جگہ کی اجازت نہیں ملی');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      // Get agricultural zone
      _agriculturalZone = await _dbService.getAgriculturalZone(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      // Get location name
      final location = await _dbService.getLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      setState(() {
        _currentLocationName = location?['region_name_urdu'] ?? 
                              location?['region_name'] ?? 
                              'جگہ: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
      });
      
    } catch (e) {
      _showError('جگہ کا تعین نہیں ہو سکا: $e');
    }
  }

  Future<void> _loadAvailableCrops() async {
    try {
      final crops = await _dbService.getAllCrops();
      setState(() {
        _availableCrops = crops;
      });
    } catch (e) {
      _showError('فصلوں کی فہرست لوڈ کرنے میں خرابی: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredCrops() {
    if (_searchController.text.isEmpty) {
      return _availableCrops;
    }
    
    final searchText = _searchController.text.toLowerCase();
    return _availableCrops.where((crop) {
      return crop['name_urdu'].toLowerCase().contains(searchText) ||
             crop['name_english'].toLowerCase().contains(searchText);
    }).toList();
  }

  void _selectCrop(String cropName) {
    setState(() {
      _selectedCrop = cropName;
    });
    
    final cropInfo = _availableCrops.firstWhere(
      (crop) => crop['name_urdu'] == cropName,
      orElse: () => {},
    );
    
    if (cropInfo.isNotEmpty) {
      _showSuccess('${cropInfo['name_urdu']} منتخب کیا گیا');
    }
  }

  void _generateReport() {
    if (_selectedCrop == null) {
      _showError('برائے کرم پہلے فصل منتخب کریں');
      return;
    }
    
    // Navigate to report screen
    Navigator.of(context).pushNamed('/urdu-report', arguments: {
      'crop': _selectedCrop,
      'location': _currentLocationName,
      'agriculturalZone': _agriculturalZone,
      'position': _currentPosition,
    });
  }

  void _generateAdvice() {
    if (_selectedCrop == null) {
      _showError('برائے کرم پہلے فصل منتخب کریں');
      return;
    }
    
    // Navigate to advice screen
    Navigator.of(context).pushNamed('/urdu-advice', arguments: {
      'crop': _selectedCrop,
      'location': _currentLocationName,
      'agriculturalZone': _agriculturalZone,
      'position': _currentPosition,
    });
  }

  void _showCropDetails() {
    if (_selectedCrop == null) {
      _showError('برائے کرم پہلے فصل منتخب کریں');
      return;
    }
    
    final cropInfo = _availableCrops.firstWhere(
      (crop) => crop['name_urdu'] == _selectedCrop,
      orElse: () => {},
    );
    
    if (cropInfo.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          cropInfo['name_urdu'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cropInfo['scientific_name'] != null) ...[
                _buildInfoRow('سائنسی نام:', cropInfo['scientific_name']),
                const SizedBox(height: 8),
              ],
              if (cropInfo['planting_months'] != null) ...[
                _buildInfoRow('بونے کا وقت:', _parseMonths(cropInfo['planting_months'])),
                const SizedBox(height: 8),
              ],
              if (cropInfo['harvest_months'] != null) ...[
                _buildInfoRow('کٹائی کا وقت:', _parseMonths(cropInfo['harvest_months'])),
                const SizedBox(height: 8),
              ],
              if (cropInfo['growing_period_days'] != null) ...[
                _buildInfoRow('بڑھنے کا دورانیہ:', '${cropInfo['growing_period_days']} دن'),
                const SizedBox(height: 8),
              ],
              if (cropInfo['yield_per_acre'] != null) ...[
                _buildInfoRow('فی ایکڑ پیداوار:', cropInfo['yield_per_acre']),
                const SizedBox(height: 8),
              ],
              if (cropInfo['soil_requirements'] != null) ...[
                _buildInfoRow('مٹی کی ضرورت:', cropInfo['soil_requirements']),
                const SizedBox(height: 8),
              ],
              if (cropInfo['water_requirements'] != null) ...[
                _buildInfoRow('پانی کی ضرورت:', cropInfo['water_requirements']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بند کریں', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _parseMonths(String monthsJson) {
    try {
      final months = List<String>.from(json.decode(monthsJson));
      return months.join(', ');
    } catch (e) {
      return monthsJson;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'زرعی مشیر',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'ایپ شروع ہو رہا ہے...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
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
                              const Expanded(
                                child: Text(
                                  'خوش آمدید!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'آپ کا ذاتی زرعی مشیر',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'بہترین فصلوں اور زرعی مشورے کے لیے',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Location Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.blue.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'آپ کی جگہ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentLocationName ?? 'جگہ کا تعین نہیں ہو سکا',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (_agriculturalZone != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'زرعی علاقہ: ${_agriculturalZone!['zone_name_urdu']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Crop Selection Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.eco,
                                color: Colors.green.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'فصل منتخب کریں',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Search Field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'فصل کا نام تلاش کریں...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.green.shade600),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Crop Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: _getFilteredCrops().length,
                            itemBuilder: (context, index) {
                              final crop = _getFilteredCrops()[index];
                              final isSelected = _selectedCrop == crop['name_urdu'];
                              
                              return GestureDetector(
                                onTap: () => _selectCrop(crop['name_urdu']),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.shade100 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      crop['name_urdu'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.green.shade700 : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          if (_selectedCrop != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'منتخب شدہ: $_selectedCrop',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showCropDetails,
                                    child: const Text('تفصیلات'),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          onPressed: _selectedCrop != null ? _generateReport : null,
                          icon: const Icon(Icons.assessment, size: 24),
                          label: const Text(
                            'زرعی رپورٹ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedCrop != null ? _generateAdvice : null,
                          icon: const Icon(Icons.lightbulb, size: 24),
                          label: const Text(
                            'زرعی مشورہ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Help Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline, color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'کیسے استعمال کریں',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('1. اپنی جگہ کا تعین ہو جانے کا انتظار کریں'),
                          const Text('2. فصل کا نام تلاش کریں یا گرڈ سے منتخب کریں'),
                          const Text('3. "زرعی رپورٹ" یا "زرعی مشورہ" پر کلک کریں'),
                          const Text('4. تفصیلی معلومات حاصل کریں'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
