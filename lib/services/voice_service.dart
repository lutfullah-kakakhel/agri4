import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  
  // Audio Player for pre-recorded sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Voice settings
  bool _isListening = false;
  bool _isSpeaking = false;
  
  // Language settings
  String _currentLanguage = 'ur-PK'; // Urdu Pakistan
  List<String> _availableLanguages = ['ur-PK', 'en-US'];

  // Callbacks
  Function(String)? onSpeechResult;
  Function(String)? onSpeechError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;
  Function()? onSpeakingStarted;
  Function()? onSpeakingCompleted;

  /// Initialize voice services
  Future<void> initialize() async {
    await _initializeSpeechToText();
    await _initializeTextToSpeech();
  }

  /// Initialize Speech to Text
  Future<void> _initializeSpeechToText() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech to Text Error: $error');
          onSpeechError?.call(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('Speech to Text Status: $status');
          if (status == 'listening') {
            _isListening = true;
            onListeningStarted?.call();
          } else if (status == 'notListening') {
            _isListening = false;
            onListeningStopped?.call();
          }
        },
      );

      if (_speechEnabled) {
        // Get available languages
        final locales = await _speechToText.locales();
        _availableLanguages = locales.map((locale) => locale.localeId).toList();
        debugPrint('Available languages: $_availableLanguages');
      }
    } catch (e) {
      debugPrint('Failed to initialize Speech to Text: $e');
    }
  }

  /// Initialize Text to Speech
  Future<void> _initializeTextToSpeech() async {
    try {
      // Set language for TTS
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(0.5); // Slower speech for better understanding
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingCompleted?.call();
      });

      // Set start handler
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingStarted?.call();
      });

      // Set error handler
      _flutterTts.setErrorHandler((message) {
        debugPrint('TTS Error: $message');
      });

    } catch (e) {
      debugPrint('Failed to initialize Text to Speech: $e');
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (!_speechEnabled) {
      debugPrint('Speech to Text not enabled');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          debugPrint('Recognized: $_lastWords');
          onSpeechResult?.call(_lastWords);
        },
        localeId: _currentLanguage,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// Play audio file
  Future<void> playAudioFile(String filePath) async {
    try {
      await _audioPlayer.play(AssetSource(filePath));
    } catch (e) {
      debugPrint('Error playing audio file: $e');
    }
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _flutterTts.setLanguage(language);
  }

  /// Get available languages
  List<String> getAvailableLanguages() => _availableLanguages;

  /// Check if speech is enabled
  bool get isSpeechEnabled => _speechEnabled;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Get last recognized words
  String get lastWords => _lastWords;

  /// Get current language
  String get currentLanguage => _currentLanguage;

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
  }
}

/// Voice commands for agricultural app
class VoiceCommands {
  static const Map<String, String> cropNames = {
    // English to Urdu crop names
    'wheat': 'گندم',
    'rice': 'چاول',
    'cotton': 'کپاس',
    'sugarcane': 'گنا',
    'maize': 'مکئی',
    'potato': 'آلو',
    'onion': 'پیاز',
    'tomato': 'ٹماٹر',
    'chili': 'مرچ',
    'okra': 'بھنڈی',
    'brinjal': 'بینگن',
    'cabbage': 'بند گوبھی',
    'cauliflower': 'پھول گوبھی',
    'spinach': 'پالک',
    'coriander': 'دھنیا',
    'mint': 'پودینہ',
    'basil': 'تولسی',
    // Urdu crop names
    'گندم': 'wheat',
    'چاول': 'rice',
    'کپاس': 'cotton',
    'گنا': 'sugarcane',
    'مکئی': 'maize',
    'آلو': 'potato',
    'پیاز': 'onion',
    'ٹماٹر': 'tomato',
    'مرچ': 'chili',
    'بھنڈی': 'okra',
    'بینگن': 'brinjal',
    'بند گوبھی': 'cabbage',
    'پھول گوبھی': 'cauliflower',
    'پالک': 'spinach',
    'دھنیا': 'coriander',
    'پودینہ': 'mint',
    'تولسی': 'basil',
  };

  static const Map<String, String> locationPhrases = {
    'field': 'کھیت',
    'farm': 'فارم',
    'here': 'یہاں',
    'this location': 'یہ جگہ',
    'current location': 'موجودہ جگہ',
    'کھیت': 'field',
    'فارم': 'farm',
    'یہاں': 'here',
    'یہ جگہ': 'this location',
    'موجودہ جگہ': 'current location',
  };

  static const Map<String, String> actionCommands = {
    'generate report': 'رپورٹ بنائیں',
    'get advice': 'مشورہ لیں',
    'start': 'شروع کریں',
    'stop': 'بند کریں',
    'help': 'مدد',
    'repeat': 'دوبارہ',
    'yes': 'ہاں',
    'no': 'نہیں',
    'رپورٹ بنائیں': 'generate report',
    'مشورہ لیں': 'get advice',
    'شروع کریں': 'start',
    'بند کریں': 'stop',
    'مدد': 'help',
    'دوبارہ': 'repeat',
    'ہاں': 'yes',
    'نہیں': 'no',
  };

  /// Recognize crop name from speech
  static String? recognizeCrop(String speechText) {
    final text = speechText.toLowerCase().trim();
    
    // Direct match
    if (cropNames.containsKey(text)) {
      return cropNames[text];
    }
    
    // Partial match
    for (final entry in cropNames.entries) {
      if (entry.key.contains(text) || text.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Recognize location command
  static bool isLocationCommand(String speechText) {
    final text = speechText.toLowerCase().trim();
    return locationPhrases.containsKey(text);
  }

  /// Recognize action command
  static String? recognizeAction(String speechText) {
    final text = speechText.toLowerCase().trim();
    
    for (final entry in actionCommands.entries) {
      if (entry.key.contains(text) || text.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Get crop name in Urdu
  static String getCropNameInUrdu(String englishName) {
    return cropNames[englishName.toLowerCase()] ?? englishName;
  }

  /// Get crop name in English
  static String getCropNameInEnglish(String urduName) {
    return cropNames[urduName] ?? urduName;
  }
}
