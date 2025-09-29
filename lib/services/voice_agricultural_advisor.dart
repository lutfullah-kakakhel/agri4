import 'dart:convert';
import 'package:flutter/material.dart';
import 'voice_service.dart';
import 'agricultural_database_service.dart';

class VoiceAgriculturalAdvisor {
  static final VoiceAgriculturalAdvisor _instance = VoiceAgriculturalAdvisor._internal();
  factory VoiceAgriculturalAdvisor() => _instance;
  VoiceAgriculturalAdvisor._internal();

  final VoiceService _voiceService = VoiceService();
  final AgriculturalDatabaseService _dbService = AgriculturalDatabaseService();

  // Current session data
  double? _currentLatitude;
  double? _currentLongitude;
  String? _selectedCrop;
  Map<String, dynamic>? _currentLocation;
  Map<String, dynamic>? _currentAgriculturalZone;

  // Callbacks
  Function(String)? onLocationDetected;
  Function(String)? onCropSelected;
  Function(Map<String, dynamic>)? onReportGenerated;
  Function(String)? onAdviceGenerated;
  Function(String)? onError;

  /// Initialize the advisor
  Future<void> initialize() async {
    await _voiceService.initialize();
    await _dbService.initialize();
    _setupVoiceCallbacks();
  }

  /// Setup voice service callbacks
  void _setupVoiceCallbacks() {
    _voiceService.onSpeechResult = _handleSpeechResult;
    _voiceService.onSpeechError = _handleSpeechError;
    _voiceService.onListeningStarted = () {
      debugPrint('Started listening for voice input');
    };
    _voiceService.onListeningStopped = () {
      debugPrint('Stopped listening for voice input');
    };
  }

  /// Handle speech recognition result
  void _handleSpeechResult(String recognizedText) {
    debugPrint('Recognized speech: $recognizedText');
    
    // Check if it's a crop name
    final cropName = VoiceCommands.recognizeCrop(recognizedText);
    if (cropName != null) {
      _handleCropSelection(cropName);
      return;
    }

    // Check if it's a location command
    if (VoiceCommands.isLocationCommand(recognizedText)) {
      _handleLocationConfirmation();
      return;
    }

    // Check if it's an action command
    final action = VoiceCommands.recognizeAction(recognizedText);
    if (action != null) {
      _handleActionCommand(action);
      return;
    }

    // If no specific command recognized, ask for clarification
    _askForClarification(recognizedText);
  }

  /// Handle speech recognition error
  void _handleSpeechError(String error) {
    debugPrint('Speech recognition error: $error');
    onError?.call('Voice recognition error: $error');
    
    // Speak error message in Urdu
    _speakInUrdu('آواز کی پہچان میں خرابی ہے۔ برائے کرم دوبارہ کوشش کریں۔');
  }

  /// Handle crop selection
  void _handleCropSelection(String cropName) {
    _selectedCrop = cropName;
    onCropSelected?.call(cropName);
    
    // Confirm crop selection
    final urduCropName = VoiceCommands.getCropNameInUrdu(cropName);
    _speakInUrdu('آپ نے $urduCropName منتخب کیا ہے۔ کیا یہ درست ہے؟');
    
    // Show available actions
    _speakInUrdu('آپ رپورٹ بنانے کے لیے "رپورٹ بنائیں" کہہ سکتے ہیں یا مشورے کے لیے "مشورہ لیں" کہہ سکتے ہیں۔');
  }

  /// Handle location confirmation
  void _handleLocationConfirmation() {
    if (_currentLocation != null) {
      final regionName = _currentLocation!['region_name_urdu'] ?? _currentLocation!['region_name'];
      _speakInUrdu('آپ کی موجودہ جگہ $regionName ہے۔');
      
      if (_currentAgriculturalZone != null) {
        final zoneName = _currentAgriculturalZone!['zone_name_urdu'];
        _speakInUrdu('یہ $zoneName زرعی علاقہ ہے۔');
      }
    } else {
      _speakInUrdu('جگہ کا تعین نہیں ہو سکا۔ برائے کرم GPS کو آن کریں۔');
    }
  }

  /// Handle action commands
  void _handleActionCommand(String action) {
    switch (action.toLowerCase()) {
      case 'generate report':
        generateAgriculturalReport();
        break;
      case 'get advice':
        generateAgriculturalAdvice();
        break;
      case 'start':
        _startVoiceInteraction();
        break;
      case 'stop':
        _stopVoiceInteraction();
        break;
      case 'help':
        _provideVoiceHelp();
        break;
      case 'repeat':
        _repeatLastMessage();
        break;
      default:
        _askForClarification(action);
    }
  }

  /// Ask for clarification when command is not clear
  void _askForClarification(String recognizedText) {
    _speakInUrdu('میں آپ کی بات نہیں سمجھ سکا۔ برائے کرم دوبارہ کوشش کریں۔');
    _speakInUrdu('آپ فصلیں جیسے گندم، چاول، کپاس، یا گنا کہہ سکتے ہیں۔');
  }

  /// Start voice interaction
  Future<void> _startVoiceInteraction() async {
    _speakInUrdu('خوش آمدید! میں آپ کا زرعی مشیر ہوں۔');
    
    if (_currentLocation == null) {
      _speakInUrdu('برائے کرم اپنی جگہ کا تعین کریں۔');
      return;
    }

    final regionName = _currentLocation!['region_name_urdu'] ?? _currentLocation!['region_name'];
    _speakInUrdu('آپ $regionName میں ہیں۔');

    // Get suitable crops for the location
    if (_currentAgriculturalZone != null) {
      final suitableCrops = await _getSuitableCropsForLocation();
      if (suitableCrops.isNotEmpty) {
        final cropNames = suitableCrops.map((crop) => crop['name_urdu']).join(', ');
        _speakInUrdu('یہاں اگنے والی فصلیں: $cropNames');
      }
    }

    _speakInUrdu('برائے کرم اپنی فصل کا نام بتائیں۔');
    await _voiceService.startListening();
  }

  /// Stop voice interaction
  Future<void> _stopVoiceInteraction() async {
    await _voiceService.stopListening();
    _speakInUrdu('آپ کا شکریہ۔ خدا حافظ۔');
  }

  /// Provide voice help
  void _provideVoiceHelp() {
    _speakInUrdu('میں آپ کی مدد کر سکتا ہوں:');
    _speakInUrdu('فصل کا نام بتائیں جیسے گندم، چاول، کپاس');
    _speakInUrdu('رپورٹ بنانے کے لیے "رپورٹ بنائیں" کہیں');
    _speakInUrdu('مشورے کے لیے "مشورہ لیں" کہیں');
    _speakInUrdu('مدد کے لیے "مدد" کہیں');
  }

  /// Repeat last message (placeholder)
  void _repeatLastMessage() {
    _speakInUrdu('آخری پیغام دوبارہ سنائیں گے۔');
  }

  /// Set current location
  void setLocation(double latitude, double longitude) async {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    
    // Get agricultural zone for this location
    _currentAgriculturalZone = await _dbService.getAgriculturalZone(latitude, longitude);
    
    // Check if location exists in database
    _currentLocation = await _dbService.getLocation(latitude, longitude);
    
    if (_currentLocation == null) {
      // Add new location to database
      final newLocation = {
        'latitude': latitude,
        'longitude': longitude,
        'region_name': 'Unknown Region',
        'region_name_urdu': 'نامعلوم علاقہ',
        'agricultural_zone_id': _currentAgriculturalZone?['id'],
        'soil_type': _currentAgriculturalZone?['soil_type'],
        'climate_data': _currentAgriculturalZone?['climate_zone'],
      };
      
      final locationId = await _dbService.addLocation(newLocation);
      newLocation['id'] = locationId;
      _currentLocation = newLocation;
    }
    
    onLocationDetected?.call('Location set: $latitude, $longitude');
  }

  /// Get suitable crops for current location
  Future<List<Map<String, dynamic>>> _getSuitableCropsForLocation() async {
    if (_currentAgriculturalZone == null) return [];
    
    final zoneId = _currentAgriculturalZone!['id'] as int;
    return await _dbService.getSuitableCrops(zoneId);
  }

  /// Generate agricultural report
  Future<void> generateAgriculturalReport() async {
    if (_selectedCrop == null) {
      _speakInUrdu('برائے کرم پہلے فصل کا نام بتائیں۔');
      return;
    }

    if (_currentLocation == null) {
      _speakInUrdu('جگہ کا تعین نہیں ہو سکا۔');
      return;
    }

    _speakInUrdu('رپورٹ تیار کر رہا ہوں۔ برائے کرم انتظار کریں۔');

    try {
      // Get crop information
      final cropInfo = await _dbService.getCropByName(_selectedCrop!);
      if (cropInfo == null) {
        _speakInUrdu('یہ فصل ڈیٹابیس میں نہیں ملی۔');
        return;
      }

      // Generate report data
      final report = {
        'crop': cropInfo,
        'location': _currentLocation,
        'agricultural_zone': _currentAgriculturalZone,
        'timestamp': DateTime.now().toIso8601String(),
        'recommendations': await _generateRecommendations(cropInfo),
      };

      // Speak report summary
      await _speakReportSummary(report);
      
      onReportGenerated?.call(report);
      
    } catch (e) {
      debugPrint('Error generating report: $e');
      _speakInUrdu('رپورٹ بنانے میں خرابی ہوئی ہے۔');
      onError?.call('Error generating report: $e');
    }
  }

  /// Generate agricultural advice
  Future<void> generateAgriculturalAdvice() async {
    if (_selectedCrop == null) {
      _speakInUrdu('برائے کرم پہلے فصل کا نام بتائیں۔');
      return;
    }

    _speakInUrdu('زرعی مشورہ تیار کر رہا ہوں۔');

    try {
      final cropInfo = await _dbService.getCropByName(_selectedCrop!);
      if (cropInfo == null) {
        _speakInUrdu('یہ فصل ڈیٹابیس میں نہیں ملی۔');
        return;
      }

      final advice = await _generateCropAdvice(cropInfo);
      _speakInUrdu(advice);
      
      onAdviceGenerated?.call(advice);
      
    } catch (e) {
      debugPrint('Error generating advice: $e');
      _speakInUrdu('مشورہ بنانے میں خرابی ہوئی ہے۔');
      onError?.call('Error generating advice: $e');
    }
  }

  /// Generate recommendations based on crop and location
  Future<List<Map<String, dynamic>>> _generateRecommendations(Map<String, dynamic> cropInfo) async {
    final recommendations = <Map<String, dynamic>>[];
    
    // Planting season recommendation
    final plantingMonths = jsonDecode(cropInfo['planting_months'] as String) as List;
    final currentMonth = DateTime.now().month;
    final currentMonthName = _getMonthName(currentMonth);
    
    if (plantingMonths.contains(currentMonthName)) {
      recommendations.add({
        'type': 'planting',
        'message_english': 'This is the right time to plant ${cropInfo['name_english']}',
        'message_urdu': 'یہ ${cropInfo['name_urdu']} بونے کا صحیح وقت ہے',
        'priority': 'high'
      });
    }

    // Soil requirements
    recommendations.add({
      'type': 'soil',
      'message_english': 'Ensure soil is ${cropInfo['soil_requirements']}',
      'message_urdu': 'یقینی بنائیں کہ مٹی ${cropInfo['soil_requirements']} ہے',
      'priority': 'medium'
    });

    // Water requirements
    recommendations.add({
      'type': 'water',
      'message_english': 'Water requirement: ${cropInfo['water_requirements']}',
      'message_urdu': 'پانی کی ضرورت: ${cropInfo['water_requirements']}',
      'priority': 'medium'
    });

    return recommendations;
  }

  /// Generate crop-specific advice
  Future<String> _generateCropAdvice(Map<String, dynamic> cropInfo) async {
    final cropNameUrdu = cropInfo['name_urdu'];
    final plantingMonths = jsonDecode(cropInfo['planting_months'] as String) as List;
    final harvestMonths = jsonDecode(cropInfo['harvest_months'] as String) as List;
    final growingPeriod = cropInfo['growing_period_days'];
    final yieldPerAcre = cropInfo['yield_per_acre'];

    String advice = '$cropNameUrdu کے لیے زرعی مشورہ: ';
    advice += 'بونے کا وقت: ${plantingMonths.join(', ')}. ';
    advice += 'کٹائی کا وقت: ${harvestMonths.join(', ')}. ';
    advice += 'بڑھنے کا دورانیہ: $growingPeriod دن. ';
    advice += 'فی ایکڑ پیداوار: $yieldPerAcre. ';

    // Add pest and disease advice
    final commonPests = jsonDecode(cropInfo['common_pests'] as String) as List;
    final commonDiseases = jsonDecode(cropInfo['common_diseases'] as String) as List;
    
    if (commonPests.isNotEmpty) {
      advice += 'عام کیڑے: ${commonPests.join(', ')}. ';
    }
    
    if (commonDiseases.isNotEmpty) {
      advice += 'عام بیماریاں: ${commonDiseases.join(', ')}. ';
    }

    return advice;
  }

  /// Speak report summary
  Future<void> _speakReportSummary(Map<String, dynamic> report) async {
    final cropInfo = report['crop'] as Map<String, dynamic>;
    final cropNameUrdu = cropInfo['name_urdu'];
    
    _speakInUrdu('$cropNameUrdu کی زرعی رپورٹ تیار ہے۔');
    
    final recommendations = report['recommendations'] as List<Map<String, dynamic>>;
    for (final rec in recommendations) {
      if (rec['priority'] == 'high') {
        _speakInUrdu(rec['message_urdu']);
      }
    }
    
    _speakInUrdu('تفصیلی رپورٹ اسکرین پر دکھائی جا رہی ہے۔');
  }

  /// Speak text in Urdu
  Future<void> _speakInUrdu(String text) async {
    await _voiceService.setLanguage('ur-PK');
    await _voiceService.speak(text);
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    await _voiceService.startListening();
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  /// Get current crop
  String? get currentCrop => _selectedCrop;

  /// Get current location
  Map<String, dynamic>? get currentLocation => _currentLocation;

  /// Get current agricultural zone
  Map<String, dynamic>? get currentAgriculturalZone => _currentAgriculturalZone;

  /// Dispose resources
  void dispose() {
    _voiceService.dispose();
    _dbService.close();
  }
}
