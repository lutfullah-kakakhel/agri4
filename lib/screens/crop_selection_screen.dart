import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/agricultural_database_service.dart';

class CropSelectionScreen extends StatefulWidget {
  final dynamic position;
  final String? locationName;
  final String? districtName;
  final String? provinceName;
  final Map<String, dynamic>? agriculturalZone;
  final Map<String, dynamic>? locationDetails;

  const CropSelectionScreen({
    super.key,
    required this.position,
    this.locationName,
    this.districtName,
    this.provinceName,
    this.agriculturalZone,
    this.locationDetails,
  });

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();
  
  List<Map<String, dynamic>> _availableCrops = [];
  String? _selectedCrop;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final crops = await _dbService.getAllCrops();
      setState(() {
        _availableCrops = crops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فصلوں کی فہرست لوڈ کرنے میں خرابی: $e';
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cropInfo['name_urdu']} منتخب کیا گیا'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCropDetails(String cropName) {
    final cropInfo = _availableCrops.firstWhere(
      (crop) => crop['name_urdu'] == cropName,
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
                _buildDetailRow('سائنسی نام:', cropInfo['scientific_name']),
                const SizedBox(height: 8),
              ],
              if (cropInfo['planting_months'] != null) ...[
                _buildDetailRow('بونے کا وقت:', _parseMonths(cropInfo['planting_months'])),
                const SizedBox(height: 8),
              ],
              if (cropInfo['harvest_months'] != null) ...[
                _buildDetailRow('کٹائی کا وقت:', _parseMonths(cropInfo['harvest_months'])),
                const SizedBox(height: 8),
              ],
              if (cropInfo['growing_period_days'] != null) ...[
                _buildDetailRow('بڑھنے کا دورانیہ:', '${cropInfo['growing_period_days']} دن'),
                const SizedBox(height: 8),
              ],
              if (cropInfo['soil_requirements'] != null) ...[
                _buildDetailRow('مٹی کی ضرورت:', cropInfo['soil_requirements']),
                const SizedBox(height: 8),
              ],
              if (cropInfo['water_requirements'] != null) ...[
                _buildDetailRow('پانی کی ضرورت:', cropInfo['water_requirements']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بند کریں', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectCrop(cropName);
            },
            child: const Text('منتخب کریں', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  void _proceedToWeather() {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برائے کرم پہلے فصل منتخب کریں'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navigate to weather screen
    Navigator.of(context).pushNamed('/weather', arguments: {
      'position': widget.position,
      'locationName': widget.locationName,
      'districtName': widget.districtName,
      'provinceName': widget.provinceName,
      'agriculturalZone': widget.agriculturalZone,
      'locationDetails': widget.locationDetails,
      'selectedCrop': _selectedCrop,
      'cropInfo': _availableCrops.firstWhere(
        (crop) => crop['name_urdu'] == _selectedCrop,
        orElse: () => {},
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'فصل منتخب کریں',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
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
                    'فصلوں کی فہرست لوڈ ہو رہی ہے...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildCropSelectionScreen(),
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
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'فصلوں کی فہرست لوڈ نہیں ہو سکی',
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
              onPressed: _loadCrops,
              icon: const Icon(Icons.refresh),
              label: const Text('دوبارہ کوشش کریں'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelectionScreen() {
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
                    Icons.eco,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'فصل منتخب کریں',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اپنی فصل کا نام منتخب کریں',
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
          
          // Selected Crop Card
          if (_selectedCrop != null)
            Card(
              color: Colors.green.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'منتخب شدہ فصل',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _selectedCrop!,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showCropDetails(_selectedCrop!),
                      child: const Text('تفصیلات'),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_selectedCrop != null) const SizedBox(height: 20),
          
          // Crops Grid
          const Text(
            'دستیاب فصلیں',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: _availableCrops.length,
            itemBuilder: (context, index) {
              final crop = _availableCrops[index];
              final isSelected = _selectedCrop == crop['name_urdu'];
              
              return GestureDetector(
                onTap: () => _selectCrop(crop['name_urdu']),
                onLongPress: () => _showCropDetails(crop['name_urdu']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 32,
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          crop['name_urdu'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.green.shade700 : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
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
                  onPressed: _selectedCrop != null ? _proceedToWeather : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('آگے بڑھیں'),
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
                  '• فصل پر کلک کرکے منتخب کریں',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  '• تفصیلات دیکھنے کے لیے فصل پر لمبا دبائیں',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  '• منتخب شدہ فصل سبز رنگ میں دکھائی دے گی',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



