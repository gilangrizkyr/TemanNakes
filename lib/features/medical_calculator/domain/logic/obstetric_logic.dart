import '../models/calc_result.dart';

class ObstetricLogic {
  /// Hitung HPL (Hari Perkiraan Lahir) — Naegele Rule
  static CalculationResult calcHPL({required DateTime hpht}) {
    if (hpht.isAfter(DateTime.now())) {
      return CalculationResult(
        moduleName: 'Kebidanan',
        label: 'HPL (Naegele)',
        value: '-',
        unit: '',
        interpretation: '⚠️ Tanggal HPHT tidak valid (masa depan)',
        severity: CalcSeverity.danger,
        steps: ['HPHT tidak boleh melebihi tanggal hari ini.'],
      );
    }
    // Naegele: +1 tahun, -3 bulan, +7 hari
    final hpl = DateTime(
      hpht.year + (hpht.month > 3 ? 1 : 0),
      hpht.month <= 3 ? hpht.month + 9 : hpht.month - 3,
      hpht.day + 7,
    );

    final today = DateTime.now();
    final daysRemaining = hpl.difference(today).inDays;
    final weeksRemaining = (daysRemaining / 7).floor();

    String interpretation;
    CalcSeverity severity;

    if (daysRemaining < 0) {
      interpretation = 'Telah melewati HPL (${(-daysRemaining)} hari lalu)';
      severity = CalcSeverity.warning;
    } else if (daysRemaining <= 14) {
      interpretation = '⚠️ Segera lahir ($daysRemaining hari lagi)';
      severity = CalcSeverity.warning;
    } else {
      interpretation = 'Normal – $weeksRemaining minggu lagi';
      severity = CalcSeverity.normal;
    }

    return CalculationResult(
      moduleName: 'Kebidanan',
      label: 'HPL (Naegele)',
      value: _formatDate(hpl),
      unit: '',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus Naegele: HPHT + 1 tahun – 3 bulan + 7 hari',
        'HPHT: ${_formatDate(hpht)}',
        'HPL: ${_formatDate(hpl)}',
      ],
      extras: {
        'HPHT': _formatDate(hpht),
        'Sisa Waktu': '$weeksRemaining minggu ($daysRemaining hari)',
      },
      sourceLabel: 'Standar Obstetri (Naegele)',
      confidenceLabel: 'Estimasi (Naegele)',
      interpretationHint: daysRemaining < 0
          ? 'Interpretasi umum: Sudah melewati estimasi HPL. Evaluasi klinis lebih lanjut sesuai kondisi ibu dan janin.'
          : daysRemaining <= 14
              ? 'Interpretasi umum: Mendekati HPL. Pertimbangkan pemantauan lebih ketat sesuai kondisi ibu.'
              : 'Interpretasi umum: Estimasi HPL berdasarkan Rumus Naegele. Konfirmasi dengan USG bila tersedia.',
    );
  }

  /// Hitung usia kehamilan dari HPHT
  static CalculationResult calcGestationalAge({required DateTime hpht}) {
    final today = DateTime.now();
    final totalDays = today.difference(hpht).inDays;
    final weeks = totalDays ~/ 7;
    final days = totalDays % 7;

    CalcSeverity severity;
    String interpretation;

    if (weeks < 0) {
      interpretation = 'HPHT tidak valid';
      severity = CalcSeverity.danger;
    } else if (weeks < 28) {
      interpretation = 'Trimester ${weeks < 14 ? "I" : "II"} (${weeks}m${days}h)';
      severity = CalcSeverity.normal;
    } else if (weeks < 37) {
      interpretation = '⚠️ Prematur (${weeks}m${days}h)';
      severity = CalcSeverity.warning;
    } else if (weeks <= 42) {
      interpretation = '✅ Aterm (${weeks}m${days}h)';
      severity = CalcSeverity.normal;
    } else {
      interpretation = '⚠️ Post-term, perlu evaluasi';
      severity = CalcSeverity.warning;
    }

    return CalculationResult(
      moduleName: 'Kebidanan',
      label: 'Usia Kehamilan',
      value: '$weeks minggu $days hari',
      unit: '',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Hitung dari HPHT ke hari ini',
        'Total hari: $totalDays hari',
        'Usia kehamilan: $weeks minggu $days hari',
      ],
      sourceLabel: 'Rumus Klinis Umum',
      confidenceLabel: 'Estimasi Klinis',
      interpretationHint: weeks < 28
          ? 'Interpretasi umum: Trimester awal-pertengahan. Rutinkan pemantauan ANC sesuai jadwal.'
          : weeks < 37
              ? 'Interpretasi umum: Usia kehamilan prematur. Pertimbangkan konsultasi klinis lanjut.'
              : weeks <= 42
                  ? 'Interpretasi umum: Usia kehamilan aterm. Pantau tanda-tanda persalinan sesuai kondisi ibu.'
                  : 'Interpretasi umum: Melewati usia aterm. Evaluasi klinis dan pertimbangkan tatalaksana sesuai pedoman.',
    );
  }

  /// Taksiran Berat Janin (TBJ) — Johnson Formula
  static CalculationResult calcFetalWeight({
    required double fundalHeightCm,
    required bool isEngaged, // kepala sudah masuk panggul
  }) {
    if (fundalHeightCm <= 0) {
      return CalculationResult(
        moduleName: 'Kebidanan',
        label: 'Taksiran Berat Janin (TBJ)',
        value: '0',
        unit: 'gram',
        interpretation: '⚠️ Input TFU tidak valid',
        severity: CalcSeverity.danger,
        steps: ['TFU harus lebih dari 0 cm'],
      );
    }
    // Johnson: TBJ = (TFU - n) × 155 gram
    // n = 12 jika kepala blm masuk, 11 jika sudah masuk
    final n = isEngaged ? 11 : 12;
    
    // Safety Guard: If TFU is too small, return 0 instead of negative
    if (fundalHeightCm <= n) {
      return CalculationResult(
        moduleName: 'Kebidanan',
        label: 'Taksiran Berat Janin (TBJ)',
        value: '0',
        unit: 'gram',
        interpretation: '⚠️ TFU terlalu kecil untuk taksiran TBJ',
        severity: CalcSeverity.warning,
        steps: ['TFU ($fundalHeightCm cm) ≤ konstanta $n'],
      );
    }

    final tbj = (fundalHeightCm - n) * 155;

    CalcSeverity severity;
    String interpretation;

    if (tbj < 1500) {
      interpretation = '⚠️ Berat lahir sangat rendah (< 1500g)';
      severity = CalcSeverity.danger;
    } else if (tbj < 2500) {
      interpretation = '⚠️ Berat lahir rendah (BBLR)';
      severity = CalcSeverity.warning;
    } else if (tbj <= 4000) {
      interpretation = '✅ Berat normal (2500–4000g)';
      severity = CalcSeverity.normal;
    } else {
      interpretation = '⚠️ Makrosomia (> 4000g)';
      severity = CalcSeverity.warning;
    }

    return CalculationResult(
      moduleName: 'Kebidanan',
      label: 'Taksiran Berat Janin (TBJ)',
      value: tbj.toStringAsFixed(0),
      unit: 'gram',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus Johnson: TBJ = (TFU – n) × 155',
        'n = $n (${isEngaged ? "kepala sudah masuk panggul" : "kepala belum masuk panggul"})',
        'TBJ = ($fundalHeightCm – $n) × 155 = ${tbj.toStringAsFixed(0)} gram',
        'Referensi: 2500–4000 gram = Berat Normal (WHO)',
      ],
      sourceLabel: 'Standar Obstetri (Johnson)',
      confidenceLabel: 'Estimasi (Johnson)',
      interpretationHint: tbj < 1500
          ? 'Interpretasi umum: Taksiran berat sangat rendah. Pertimbangkan evaluasi klinis dan dukungan neonatal.'
          : tbj < 2500
              ? 'Interpretasi umum: Taksiran BBLR. Pertimbangkan pemantauan kehamilan dan persiapan klinis.'
              : tbj <= 4000
                  ? 'Interpretasi umum: Taksiran berat dalam rentang normal (Johnson-Toshach). Hasil estimasi, konfirmasi dengan USG bila tersedia.'
                  : 'Interpretasi umum: Taksiran di atas 4000g. Pertimbangkan evaluasi faktor risiko makrosomia.',
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
