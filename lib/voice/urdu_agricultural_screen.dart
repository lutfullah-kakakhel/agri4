import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_agricultural_advisor.dart';
import '../services/voice_service.dart';
import '../services/agricultural_database_service.dart';

class UrduAgriculturalScreen extends StatefulWidget {
  const UrduAgriculturalScreen({super.key});

  @override
  State<UrduAgriculturalScreen> createState() => _UrduAgriculturalScreenState();
}

class _UrduAgriculturalScreenState extends State<UrduAgriculturalScreen> {
  final VoiceAgriculturalAdvisor _advisor = VoiceAgriculturalAdvisor();
  final VoiceService _voiceService = VoiceService();
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();
  
  // UI State
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  
  // Location and Crop State
  Position? _currentPosition;
  String? _selectedCrop;
  String? _currentLocationName;
  Map<String, dynamic>? _agriculturalZone;
  List<Map<String, dynamic>> _availableCrops = [];
  
  // Controllers
  final TextEditingController _cropSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Voice state
  bool _voiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize services
      await _advisor.initialize();
      await _dbService.initialize();
      
      // Request location permission
      await _requestLocationPermission();
      
      // Get current location
      await _getCurrentLocation();
      
      // Load available crops
      await _loadAvailableCrops();
      
      // Setup callbacks
      _setupCallbacks();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('شروع کرنے میں خرابی ہوئی ہے: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      // Set location in advisor
      _advisor.setLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
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

  void _setupCallbacks() {
    _advisor.onLocationDetected = (location) {
      setState(() {
        _currentLocationName = location;
      });
    };
    
    _advisor.onCropSelected = (cropName) {
      setState(() {
        _selectedCrop = cropName;
      });
    };
    
    _advisor.onReportGenerated = (report) {
      _showReportDialog(report);
    };
    
    _advisor.onAdviceGenerated = (advice) {
      _showAdviceDialog(advice);
    };
    
    _advisor.onError = (error) {
      _showError(error);
    };
    
    _voiceService.onListeningStarted = () {
      setState(() {
        _isListening = true;
      });
    };
    
    _voiceService.onListeningStopped = () {
      setState(() {
        _isListening = false;
      });
    };
    
    _voiceService.onSpeakingStarted = () {
      setState(() {
        _isSpeaking = true;
      });
    };
    
    _voiceService.onSpeakingCompleted = () {
      setState(() {
        _isSpeaking = false;
      });
    };
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showReportDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('زرعی رپورٹ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (report['crop'] != null) ...[
                _buildReportSection(
                  'فصل',
                  report['crop']['name_urdu'],
                  report['crop']['name_english'],
                ),
                const SizedBox(height: 12),
              ],
              if (report['location'] != null) ...[
                _buildReportSection(
                  'جگہ',
                  report['location']['region_name_urdu'] ?? report['location']['region_name'],
                  null,
                ),
                const SizedBox(height: 12),
              ],
              if (report['agricultural_zone'] != null) ...[
                _buildReportSection(
                  'زرعی علاقہ',
                  report['agricultural_zone']['zone_name_urdu'],
                  report['agricultural_zone']['zone_name'],
                ),
                const SizedBox(height: 12),
              ],
              if (report['recommendations'] != null) ...[
                const Text('تجاویز:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(report['recommendations'] as List).map((rec) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec['message_urdu'], style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )
                ).toList(),
              ],
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_voiceEnabled)
                IconButton(
                  onPressed: () => _speakReport(report),
                  icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_down),
                  tooltip: 'سنائیں',
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('بند کریں', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(String title, String urduText, String? englishText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          urduText,
          style: const TextStyle(fontSize: 14),
        ),
        if (englishText != null) ...[
          const SizedBox(height: 2),
          Text(
            '($englishText)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  void _showAdviceDialog(String advice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('زرعی مشورہ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            advice,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_voiceEnabled)
                IconButton(
                  onPressed: () => _speakAdvice(advice),
                  icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_down),
                  tooltip: 'سنائیں',
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('بند کریں', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _speakReport(Map<String, dynamic> report) async {
    final cropInfo = report['crop'] as Map<String, dynamic>?;
    if (cropInfo != null) {
      final cropNameUrdu = cropInfo['name_urdu'];
      await _voiceService.speak('$cropNameUrdu کی زرعی رپورٹ');
      
      final recommendations = report['recommendations'] as List<Map<String, dynamic>>?;
      if (recommendations != null) {
        for (final rec in recommendations) {
          if (rec['priority'] == 'high') {
            await _voiceService.speak(rec['message_urdu']);
          }
        }
      }
    }
  }

  Future<void> _speakAdvice(String advice) async {
    await _voiceService.speak(advice);
  }

  Future<void> _selectCrop(String cropName) async {
    setState(() {
      _selectedCrop = cropName;
    });
    
    if (_voiceEnabled) {
      final cropInfo = await _dbService.getCropByName(cropName);
      if (cropInfo != null) {
        await _voiceService.speak('آپ نے ${cropInfo['name_urdu']} منتخب کیا ہے');
      }
    }
  }

  Future<void> _generateReport() async {
    if (_selectedCrop == null) {
      _showError('برائے کرم پہلے فصل منتخب کریں');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate report using advisor
      await _advisor.generateAgriculturalReport();
    } catch (e) {
      _showError('رپورٹ بنانے میں خرابی: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAdvice() async {
    if (_selectedCrop == null) {
      _showError('برائے کرم پہلے فصل منتخب کریں');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate advice using advisor
      await _advisor.generateAgriculturalAdvice();
    } catch (e) {
      _showError('مشورہ بنانے میں خرابی: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (!_voiceEnabled) {
      setState(() {
        _voiceEnabled = true;
      });
      await _voiceService.startListening();
    } else {
      await _voiceService.stopListening();
      setState(() {
        _voiceEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('زرعی مشیر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleVoiceInput,
            icon: Icon(_voiceEnabled ? Icons.mic : Icons.mic_off),
            tooltip: _voiceEnabled ? 'آواز بند کریں' : 'آواز استعمال کریں',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'آپ کی جگہ:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentLocationName ?? 'جگہ کا تعین نہیں ہو سکا',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_agriculturalZone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'زرعی علاقہ: ${_agriculturalZone!['zone_name_urdu']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Crop Selection Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.agriculture, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'فصل منتخب کریں:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Text input for crop search
                          TextField(
                            controller: _cropSearchController,
                            decoration: InputDecoration(
                              hintText: 'فصل کا نام لکھیں...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _voiceEnabled
                                  ? IconButton(
                                      onPressed: () => _voiceService.startListening(),
                                      icon: const Icon(Icons.mic),
                                      tooltip: 'آواز سے تلاش کریں',
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Crop dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCrop,
                            decoration: const InputDecoration(
                              labelText: 'فصل منتخب کریں',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableCrops.map((crop) {
                              return DropdownMenuItem<String>(
                                value: crop['name_urdu'],
                                child: Text(
                                  crop['name_urdu'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _selectCrop(value);
                              }
                            },
                          ),
                          
                          if (_selectedCrop != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'منتخب شدہ: $_selectedCrop',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedCrop != null && !_isLoading ? _generateReport : null,
                          icon: _isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.assessment),
                          label: const Text('زرعی رپورٹ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedCrop != null && !_isLoading ? _generateAdvice : null,
                          icon: _isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.lightbulb),
                          label: const Text('زرعی مشورہ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Voice Status Card
                  if (_voiceEnabled)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isListening ? Icons.mic : Icons.mic_off,
                                  color: _isListening ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isListening ? 'سن رہا ہوں...' : 'آواز تیار',
                                  style: TextStyle(
                                    color: _isListening ? Colors.red : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'آواز کے ذریعے استعمال کریں:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('• فصل کا نام بتائیں (گندم، چاول، کپاس)'),
                            const Text('• "رپورٹ بنائیں" کہیں'),
                            const Text('• "مشورہ لیں" کہیں'),
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
    _advisor.dispose();
    _cropSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
