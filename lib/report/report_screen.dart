import 'package:flutter/material.dart';
import 'package:agri4_app/services/open_meteo_service.dart';
import 'package:agri4_app/services/nasa_power_service.dart';
import 'package:agri4_app/services/advice_engine.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.openMeteo, required this.power});

  final OpenMeteoDaily openMeteo;
  final NasaPowerDaily power;

  @override
  Widget build(BuildContext context) {
    final AdviceResult advice = AdviceEngine().generate(openMeteo: openMeteo, power: power);
    return Scaffold(
      appBar: AppBar(title: const Text('Field Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Irrigation (next 3 days): ${advice.irrigationMmNext3Days.toStringAsFixed(0)} mm', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...advice.messages.map((String m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $m'),
                )),
            const SizedBox(height: 16),
            const Text('Recent Weather (Open‑Meteo)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: openMeteo.dates.length,
                itemBuilder: (BuildContext _, int i) {
                  final String date = openMeteo.dates[i];
                  final double p = i < openMeteo.precipMm.length ? openMeteo.precipMm[i] : 0;
                  final double e = i < openMeteo.et0Mm.length ? openMeteo.et0Mm[i] : 0;
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
            Expanded(
              child: ListView.builder(
                itemCount: power.dates.length,
                itemBuilder: (BuildContext _, int i) {
                  final String date = power.dates[i];
                  final double tmax = i < power.tmaxC.length ? power.tmaxC[i] : 0;
                  final double tmin = i < power.tminC.length ? power.tminC[i] : 0;
                  final double p = i < power.precipMm.length ? power.precipMm[i] : 0;
                  final double rad = i < power.solarMJm2.length ? power.solarMJm2[i] : 0;
                  return ListTile(
                    dense: true,
                    title: Text(date),
                    subtitle: Text('Tmax: ${tmax.toStringAsFixed(1)} °C, Tmin: ${tmin.toStringAsFixed(1)} °C, Rain: ${p.toStringAsFixed(1)} mm, Solar: ${rad.toStringAsFixed(1)} MJ/m²'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


