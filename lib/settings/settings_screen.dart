import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agri4_app/storage/settings_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsStorage _settings;
  late TextEditingController _areaCtrl;
  late TextEditingController _tokenCtrl;
  late TextEditingController _backendCtrl;
  String _units = 'acres';

  @override
  void initState() {
    super.initState();
    final Box sbox = Hive.box('settings');
    _settings = SettingsStorage.of(sbox);
    _units = _settings.units;
    _areaCtrl = TextEditingController(text: _settings.targetAreaAcres.toStringAsFixed(1));
    _tokenCtrl = TextEditingController(text: _settings.sentinelHubToken ?? '');
    _backendCtrl = TextEditingController(text: _settings.backendBaseUrl ?? '');
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _tokenCtrl.dispose();
    _backendCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Units'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _units,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'acres', child: Text('Acres')),
                DropdownMenuItem<String>(value: 'hectares', child: Text('Hectares')),
              ],
              onChanged: (String? v) => setState(() => _units = v ?? 'acres'),
            ),
            const SizedBox(height: 16),
            const Text('Target Area (acres)'),
            TextField(controller: _areaCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            const Text('Sentinel Hub Token'),
            TextField(controller: _tokenCtrl),
            const SizedBox(height: 16),
            const Text('Backend Base URL (optional, e.g., http://your-server:8080)'),
            TextField(controller: _backendCtrl),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await _settings.setUnits(_units);
                final double area = double.tryParse(_areaCtrl.text.trim()) ?? 2.0;
                await _settings.setTargetAreaAcres(area);
                final String token = _tokenCtrl.text.trim();
                if (token.isNotEmpty) {
                  await _settings.setSentinelHubToken(token);
                }
                final String backend = _backendCtrl.text.trim();
                if (backend.isNotEmpty) {
                  await _settings.setBackendBaseUrl(backend);
                }
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}


