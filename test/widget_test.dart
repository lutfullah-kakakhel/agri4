// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import 'package:agri4_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
    await Hive.openBox('fields');
    await Hive.openBox('settings');
    await Hive.openBox('cache_weather');
    await Hive.openBox('cache_ndvi');
  });

  testWidgets('App shows Field Mapper screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Field Mapper'), findsOneWidget);
  });
}
