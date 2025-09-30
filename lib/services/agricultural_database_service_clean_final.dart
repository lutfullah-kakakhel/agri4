import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AgriculturalDatabaseService {
  static final AgriculturalDatabaseService _instance = AgriculturalDatabaseService._internal();
  factory AgriculturalDatabaseService() => _instance;
  AgriculturalDatabaseService._internal();

  Database? _database;
  bool _isInitialized = false;

  /// Initialize database
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Skip SQLite initialization on web platform
    if (kIsWeb) {
      debugPrint('AgriculturalDatabaseService: Skipping SQLite initialization on web');
      _isInitialized = true;
      return;
    }
    
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'agricultural_data.db');

      // Delete existing database to start fresh
      await deleteDatabase(path);

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );

      // Populate with initial data
      await _populateInitialData();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('AgriculturalDatabaseService initialization error: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Agricultural Zones Table
    await db.execute('''
      CREATE TABLE agricultural_zones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_name TEXT NOT NULL,
        zone_name_urdu TEXT NOT NULL,
        coordinates TEXT NOT NULL,
        soil_type TEXT,
        climate_zone TEXT,
        suitable_crops TEXT,
        planting_seasons TEXT,
        province TEXT,
        district TEXT
      )
    ''');

    // Crops Table
    await db.execute('''
      CREATE TABLE crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT NOT NULL,
        name_local TEXT,
        scientific_name TEXT,
        suitable_zones TEXT,
        planting_months TEXT,
        harvest_months TEXT,
        soil_requirements TEXT,
        water_requirements TEXT,
        common_pests TEXT,
        common_diseases TEXT,
        yield_per_acre TEXT,
        market_price_range TEXT,
        growing_period_days INTEGER
      )
    ''');

    // Locations Table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        region_name TEXT,
        region_name_urdu TEXT,
        district TEXT,
        district_urdu TEXT,
        province TEXT,
        province_urdu TEXT,
        agricultural_zone_id INTEGER,
        created_at TEXT
      )
    ''');

    // Voice Commands Table
    await db.execute('''
      CREATE TABLE voice_commands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        command_text TEXT NOT NULL,
        command_urdu TEXT,
        action_type TEXT NOT NULL,
        parameters TEXT,
        created_at TEXT
      )
    ''');
  }

  /// Upgrade database
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here if needed
  }

  /// Get the 7 unique crops data (used by both SQLite and web)
  List<Map<String, dynamic>> _getCropsData() {
    return [
      {
        'name_english': 'Wheat',
        'name_urdu': 'گندم',
        'name_local': 'گندم',
        'scientific_name': 'Triticum aestivum',
        'suitable_zones': jsonEncode([1, 2, 3]),
        'planting_months': jsonEncode(['October', 'November', 'December']),
        'harvest_months': jsonEncode(['March', 'April', 'May']),
        'soil_requirements': 'Well-drained, fertile soil',
        'water_requirements': 'Medium',
        'common_pests': jsonEncode(['Aphids', 'Army worm', 'Termites']),
        'common_diseases': jsonEncode(['Rust', 'Smut', 'Bunt']),
        'yield_per_acre': '40-60 maunds',
        'market_price_range': 'Rs 3000-4000 per maund',
        'growing_period_days': 120
      },
      {
        'name_english': 'Rice',
        'name_urdu': 'چاول',
        'name_local': 'چاول',
        'scientific_name': 'Oryza sativa',
        'suitable_zones': jsonEncode([1, 2]),
        'planting_months': jsonEncode(['May', 'June', 'July']),
        'harvest_months': jsonEncode(['September', 'October', 'November']),
        'soil_requirements': 'Clayey soil with good water retention',
        'water_requirements': 'High',
        'common_pests': jsonEncode(['Stem borer', 'Leaf folder', 'Brown planthopper']),
        'common_diseases': jsonEncode(['Bacterial blight', 'Rice blast', 'Sheath blight']),
        'yield_per_acre': '50-80 maunds',
        'market_price_range': 'Rs 2500-3500 per maund',
        'growing_period_days': 150
      },
      {
        'name_english': 'Cotton',
        'name_urdu': 'کپاس',
        'name_local': 'کپاس',
        'scientific_name': 'Gossypium hirsutum',
        'suitable_zones': jsonEncode([1, 2]),
        'planting_months': jsonEncode(['April', 'May', 'June']),
        'harvest_months': jsonEncode(['September', 'October', 'November']),
        'soil_requirements': 'Deep, well-drained soil',
        'water_requirements': 'Medium to High',
        'common_pests': jsonEncode(['Whitefly', 'Pink bollworm', 'Jassids']),
        'common_diseases': jsonEncode(['Cotton leaf curl virus', 'Bacterial blight']),
        'yield_per_acre': '15-25 maunds',
        'market_price_range': 'Rs 8000-12000 per maund',
        'growing_period_days': 150
      },
      {
        'name_english': 'Maize',
        'name_urdu': 'مکئی',
        'name_local': 'مکئی',
        'scientific_name': 'Zea mays',
        'suitable_zones': jsonEncode([1, 3]),
        'planting_months': jsonEncode(['February', 'March', 'April']),
        'harvest_months': jsonEncode(['June', 'July', 'August']),
        'soil_requirements': 'Well-drained, fertile soil',
        'water_requirements': 'Medium',
        'common_pests': jsonEncode(['Stem borer', 'Army worm', 'Aphids']),
        'common_diseases': jsonEncode(['Maize streak virus', 'Leaf blight']),
        'yield_per_acre': '60-80 maunds',
        'market_price_range': 'Rs 2000-3000 per maund',
        'growing_period_days': 90
      },
      {
        'name_english': 'Tomato',
        'name_urdu': 'ٹماٹر',
        'name_local': 'Tomato',
        'scientific_name': 'Solanum lycopersicum',
        'suitable_zones': jsonEncode([1, 2, 3]),
        'planting_months': jsonEncode(['March', 'April', 'May', 'June']),
        'harvest_months': jsonEncode(['June', 'July', 'August', 'September']),
        'soil_requirements': 'Well-drained, fertile soil',
        'water_requirements': 'Medium',
        'common_pests': jsonEncode(['Aphids', 'Whitefly', 'Hornworm']),
        'common_diseases': jsonEncode(['Blight', 'Mosaic virus', 'Fusarium wilt']),
        'yield_per_acre': '20-40 tons',
        'market_price_range': 'International pricing varies',
        'growing_period_days': 75
      },
      {
        'name_english': 'Potato',
        'name_urdu': 'آلو',
        'name_local': 'Potato',
        'scientific_name': 'Solanum tuberosum',
        'suitable_zones': jsonEncode([1, 2, 3]),
        'planting_months': jsonEncode(['February', 'March', 'April']),
        'harvest_months': jsonEncode(['May', 'June', 'July']),
        'soil_requirements': 'Loamy, well-drained soil',
        'water_requirements': 'Medium',
        'common_pests': jsonEncode(['Colorado beetle', 'Aphids', 'Wireworm']),
        'common_diseases': jsonEncode(['Late blight', 'Early blight', 'Scab']),
        'yield_per_acre': '15-25 tons',
        'market_price_range': 'International pricing varies',
        'growing_period_days': 90
      },
      {
        'name_english': 'Barley',
        'name_urdu': 'جو',
        'name_local': 'Barley',
        'scientific_name': 'Hordeum vulgare',
        'suitable_zones': jsonEncode([1, 2, 3]),
        'planting_months': jsonEncode(['October', 'November', 'December']),
        'harvest_months': jsonEncode(['April', 'May', 'June']),
        'soil_requirements': 'Well-drained soil',
        'water_requirements': 'Low',
        'common_pests': jsonEncode(['Aphids', 'Army worm', 'Hessian fly']),
        'common_diseases': jsonEncode(['Rust', 'Smut', 'Powdery mildew']),
        'yield_per_acre': '30-50 bushels',
        'market_price_range': 'International pricing varies',
        'growing_period_days': 120
      },
    ];
  }

  /// Populate initial data
  Future<void> _populateInitialData() async {
    await _populateAgriculturalZones();
    await _populateCrops();
    await _populateVoiceCommands();
  }

  /// Populate agricultural zones
  Future<void> _populateAgriculturalZones() async {
    final zones = [
      {
        'zone_name': 'Islamabad-Rawalpindi',
        'zone_name_urdu': 'اسلام آباد-راولپنڈی',
        'coordinates': jsonEncode([
          {'lat': 33.6844, 'lng': 73.0479}, // Islamabad
          {'lat': 33.5651, 'lng': 73.0169}, // Taxila
          {'lat': 33.6844, 'lng': 73.0479}  // Rawalpindi
        ]),
        'soil_type': 'Loamy, Rocky',
        'climate_zone': 'Sub-tropical',
        'suitable_crops': jsonEncode(['wheat', 'maize', 'vegetables', 'fruits']),
        'planting_seasons': jsonEncode(['Rabi', 'Kharif']),
        'province': 'Punjab',
        'district': 'Rawalpindi'
      },
    ];

    for (final zone in zones) {
      await _database?.insert('agricultural_zones', zone);
    }
  }

  /// Populate crops data - uses _getCropsData() to avoid duplication
  Future<void> _populateCrops() async {
    final crops = _getCropsData();
    for (final crop in crops) {
      await _database?.insert('crops', crop);
    }
  }

  /// Populate voice commands
  Future<void> _populateVoiceCommands() async {
    final commands = [
      {
        'command_text': 'generate report',
        'command_urdu': 'رپورٹ بنائیں',
        'action_type': 'generate_report',
        'parameters': jsonEncode({'type': 'agricultural_report'})
      },
      {
        'command_text': 'get advice',
        'command_urdu': 'مشورہ لیں',
        'action_type': 'get_advice',
        'parameters': jsonEncode({'type': 'agricultural_advice'})
      },
    ];

    for (final command in commands) {
      await _database?.insert('voice_commands', command);
    }
  }

  /// Get all crops
  Future<List<Map<String, dynamic>>> getAllCrops() async {
    if (_database == null) {
      // Use web fallback when database is not available
      if (kIsWeb) {
        return await getAvailableCropsWeb();
      }
      return [];
    }

    return await _database!.query('crops');
  }

  /// Get location by coordinates
  Future<Map<String, dynamic>?> getLocation(double lat, double lng) async {
    if (_database == null) {
      // Use web fallback when database is not available
      if (kIsWeb) {
        return await getLocationWeb(lat, lng);
      }
      return null;
    }

    // Special handling for Pakistani cities
    if ((lat >= 33.3 && lat <= 33.8) && (lng >= 72.8 && lng <= 73.2)) {
      // Islamabad/Taxila/Rawalpindi area
      return {
        'region_name': 'Islamabad',
        'region_name_urdu': 'اسلام آباد',
        'district': 'Islamabad',
        'district_urdu': 'اسلام آباد',
        'province': 'Punjab',
        'province_urdu': 'پنجاب',
        'latitude': lat,
        'longitude': lng,
      };
    }
    
    return null;
  }

  /// Add location
  Future<int> addLocation(Map<String, dynamic> locationData) async {
    return await _database!.insert('locations', locationData);
  }

  /// Get voice command
  Future<Map<String, dynamic>?> getVoiceCommand(String commandText) async {
    if (_database == null) return null;

    final result = await _database!.query(
      'voice_commands',
      where: 'command_text = ? OR command_urdu = ?',
      whereArgs: [commandText.toLowerCase(), commandText],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// Get agricultural zone by coordinates
  Future<Map<String, dynamic>?> getAgriculturalZone(double lat, double lng) async {
    if (_database == null) return null;

    // For now, return a default zone
    return {
      'zone_name': 'Default Zone',
      'zone_name_urdu': 'ڈیفالٹ زون',
      'coordinates': jsonEncode([{'lat': lat, 'lng': lng}]),
      'soil_type': 'Mixed',
      'climate_zone': 'Temperate',
      'suitable_crops': jsonEncode(['wheat', 'maize', 'vegetables']),
      'planting_seasons': jsonEncode(['Rabi', 'Kharif']),
      'province': 'Unknown',
      'district': 'Unknown'
    };
  }

  /// Get crop by name
  Future<Map<String, dynamic>?> getCropByName(String name) async {
    if (_database == null) return null;

    final result = await _database!.query(
      'crops',
      where: 'name_english = ? OR name_urdu = ? OR name_local = ?',
      whereArgs: [name, name, name],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// Get suitable crops for zone
  Future<List<Map<String, dynamic>>> getSuitableCrops(int zoneId) async {
    // For now, return all crops
    return await getAllCrops();
  }

  /// Close database
  Future<void> close() async {
    await _database?.close();
  }

  // Web fallback methods when SQLite is not available
  Future<List<Map<String, dynamic>>> getAvailableCropsWeb() async {
    if (kIsWeb) {
      // Use the same _getCropsData() method to avoid duplication
      return _getCropsData();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getLocationWeb(double lat, double lng) async {
    if (kIsWeb) {
      // Pakistan locations
      if ((lat >= 33.3 && lat <= 33.8) && (lng >= 72.8 && lng <= 73.2)) {
        return {
          'region_name': 'Islamabad',
          'region_name_urdu': 'اسلام آباد',
          'district': 'Islamabad',
          'district_urdu': 'اسلام آباد',
          'province': 'Punjab',
          'province_urdu': 'پنجاب',
          'latitude': lat,
          'longitude': lng,
        };
      }
      
      // UAE locations
      if ((lat >= 24.0 && lat <= 26.0) && (lng >= 54.0 && lng <= 56.0)) {
        return {
          'region_name': 'Dubai',
          'region_name_urdu': 'دبئی',
          'district': 'Dubai',
          'district_urdu': 'دبئی',
          'province': 'UAE',
          'province_urdu': 'متحدہ عرب امارات',
          'latitude': lat,
          'longitude': lng,
        };
      }
      
      // Canada locations (major cities)
      if ((lat >= 43.0 && lat <= 44.0) && (lng >= -79.5 && lng <= -79.0)) {
        return {
          'region_name': 'Toronto',
          'region_name_urdu': 'ٹورنٹو',
          'district': 'Ontario',
          'district_urdu': 'اونٹاریو',
          'province': 'Canada',
          'province_urdu': 'کینیڈا',
          'latitude': lat,
          'longitude': lng,
        };
      }
      
      if ((lat >= 45.0 && lat <= 46.0) && (lng >= -73.7 && lng <= -73.3)) {
        return {
          'region_name': 'Montreal',
          'region_name_urdu': 'مونٹریال',
          'district': 'Quebec',
          'district_urdu': 'کیوبیک',
          'province': 'Canada',
          'province_urdu': 'کینیڈا',
          'latitude': lat,
          'longitude': lng,
        };
      }
      
      if ((lat >= 49.0 && lat <= 50.0) && (lng >= -123.3 && lng <= -122.8)) {
        return {
          'region_name': 'Vancouver',
          'region_name_urdu': 'وینکوور',
          'district': 'British Columbia',
          'district_urdu': 'برٹش کولمبیا',
          'province': 'Canada',
          'province_urdu': 'کینیڈا',
          'latitude': lat,
          'longitude': lng,
        };
      }
      
      // Generic international location
      return {
        'region_name': 'International Location',
        'region_name_urdu': 'بین الاقوامی مقام',
        'district': 'Global',
        'district_urdu': 'عالمی',
        'province': 'World',
        'province_urdu': 'دنیا',
        'latitude': lat,
        'longitude': lng,
      };
    }
    return null;
  }
}

