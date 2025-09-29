import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_agricultural_advisor.dart';
import '../services/voice_service.dart';
import '../services/agricultural_database_service.dart';

class VoiceAgriculturalScreen extends StatefulWidget {
  const VoiceAgriculturalScreen({super.key});

  @override
  State<VoiceAgriculturalScreen> createState() => _VoiceAgriculturalScreenState();
}

class _VoiceAgriculturalScreenState extends State<VoiceAgriculturalScreen> {
  final VoiceAgriculturalAdvisor _advisor = VoiceAgriculturalAdvisor();
  final VoiceService _voiceService = VoiceService();
  
  // UI State
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  
  // Location and Crop State
  Position? _currentPosition;
  String? _selectedCrop;
  String? _currentLocationName;
  String? _currentAgriculturalZone;
  
  // Voice Interaction State
  String _lastRecognizedText = '';
  String _currentMessage = '';
  List<String> _conversationHistory = [];
  
  // UI Controllers
  final ScrollController _scrollController = ScrollController();

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
      // Initialize voice services
      await _advisor.initialize();
      
      // Request location permission
      await _requestLocationPermission();
      
      // Get current location
      await _getCurrentLocation();
      
      // Setup callbacks
      _setupCallbacks();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      // Welcome message
      _addToConversation('خوش آمدید! میں آپ کا زرعی مشیر ہوں۔');
      _addToConversation('آپ کی جگہ کا تعین کر رہا ہوں...');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addToConversation('شروع کرنے میں خرابی ہوئی ہے: $e');
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
      
      // Get location name (simplified)
      _currentLocationName = 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}';
      
      setState(() {});
      
    } catch (e) {
      _addToConversation('جگہ کا تعین نہیں ہو سکا: $e');
    }
  }

  void _setupCallbacks() {
    _advisor.onLocationDetected = (location) {
      setState(() {
        _currentLocationName = location;
      });
      _addToConversation('جگہ کا تعین ہو گیا: $location');
    };
    
    _advisor.onCropSelected = (cropName) {
      setState(() {
        _selectedCrop = cropName;
      });
      _addToConversation('فصل منتخب کی گئی: $cropName');
    };
    
    _advisor.onReportGenerated = (report) {
      _addToConversation('زرعی رپورٹ تیار ہے۔');
      _showReportDialog(report);
    };
    
    _advisor.onAdviceGenerated = (advice) {
      _addToConversation(advice);
    };
    
    _advisor.onError = (error) {
      _addToConversation('خرابی: $error');
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

  void _addToConversation(String message) {
    setState(() {
      _conversationHistory.add(message);
      _currentMessage = message;
    });
    
    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startVoiceInteraction() async {
    if (!_isInitialized) return;
    
    try {
      await _advisor.startListening();
      _addToConversation('سن رہا ہوں... آپ بول سکتے ہیں۔');
    } catch (e) {
      _addToConversation('آواز شروع کرنے میں خرابی: $e');
    }
  }

  Future<void> _stopVoiceInteraction() async {
    await _advisor.stopListening();
    _addToConversation('آواز بند کر دی گئی۔');
  }

  void _showReportDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('زرعی رپورٹ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (report['crop'] != null) ...[
                Text('فصل: ${report['crop']['name_urdu']}'),
                const SizedBox(height: 8),
                Text('انگریزی نام: ${report['crop']['name_english']}'),
                const SizedBox(height: 8),
              ],
              if (report['location'] != null) ...[
                Text('جگہ: ${report['location']['region_name_urdu'] ?? report['location']['region_name']}'),
                const SizedBox(height: 8),
              ],
              if (report['recommendations'] != null) ...[
                const Text('تجاویز:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...(report['recommendations'] as List).map((rec) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${rec['message_urdu']}'),
                  )
                ).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بند کریں'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آواز سے زرعی مشورہ'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Location and Status Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentLocationName != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'جگہ: $_currentLocationName',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_selectedCrop != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.agriculture, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'فصل: $_selectedCrop',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            _isListening ? Icons.mic : Icons.mic_off,
                            color: _isListening ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isSpeaking ? Icons.volume_up : Icons.volume_down,
                            color: _isSpeaking ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isListening ? 'سن رہا ہوں' : 
                            _isSpeaking ? 'بول رہا ہوں' : 'تیار',
                            style: TextStyle(
                              color: _isListening ? Colors.red : 
                                     _isSpeaking ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Conversation History
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversationHistory.length,
                    itemBuilder: (context, index) {
                      final message = _conversationHistory[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.blue.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: index % 2 == 0 ? Colors.blue.shade200 : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
                
                // Voice Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: _isListening ? _stopVoiceInteraction : _startVoiceInteraction,
                        backgroundColor: _isListening ? Colors.red : Colors.green,
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          // Generate report button - will be handled by voice commands
                          _addToConversation('رپورٹ بنانے کے لیے "رپورٹ بنائیں" کہیں');
                        },
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.assessment, color: Colors.white),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          // Generate advice button - will be handled by voice commands
                          _addToConversation('مشورے کے لیے "مشورہ لیں" کہیں');
                        },
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.lightbulb, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Help Text
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: const Column(
                    children: [
                      Text(
                        'آواز کے ذریعے استعمال کریں:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• فصل کا نام بتائیں (گندم، چاول، کپاس)'),
                      Text('• "رپورٹ بنائیں" کہیں'),
                      Text('• "مشورہ لیں" کہیں'),
                      Text('• "مدد" کہیں'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _advisor.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
