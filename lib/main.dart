import 'package:flutter/material.dart';
import 'package:agri4_app/map/field_map_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agri4_app/settings/settings_screen.dart';

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
      home: const FieldMapScreen(),
      routes: <String, WidgetBuilder>{
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

