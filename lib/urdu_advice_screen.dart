import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/agricultural_database_service.dart';

class UrduAdviceScreen extends StatefulWidget {
  final String cropName;
  final String? locationName;
  final Map<String, dynamic>? agriculturalZone;
  final dynamic position;

  const UrduAdviceScreen({
    super.key,
    required this.cropName,
    this.locationName,
    this.agriculturalZone,
    this.position,
  });

  @override
  State<UrduAdviceScreen> createState() => _UrduAdviceScreenState();
}

class _UrduAdviceScreenState extends State<UrduAdviceScreen> {
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();
  
  Map<String, dynamic>? _cropInfo;
  List<Map<String, dynamic>> _adviceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    try {
      final cropInfo = await _dbService.getCropByName(widget.cropName);
      if (cropInfo != null) {
        setState(() {
          _cropInfo = cropInfo;
          _adviceList = _generateAdvice(cropInfo);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('مشورہ لوڈ کرنے میں خرابی: $e');
    }
  }

  List<Map<String, dynamic>> _generateAdvice(Map<String, dynamic> cropInfo) {
    final adviceList = <Map<String, dynamic>>[];
    
    // Planting advice
    adviceList.add({
      'category': 'بونے کا طریقہ',
      'icon': Icons.schedule,
      'color': Colors.green,
      'tips': [
        'مٹی کو اچھی طرح تیار کریں',
        'بیجوں کو مناسب گہرائی میں بویں',
        'پودوں کے درمیان مناسب فاصلہ رکھیں',
        'بونے سے پہلے مٹی کی نمی چیک کریں',
      ],
    });

    // Watering advice
    adviceList.add({
      'category': 'پانی دینے کا طریقہ',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'tips': [
        'صبح کے وقت پانی دیں',
        'پانی کی مقدار متوازن رکھیں',
        'بارش کے بعد پانی دینے سے گریز کریں',
        'مٹی کو گیلا نہ کریں',
      ],
    });

    // Fertilizer advice
    adviceList.add({
      'category': 'کھاد کا استعمال',
      'icon': Icons.eco,
      'color': Colors.brown,
      'tips': [
        'نامیاتی کھاد استعمال کریں',
        'کیمیائی کھاد کا استعمال کم کریں',
        'کھاد کو جڑوں کے قریب ڈالیں',
        'موسم کے مطابق کھاد کا انتخاب کریں',
      ],
    });

    // Pest control advice
    if (cropInfo['common_pests'] != null) {
      final pests = jsonDecode(cropInfo['common_pests'] as String) as List;
      adviceList.add({
        'category': 'کیڑوں سے بچاؤ',
        'icon': Icons.bug_report,
        'color': Colors.red,
        'tips': [
          'عام کیڑے: ${pests.join(', ')}',
          'فطرتی طریقوں سے کیڑوں کو کنٹرول کریں',
          'صحت مند پودے لگائیں',
          'صاف ماحول رکھیں',
        ],
      });
    }

    // Disease prevention advice
    if (cropInfo['common_diseases'] != null) {
      final diseases = jsonDecode(cropInfo['common_diseases'] as String) as List;
      adviceList.add({
        'category': 'بیماریوں سے بچاؤ',
        'icon': Icons.medical_services,
        'color': Colors.purple,
        'tips': [
          'عام بیماریاں: ${diseases.join(', ')}',
          'پودوں کو صاف رکھیں',
          'ہوا کی گردش کا خیال رکھیں',
          'متاثرہ پودوں کو فوری ہٹائیں',
        ],
      });
    }

    // Harvesting advice
    adviceList.add({
      'category': 'کٹائی کا طریقہ',
      'icon': Icons.grass,
      'color': Colors.orange,
      'tips': [
        'صحیح وقت پر کٹائی کریں',
        'کٹائی کے آلات صاف رکھیں',
        'پھل کو احتیاط سے توڑیں',
        'کٹائی کے بعد مناسب ذخیرہ کریں',
      ],
    });

    // Market advice
    adviceList.add({
      'category': 'مارکیٹ کی معلومات',
      'icon': Icons.store,
      'color': Colors.teal,
      'tips': [
        'مارکیٹ کی قیمت چیک کریں',
        'تازہ پیداوار فروخت کریں',
        'مقامی خریدار تلاش کریں',
        'قیمت کے اتار چڑھاؤ کا خیال رکھیں',
      ],
    });

    return adviceList;
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
          'زرعی مشورہ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cropInfo == null
              ? const Center(
                  child: Text(
                    'مشورہ دستیاب نہیں',
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
                                    Icons.lightbulb,
                                    size: 32,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'زرعی مشورہ',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _cropInfo!['name_urdu'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: const Text(
                                  'یہ مشورے آپ کی فصل کی بہترین پیداوار کے لیے ہیں۔ ان پر عمل کرکے آپ اچھے نتائج حاصل کر سکتے ہیں۔',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Advice Categories
                      ..._adviceList.map((advice) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        advice['icon'],
                                        color: advice['color'],
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        advice['category'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: advice['color'],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...(advice['tips'] as List<String>).map((tip) => 
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 6),
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: advice['color'],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: const TextStyle(fontSize: 14),
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
                        ),
                      ).toList(),
                      
                      const SizedBox(height: 20),
                      
                      // Additional Tips Card
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tips_and_updates, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'اضافی تجاویز',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('• باقاعدگی سے اپنی فصل کا معائنہ کریں'),
                              const Text('• موسم کی تبدیلیوں کا خیال رکھیں'),
                              const Text('• تجربہ کار کسانوں سے مشورہ لیں'),
                              const Text('• نئی ٹیکنالوجی کا استعمال کریں'),
                              const Text('• اپنے تجربات کو ریکارڈ میں رکھیں'),
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
                                // Navigate to report screen
                                Navigator.of(context).pushNamed('/urdu-report', arguments: {
                                  'crop': widget.cropName,
                                  'location': widget.locationName,
                                  'agriculturalZone': widget.agriculturalZone,
                                  'position': widget.position,
                                });
                              },
                              icon: const Icon(Icons.assessment),
                              label: const Text('رپورٹ دیکھیں'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
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
}
