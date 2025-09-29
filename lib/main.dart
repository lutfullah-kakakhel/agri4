import 'package:flutter/material.dart';
import 'package:agri4_app/screens/location_screen.dart';
import 'package:agri4_app/screens/crop_selection_screen.dart';
import 'package:agri4_app/screens/weather_screen.dart';
import 'package:agri4_app/screens/satellite_screen.dart';
import 'package:agri4_app/urdu_report_screen.dart';
import 'package:agri4_app/urdu_advice_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agri4_app/settings/settings_screen.dart';
import 'package:agri4_app/voice/urdu_agricultural_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('fields');
  await Hive.openBox('settings');
  await Hive.openBox('cache_weather');
  await Hive.openBox('cache_ndvi');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGRI4 ADVISOR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.green.shade50, // Light plant green background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      home: const LocationScreen(),
      routes: <String, WidgetBuilder>{
        '/settings': (_) => const SettingsScreen(),
        '/voice': (_) => const UrduAgriculturalScreen(),
        '/crop-selection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CropSelectionScreen(
            position: args['position'],
            locationName: args['locationName'],
            districtName: args['districtName'],
            provinceName: args['provinceName'],
            agriculturalZone: args['agriculturalZone'],
            locationDetails: args['locationDetails'],
          );
        },
        '/weather': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WeatherScreen(
            position: args['position'],
            locationName: args['locationName'],
            districtName: args['districtName'],
            provinceName: args['provinceName'],
            agriculturalZone: args['agriculturalZone'],
            locationDetails: args['locationDetails'],
            selectedCrop: args['selectedCrop'],
            cropInfo: args['cropInfo'],
          );
        },
        '/satellite': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SatelliteScreen(
            position: args['position'],
            locationName: args['locationName'],
            districtName: args['districtName'],
            provinceName: args['provinceName'],
            agriculturalZone: args['agriculturalZone'],
            locationDetails: args['locationDetails'],
            selectedCrop: args['selectedCrop'],
            cropInfo: args['cropInfo'],
            currentWeather: args['currentWeather'],
            forecast: args['forecast'],
            weatherRecommendations: args['weatherRecommendations'],
          );
        },
        '/final-report': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return UrduReportScreen(
            cropName: args['selectedCrop'],
            locationName: args['locationName'],
            agriculturalZone: args['agriculturalZone'],
            position: args['position'],
          );
        },
        '/urdu-report': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return UrduReportScreen(
            cropName: args['crop'],
            locationName: args['location'],
            agriculturalZone: args['agriculturalZone'],
            position: args['position'],
          );
        },
        '/urdu-advice': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return UrduAdviceScreen(
            cropName: args['crop'],
            locationName: args['location'],
            agriculturalZone: args['agriculturalZone'],
            position: args['position'],
          );
        },
      },
    );
  }
}

