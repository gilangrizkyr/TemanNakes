import '../models/calc_result.dart';

class PatientStatusLogic {
  static CalculationResult calcBMI({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      return CalculationResult(
        moduleName: 'Status Pasien',
        label: 'BMI',
        value: '0',
        unit: 'kg/m²',
        interpretation: '⚠️ Input tidak valid',
        severity: CalcSeverity.danger,
        steps: ['Tinggi dan Berat harus > 0'],
      );
    }
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    String category;
    CalcSeverity severity;

    if (bmi < 17.0) {
      category = 'Sangat Kurus';
      severity = CalcSeverity.danger;
    } else if (bmi < 18.5) {
      category = 'Kurus';
      severity = CalcSeverity.warning;
    } else if (bmi < 25.0) {
      category = 'Normal';
      severity = CalcSeverity.normal;
    } else if (bmi < 27.0) {
      category = 'Overweight';
      severity = CalcSeverity.warning;
    } else if (bmi < 30.0) {
      category = 'Obesitas Ringan';
      severity = CalcSeverity.warning;
    } else {
      category = 'Obesitas Berat';
      severity = CalcSeverity.danger;
    }

    return CalculationResult(
      moduleName: 'Status Pasien',
      label: 'BMI',
      value: bmi.toStringAsFixed(1),
      unit: 'kg/m²',
      interpretation: category,
      severity: severity,
      steps: [
        'Rumus: BMI = Berat (kg) ÷ Tinggi² (m²)',
        'Tinggi dalam meter: ${heightCm}cm = ${heightM.toStringAsFixed(2)} m',
        'BMI = $weightKg ÷ (${heightM.toStringAsFixed(2)})² = ${bmi.toStringAsFixed(1)} kg/m²',
        'Kategori: $category (Ref: WHO)',
      ],
      extras: {
        'Berat Ideal (±)': _idealWeightRange(heightCm),
      },
      sourceLabel: 'WHO guideline',
      confidenceLabel: 'Klasifikasi BMI',
      interpretationHint: bmi < 17.0
          ? 'Interpretasi umum: Sangat kurus berdasarkan klasifikasi WHO. Pertimbangkan asesmen status gizi.'
          : bmi < 18.5
              ? 'Interpretasi umum: Berat badan kurang. Pertimbangkan evaluasi asupan nutrisi.'
              : bmi < 25.0
                  ? 'Interpretasi umum: Berat badan ideal sesuai klasifikasi WHO.'
                  : bmi < 27.0
                      ? 'Interpretasi umum: Sedikit di atas ideal. Pertimbangkan pemantauan faktor risiko metabolik.'
                      : bmi < 30.0
                          ? 'Interpretasi umum: Overweight. Pertimbangkan evaluasi faktor risiko kardiovaskular.'
                          : 'Interpretasi umum: Obesitas berdasarkan WHO. Pertimbangkan asesmen komorbid.',
    );
  }

  static String _idealWeightRange(double heightCm) {
    final heightM = heightCm / 100;
    final minW = (18.5 * heightM * heightM).toStringAsFixed(0);
    final maxW = (24.9 * heightM * heightM).toStringAsFixed(0);
    return '$minW – $maxW kg';
  }

  static CalculationResult calcMAP({
    required double systolic,
    required double diastolic,
  }) {
    if (systolic <= 0 || diastolic <= 0 || systolic < diastolic) {
      return CalculationResult(
        moduleName: 'Status Pasien',
        label: 'MAP (Mean Arterial Pressure)',
        value: '0',
        unit: 'mmHg',
        interpretation: '⚠️ Tekanan darah tidak valid (Sistolik < Diastolik)',
        severity: CalcSeverity.danger,
        steps: ['Sistolik harus lebih besar dari Diastolik.'],
      );
    }
    // MAP = (SBP + 2×DBP) / 3
    final map = (systolic + 2 * diastolic) / 3;

    String interpretation;
    CalcSeverity severity;

    if (map < 60) {
      interpretation = '🔴 Rendah – Risiko hipoperfusi organ';
      severity = CalcSeverity.danger;
    } else if (map < 70) {
      interpretation = '⚠️ Batas rendah, pantau ketat';
      severity = CalcSeverity.warning;
    } else if (map <= 100) {
      interpretation = '✅ Normal (60–100 mmHg)';
      severity = CalcSeverity.normal;
    } else {
      interpretation = '⚠️ Tinggi – Risiko hipertensi';
      severity = CalcSeverity.warning;
    }

    return CalculationResult(
      moduleName: 'Status Pasien',
      label: 'MAP (Mean Arterial Pressure)',
      value: map.toStringAsFixed(1),
      unit: 'mmHg',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus: MAP = (Sistolik + 2 × Diastolik) ÷ 3',
        'MAP = ($systolic + 2 × $diastolic) ÷ 3',
        'MAP = (${systolic + 2 * diastolic}) ÷ 3 = ${map.toStringAsFixed(1)} mmHg',
        'Nilai normal: 60–100 mmHg',
      ],
      sourceLabel: 'Rumus Klinis Umum',
      confidenceLabel: 'Kalkulasi MAP',
      interpretationHint: map < 60
          ? 'Interpretasi umum: MAP rendah — pertimbangkan evaluasi perfusi organ sesuai kondisi klinis.'
          : map < 70
              ? 'Interpretasi umum: MAP batas bawah. Pemantauan ketat sesuai pertimbangan klinis dianjurkan.'
              : map <= 100
                  ? 'Interpretasi umum: MAP dalam rentang target perfusi organ yang umum (70–100 mmHg).'
                  : 'Interpretasi umum: MAP tinggi. Pertimbangkan evaluasi tekanan darah dan faktor risiko.',
    );
  }

  static CalculationResult calcShockIndex({
    required double heartRate,
    required double systolic,
  }) {
    if (heartRate <= 0 || systolic <= 0) {
      return CalculationResult(
        moduleName: 'Status Pasien',
        label: 'Shock Index',
        value: '0',
        unit: '',
        interpretation: '⚠️ Input tidak valid',
        severity: CalcSeverity.danger,
        steps: ['HR dan Sistolik harus > 0'],
      );
    }
    final si = heartRate / systolic;

    String interpretation;
    CalcSeverity severity;

    if (si < 0.6) {
      interpretation = '✅ Normal';
      severity = CalcSeverity.normal;
    } else if (si < 1.0) {
      interpretation = '⚠️ Ringan – Waspada';
      severity = CalcSeverity.warning;
    } else if (si < 1.4) {
      interpretation = '🔴 Moderat – Risiko syok';
      severity = CalcSeverity.danger;
    } else {
      interpretation = '🔴 Berat – Syok berat, tindakan segera';
      severity = CalcSeverity.danger;
    }

    return CalculationResult(
      moduleName: 'Status Pasien',
      label: 'Shock Index',
      value: si.toStringAsFixed(2),
      unit: '',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus: Shock Index = HR ÷ Tekanan Sistolik',
        'SI = $heartRate ÷ $systolic = ${si.toStringAsFixed(2)}',
        '< 0.6 = Normal | 0.6–1.0 = Ringan | 1.0–1.4 = Moderat | >1.4 = Berat',
      ],
      sourceLabel: 'Standar Klinis',
      confidenceLabel: 'Indeks Klinis',
      interpretationHint: si < 0.6
          ? 'Interpretasi umum: Hemodinamik stabil berdasarkan Shock Index.'
          : si < 1.0
              ? 'Interpretasi umum: Perlu pemantauan. Pertimbangkan observasi ketat sesuai kondisi klinis.'
              : si < 1.4
                  ? 'Interpretasi umum: Nilai menunjukkan kemungkinan gangguan hemodinamik. Penilaian klinis segera dianjurkan.'
                  : 'Interpretasi umum: Nilai tinggi. Evaluasi klinis menyeluruh dan tindakan sesuai protokol sangat dianjurkan.',
    );
  }
}
