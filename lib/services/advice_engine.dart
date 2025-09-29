import 'package:agri4_app/services/open_meteo_service.dart';
import 'package:agri4_app/services/nasa_power_service.dart';

class AdviceResult {
  AdviceResult({required this.irrigationMmNext3Days, required this.messages});

  final double irrigationMmNext3Days;
  final List<String> messages;
}

class AdviceEngine {
  AdviceResult generate({required OpenMeteoDaily openMeteo, required NasaPowerDaily power}) {
    // Use last up to 7 days overlap by date index positions
    final int n = openMeteo.dates.length;
    double cumEt0 = 0;
    double cumRain = 0;
    final int days = n < 7 ? n : 7;
    for (int i = n - days; i < n; i++) {
      if (i < 0) continue;
      cumEt0 += i < openMeteo.et0Mm.length ? openMeteo.et0Mm[i] : 0;
      cumRain += i < openMeteo.precipMm.length ? openMeteo.precipMm[i] : 0;
    }

    final double deficit = (cumEt0 - cumRain).clamp(0, double.infinity);

    // Simple crop coefficient assumption Kc = 0.85 for mid-season
    final double kc = 0.85;
    final double irrigationNeedMm = deficit * kc;

    final List<String> msgs = <String>[];
    if (irrigationNeedMm > 10) {
      msgs.add('Irrigate ~${irrigationNeedMm.toStringAsFixed(0)} mm over next 3 days.');
    } else if (irrigationNeedMm > 0) {
      msgs.add('Light irrigation recommended: ${irrigationNeedMm.toStringAsFixed(0)} mm in 3 days.');
    } else {
      msgs.add('No irrigation needed this week based on ET0 − rain.');
    }

    // Heat stress heuristic using NASA POWER temps
    if (power.tmaxC.isNotEmpty) {
      final double recentTmax = power.tmaxC.last;
      if (recentTmax >= 35) {
        msgs.add('Heat stress risk: tmax ${recentTmax.toStringAsFixed(1)} °C. Consider mulching/irrigation timing.');
      }
    }

    // Dry spell heuristic
    final bool last3DaysDry = power.precipMm.takeLast(3).every((double v) => v < 1.0);
    if (last3DaysDry) {
      msgs.add('Dry spell detected (last 3 days < 1 mm). Monitor soil moisture.');
    }

    return AdviceResult(irrigationMmNext3Days: irrigationNeedMm, messages: msgs);
  }
}

extension _TakeLast on List<double> {
  Iterable<double> takeLast(int count) => skip(length > count ? length - count : 0);
}


