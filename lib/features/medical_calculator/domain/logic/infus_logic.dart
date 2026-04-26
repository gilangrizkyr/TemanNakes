import '../models/calc_result.dart';

class InfusLogic {
  /// Hitung tetesan infus (makro/mikro drop)
  static CalculationResult calcDropRate({
    required double volumeMl,
    required double durationMinutes,
    required int dropFactor, // 20 = makro, 60 = mikro
  }) {
    if (durationMinutes <= 0 || volumeMl <= 0) {
      return CalculationResult(
        moduleName: 'Infus',
        label: 'Kecepatan Tetesan',
        value: '0',
        unit: 'tetes/menit',
        interpretation: '⚠️ Input volume atau durasi tidak valid',
        severity: CalcSeverity.danger,
        steps: ['Durasi atau volume harus lebih dari 0.'],
      );
    }
    final dropsPerMin = (volumeMl * dropFactor) / durationMinutes;
    final rounded = dropsPerMin.round();

    CalcSeverity severity = CalcSeverity.normal;
    String interpretation = 'Normal';
    if (rounded > 60) {
      severity = CalcSeverity.warning;
      interpretation = '⚠️ Tetesan cepat, pantau pasien';
    }
    if (rounded > 120) {
      severity = CalcSeverity.danger;
      interpretation = '🔴 Terlalu cepat, risiko overload';
    }

    final durationHours = durationMinutes / 60;

    return CalculationResult(
      moduleName: 'Infus',
      label: 'Kecepatan Tetesan',
      value: rounded.toString(),
      unit: 'tetes/menit',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus: Tetes/menit = (Volume × Faktor Tetes) ÷ Waktu (menit)',
        'Faktor tetes: $dropFactor (${dropFactor == 60 ? "mikro" : "makro"})',
        'Tetes/menit = ($volumeMl mL × $dropFactor) ÷ $durationMinutes menit',
        'Tetes/menit = ${dropsPerMin.toStringAsFixed(1)} → dibulatkan = $rounded tetes/menit',
      ],
      extras: {
        'Volume Total': '$volumeMl mL',
        'Durasi': '${durationHours.toStringAsFixed(1)} jam',
        'Faktor Tetes': '$dropFactor (${dropFactor == 60 ? "mikro" : "makro"})',
      },
    );
  }

  /// Hitung kecepatan infus pump (mL/jam)
  static CalculationResult calcPumpRate({
    required double volumeMl,
    required double durationHours,
  }) {
    if (durationHours <= 0 || volumeMl <= 0) {
      return CalculationResult(
        moduleName: 'Infus',
        label: 'Kecepatan Infus Pump',
        value: '0',
        unit: 'mL/jam',
        interpretation: '⚠️ Input tidak valid',
        severity: CalcSeverity.danger,
        steps: ['Durasi harus lebih dari 0 jam'],
      );
    }
    final ratePerHour = volumeMl / durationHours;
    final rounded = ratePerHour.round();

    CalcSeverity severity = CalcSeverity.normal;
    String interpretation = 'Normal';
    if (ratePerHour > 200) {
      severity = CalcSeverity.warning;
      interpretation = '⚠️ Kecepatan tinggi, monitor ketat';
    }

    return CalculationResult(
      moduleName: 'Infus',
      label: 'Kecepatan Infus Pump',
      value: rounded.toString(),
      unit: 'mL/jam',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus: Kecepatan (mL/jam) = Volume ÷ Durasi (jam)',
        'Kecepatan = $volumeMl mL ÷ $durationHours jam',
        'Kecepatan = ${ratePerHour.toStringAsFixed(1)} → dibulatkan = $rounded mL/jam',
      ],
      extras: {
        'Volume Total': '$volumeMl mL',
        'Durasi': '$durationHours jam',
      },
    );
  }
}
