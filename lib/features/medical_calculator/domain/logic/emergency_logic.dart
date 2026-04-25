import '../models/calc_result.dart';

/// GCS & APGAR scoring logic
class EmergencyLogic {
  static CalculationResult calcGCS({
    required int eye,    // 1–4
    required int verbal, // 1–5
    required int motor,  // 1–6
  }) {
    final total = eye + verbal + motor;

    String interpretation;
    CalcSeverity severity;

    if (total >= 14) {
      interpretation = '✅ Ringan (${total == 15 ? "Sadar Penuh" : "Hampir Normal"})';
      severity = CalcSeverity.normal;
    } else if (total >= 9) {
      interpretation = '⚠️ Sedang – Perlu pemantauan';
      severity = CalcSeverity.warning;
    } else if (total >= 4) {
      interpretation = '🔴 Berat – Gangguan kesadaran serius';
      severity = CalcSeverity.danger;
    } else {
      interpretation = '🔴 Sangat Berat (3=Koma terdalam)';
      severity = CalcSeverity.danger;
    }

    return CalculationResult(
      moduleName: 'Emergency',
      label: 'GCS (Glasgow Coma Scale)',
      value: total.toString(),
      unit: '/ 15',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'E (Eye Opening): $eye/4',
        'V (Verbal Response): $verbal/5',
        'M (Motor Response): $motor/6',
        'Total GCS: $eye + $verbal + $motor = $total',
        '14–15: Ringan | 9–13: Sedang | 3–8: Berat',
      ],
      extras: {
        'Eye Opening (E)': '$eye/4 – ${_gcsEye(eye)}',
        'Verbal (V)': '$verbal/5 – ${_gcsVerbal(verbal)}',
        'Motor (M)': '$motor/6 – ${_gcsMotor(motor)}',
      },
    );
  }

  static String _gcsEye(int v) => switch (v) {
    4 => 'Spontan',
    3 => 'Terhadap suara',
    2 => 'Terhadap nyeri',
    _ => 'Tidak ada',
  };

  static String _gcsVerbal(int v) => switch (v) {
    5 => 'Orientasi baik',
    4 => 'Bingung',
    3 => 'Kata-kata tidak tepat',
    2 => 'Suara tidak dimengerti',
    _ => 'Tidak ada',
  };

  static String _gcsMotor(int v) => switch (v) {
    6 => 'Ikuti perintah',
    5 => 'Lokalisasi nyeri',
    4 => 'Fleksi norml (withdraw)',
    3 => 'Fleksi abnormal',
    2 => 'Ekstensi abnormal',
    _ => 'Tidak ada',
  };

  static CalculationResult calcAPGAR({
    required int appearance,  // 0–2 (warna kulit)
    required int pulse,       // 0–2 (nadi)
    required int grimace,     // 0–2 (refleks)
    required int activity,    // 0–2 (tonus otot)
    required int respiration, // 0–2 (pernapasan)
    required int minuteAfterBirth, // 1 atau 5
  }) {
    final total = appearance + pulse + grimace + activity + respiration;

    String interpretation;
    CalcSeverity severity;

    if (total >= 7) {
      interpretation = '✅ Normal – Bayi sehat ($total/10)';
      severity = CalcSeverity.normal;
    } else if (total >= 4) {
      interpretation = '⚠️ Asfiksia Ringan-Sedang – Perlu stimulasi';
      severity = CalcSeverity.warning;
    } else {
      interpretation = '🔴 Asfiksia Berat – Resusitasi segera';
      severity = CalcSeverity.danger;
    }

    return CalculationResult(
      moduleName: 'Emergency',
      label: 'APGAR Score (Menit ke-$minuteAfterBirth)',
      value: total.toString(),
      unit: '/ 10',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'A – Appearance (Warna): $appearance/2',
        'P – Pulse (Nadi): $pulse/2',
        'G – Grimace (Refleks): $grimace/2',
        'A – Activity (Tonus): $activity/2',
        'R – Respiration (Nafas): $respiration/2',
        'Total APGAR = $total',
        '7–10: Normal | 4–6: Asfiksia Ringan | 0–3: Asfiksia Berat',
      ],
    );
  }
}
