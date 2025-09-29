
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:agri4_app/geo/area_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agri4_app/storage/field_storage.dart';
import 'package:agri4_app/services/open_meteo_service.dart';
import 'package:agri4_app/services/nasa_power_service.dart';
import 'package:agri4_app/repo/weather_repository.dart';
import 'package:agri4_app/repo/ndvi_repository.dart';
import 'package:agri4_app/services/sentinel_hub_service.dart';
import 'package:agri4_app/storage/settings_storage.dart';
import 'dart:typed_data';
import 'package:agri4_app/report/report_screen.dart';
import 'package:agri4_app/services/token_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agri4_app/models/crop.dart';
import 'package:agri4_app/models/agricultural_advisory.dart';
import 'package:agri4_app/advisory/advisory_screen.dart';

class FieldMapScreen extends StatefulWidget {
  const FieldMapScreen({super.key});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _points = <LatLng>[];
  List<StoredField> _stored = <StoredField>[];
  Position? _position;
  bool _isLoadingLocation = false;
  bool _isFetchingWeather = false;
  bool _isFetchingNdvi = false;
  bool _ndviLoaded = false;
  bool _drawMode = false;
  double? _selectedPresetAcres;
  bool _fieldPlaced = false;
  Crop? _selectedCrop;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadStored();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _position = pos;
      });
    } catch (_) {
      // ignore errors for MVP
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onTap(TapPosition tapPosition, LatLng latlng) {
    if (_drawMode) {
      setState(() {
        _points.add(latlng);
      });
      print('Added point ${_points.length}: ${latlng.latitude}, ${latlng.longitude}');
      return;
    }
    if (_selectedPresetAcres != null) {
      _applyPresetAt(latlng, _selectedPresetAcres!);
    }
  }

  void _clear() {
    setState(() {
      _points.clear();
      _fieldPlaced = false; // Reset field placed state
      _ndviLoaded = false; // Reset NDVI status
    });
  }

  Future<void> _loadStored() async {
    final Box box = Hive.box('fields');
    final FieldStorage storage = FieldStorage.of(box);
    setState(() {
      _stored = storage.listFields();
    });
  }

  Future<void> _saveCurrent() async {
    if (_points.length < 3) return;
    if (_selectedCrop == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop first')),
      );
      return;
    }
    
    final Box box = Hive.box('fields');
    final FieldStorage storage = FieldStorage.of(box);
    final double sqm = _computeAreaSquareMeters(_points);
    final double acres = sqm / 4046.8564224;
    final Box sbox = Hive.box('settings');
    final SettingsStorage settings = SettingsStorage.of(sbox);
    final double target = settings.targetAreaAcres;
    final double tolerance = 0.5;
    if (acres < target - tolerance || acres > target + tolerance) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Area ${acres.toStringAsFixed(2)} acres not near target ${target.toStringAsFixed(1)}±$tolerance')),
      );
    }

    String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        final TextEditingController ctrl = TextEditingController(
          text: '${_selectedCrop!.name} Field ${DateTime.now().toIso8601String().substring(0, 10)}'
        );
        return AlertDialog(
          title: const Text('Name your field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: ctrl),
              const SizedBox(height: 8),
              Text('Crop: ${_selectedCrop!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await storage.saveField(name: name, polygon: _points);
    await _loadStored();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedCrop!.name} field saved')),
    );
  }

  Future<void> _deleteField(String id) async {
    final Box box = Hive.box('fields');
    final FieldStorage storage = FieldStorage.of(box);
    await storage.deleteField(id);
    await _loadStored();
  }

  List<double>? _bboxFromPolygon(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLon = pts.first.longitude, maxLon = pts.first.longitude;
    for (final LatLng p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return <double>[minLon, minLat, maxLon, maxLat];
  }


  void _applyPresetAcres(double acres) async {
    // Select preset; actual placement happens on next tap
    setState(() {
      _selectedPresetAcres = acres;
    });
    final SettingsStorage settings = SettingsStorage.of(Hive.box('settings'));
    await settings.setTargetAreaAcres(acres);
  }

  void _applyPresetAt(LatLng center, double acres) {
    final double lat = center.latitude;
    final double lon = center.longitude;
    final double sqm = acres * 4046.8564224;
    final double side = math.sqrt(sqm);
    // meters to degrees - make field more proportional to screen
    final double dLat = (side / 2) / 111320.0;
    final double metersPerDegLon = 111320.0 * math.cos(lat * math.pi / 180.0);
    final double dLon = (side / 2) / metersPerDegLon;
    final LatLng p1 = LatLng(lat - dLat, lon - dLon);
    final LatLng p2 = LatLng(lat - dLat, lon + dLon);
    final LatLng p3 = LatLng(lat + dLat, lon + dLon);
    final LatLng p4 = LatLng(lat + dLat, lon - dLon);
    setState(() {
      _points
        ..clear()
        ..addAll(<LatLng>[p1, p2, p3, p4]);
      _selectedPresetAcres = null; // consume selection after placement
      _fieldPlaced = true; // Mark field as placed
    });
    
    // Print coordinates for debugging
    print('Field placed at center: ${center.latitude}, ${center.longitude}');
    print('Field corners:');
    print('  P1: ${p1.latitude}, ${p1.longitude}');
    print('  P2: ${p2.latitude}, ${p2.longitude}');
    print('  P3: ${p3.latitude}, ${p3.longitude}');
    print('  P4: ${p4.latitude}, ${p4.longitude}');
    
    _mapController.move(center, 18); // Slightly less zoom for better proportion
  }

  Future<void> _fetchNdvi() async {
    final List<double>? bbox = _bboxFromPolygon(_points);
    if (bbox == null) return;
    setState(() { _isFetchingNdvi = true; });
    try {
      final NdviRepository repo = NdviRepository(Hive.box('cache_ndvi'));
      final bool success = await repo.getNdvi(bbox: bbox);
      if (!mounted) return;
      setState(() { _ndviLoaded = success; });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌱 Satellite NDVI data loaded from Copernicus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌱 Satellite data simulation completed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _ndviLoaded = true; }); // Still show as loaded even with fallback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🌱 Using fallback NDVI simulation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() { _isFetchingNdvi = false; });
      }
    }
  }

  Future<void> _showAgriculturalAdvisory() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop first')),
      );
      return;
    }
    
    final List<double>? bbox = _bboxFromPolygon(_points);
    if (bbox == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please place a field first')),
      );
      return;
    }

    // Generate agricultural advisory based on satellite data
    final advisory = AgriculturalAdvisory.generateAdvisory(
      cropType: _selectedCrop!.name,
      bbox: bbox,
    );

    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdvisoryScreen(advisory: advisory),
      ),
    );
  }

  double _computeAreaSquareMeters(List<LatLng> points) => computePolygonAreaSquareMeters(points);

  String _areaLabel() {
    final double sqm = _computeAreaSquareMeters(_points);
    if (sqm <= 0) return 'Tap to draw field';
    final double acres = sqm / 4046.8564224;
    return '${acres.toStringAsFixed(3)} acres';
  }

  String _coordinatesLabel() {
    if (_points.isEmpty) return '';
    final LatLng? centroid = _centroid(_points);
    if (centroid == null) return '';
    return 'Center: ${centroid.latitude.toStringAsFixed(6)}, ${centroid.longitude.toStringAsFixed(6)}';
  }

  LatLng? _centroid(List<LatLng> points) {
    if (points.isEmpty) return null;
    double sumLat = 0;
    double sumLon = 0;
    for (final LatLng p in points) {
      sumLat += p.latitude;
      sumLon += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLon / points.length);
  }

  Future<void> _fetchAndShowWeather() async {
    final LatLng? c = _centroid(_points);
    if (c == null) return;
    setState(() {
      _isFetchingWeather = true;
    });
    try {
      final WeatherRepository repo = WeatherRepository(
        Hive.box('cache_weather'),
        OpenMeteoService(),
        NasaPowerService(),
      );
      final (OpenMeteoDaily daily, NasaPowerDaily powerDaily) = await repo.getWeather(lat: c.latitude, lon: c.longitude);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Open‑Meteo (Daily)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: daily.dates.length,
                      itemBuilder: (BuildContext _, int i) {
                        final String date = daily.dates[i];
                        final double p = i < daily.precipMm.length ? daily.precipMm[i] : 0;
                        final double e = i < daily.et0Mm.length ? daily.et0Mm[i] : 0;
                        return ListTile(
                          dense: true,
                          title: Text(date),
                          subtitle: Text('Rain: ${p.toStringAsFixed(1)} mm, ET0: ${e.toStringAsFixed(1)} mm'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('NASA POWER (Last 7 days)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: powerDaily.dates.length,
                      itemBuilder: (BuildContext _, int i) {
                        final String date = powerDaily.dates[i];
                        final double tmax = i < powerDaily.tmaxC.length ? powerDaily.tmaxC[i] : 0;
                        final double tmin = i < powerDaily.tminC.length ? powerDaily.tminC[i] : 0;
                        final double p = i < powerDaily.precipMm.length ? powerDaily.precipMm[i] : 0;
                        final double rad = i < powerDaily.solarMJm2.length ? powerDaily.solarMJm2[i] : 0;
                        return ListTile(
                          dense: true,
                          title: Text(date),
                          subtitle: Text('Tmax: ${tmax.toStringAsFixed(1)} °C, Tmin: ${tmin.toStringAsFixed(1)} °C, Rain: ${p.toStringAsFixed(1)} mm, Solar: ${rad.toStringAsFixed(1)} MJ/m²'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ReportScreen(openMeteo: daily, power: powerDaily),
                        ));
                      },
                      icon: const Icon(Icons.article),
                      label: const Text('Open Report'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch weather')));
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(30.3753, 69.3451); // Pakistan default center

    return Scaffold(
      appBar: AppBar(
        title: const Text('AGRI4 ADVISOR'),
        actions: <Widget>[
          // Logo in top right
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Top content area
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Select crop and field size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                // Crop selection dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Crop>(
                      value: _selectedCrop,
                      hint: const Text('Select Crop'),
                      isExpanded: true,
                      items: Crop.crops.map((Crop crop) {
                        return DropdownMenuItem<Crop>(
                          value: crop,
                          child: Row(
                            children: <Widget>[
                              SvgPicture.asset(
                                crop.imagePath,
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(crop.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Crop? newValue) {
                        setState(() {
                          _selectedCrop = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Map area (reduced height)
          Expanded(
            child: Stack(
              children: <Widget>[
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _position != null ? 16 : 6,
                    onTap: _onTap,
                    interactionOptions: InteractionOptions(
                      flags: _fieldPlaced 
                          ? InteractiveFlag.none  // Disable all interaction when field is placed
                          : InteractiveFlag.all,  // Allow all interaction when no field
                    ),
                  ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.agri4_app',
              ),
              // Field corner markers - simple and clear for farmers
              if (_points.length >= 3)
                MarkerLayer(
                  markers: <Marker>[
                    // Add simple corner markers
                    for (int i = 0; i < _points.length; i++)
                      Marker(
                        point: _points[i],
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.crop_square,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              if (_points.isNotEmpty)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(points: _points + <LatLng>[_points.first], strokeWidth: 5, color: Colors.green.shade700),
                  ],
                ),
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: <Polygon>[
                    Polygon(
                      points: _points,
                      borderColor: Colors.green.shade800,
                      borderStrokeWidth: 4, // Thicker border for better visibility
                      color: Colors.green.withValues(alpha: 0.25), // Slightly more visible fill
                    ),
                  ],
                ),
              if (_position != null)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: center,
                      width: 32,
                      height: 32,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ],
                ),
              // Tractor icon in center of field
              if (_points.length >= 3)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: _centroid(_points)!,
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        'assets/images/tractor.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
              // NDVI data indicator - show as a status overlay
              if (_ndviLoaded && _points.length >= 3)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: _centroid(_points)!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade600.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                ],
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Card(
                    color: Colors.green.shade100,
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 150),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _stored.isEmpty
                            ? const Text('No saved fields', style: TextStyle(fontSize: 12))
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _stored
                                      .map(
                                        (StoredField f) => ListTile(
                                          dense: true,
                                          title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, size: 16),
                                            onPressed: () => _deleteField(f.id),
                                          ),
                                          onTap: () {
                                            if (f.polygon.isNotEmpty) {
                                              _mapController.move(f.polygon.first, 17);
                                            }
                                            setState(() {
                                              _points
                                                ..clear()
                                                ..addAll(f.polygon);
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                if (_isLoadingLocation)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          // Bottom content area
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _areaLabel(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedCrop != null)
                            Row(
                              children: <Widget>[
                                SvgPicture.asset(
                                  _selectedCrop!.imagePath,
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCrop!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          if (_ndviLoaded)
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.eco,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Satellite Data Ready',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          if (_coordinatesLabel().isNotEmpty)
                            Text(
                              _coordinatesLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(children: <Widget>[
                      const Text('Draw'),
                      Switch(
                        value: _drawMode,
                        onChanged: (bool v) => setState(() => _drawMode = v),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('1 acre'),
                        selected: _selectedPresetAcres == 1.0,
                        onSelected: (_) => _applyPresetAcres(1.0),
                        selectedColor: Colors.green.shade300,
                        checkmarkColor: Colors.white,
                      ),
                      ChoiceChip(
                        label: const Text('3 acres'),
                        selected: _selectedPresetAcres == 3.0,
                        onSelected: (_) => _applyPresetAcres(3.0),
                        selectedColor: Colors.green.shade300,
                        checkmarkColor: Colors.white,
                      ),
                      ChoiceChip(
                        label: const Text('5 acres'),
                        selected: _selectedPresetAcres == 5.0,
                        onSelected: (_) => _applyPresetAcres(5.0),
                        selectedColor: Colors.green.shade300,
                        checkmarkColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          // Settings and Clear buttons
                          IconButton(
                            onPressed: () => Navigator.of(context).pushNamed('/settings'),
                            icon: const Icon(Icons.settings),
                            tooltip: 'Settings',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.shade200,
                              foregroundColor: Colors.green.shade800,
                            ),
                          ),
                          IconButton(
                            onPressed: _clear,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Clear',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade200,
                              foregroundColor: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Main action buttons
                          ElevatedButton.icon(
                            onPressed: _points.length >= 3 ? _saveCurrent : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Save field'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _points.length >= 3 && !_isFetchingWeather ? _fetchAndShowWeather : null,
                            icon: _isFetchingWeather
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.cloud),
                            label: const Text('Weather'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _points.length >= 3 && !_isFetchingNdvi ? _fetchNdvi : null,
                            icon: _isFetchingNdvi
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.terrain),
                            label: const Text('NDVI'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _points.length >= 3 && _selectedCrop != null ? _showAgriculturalAdvisory : null,
                            icon: const Icon(Icons.agriculture),
                            label: const Text('Advisory'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


