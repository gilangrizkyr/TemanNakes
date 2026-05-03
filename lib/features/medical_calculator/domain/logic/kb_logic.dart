import '../models/calc_result.dart';

class KbLogic {
  /// Hitung jadwal suntik KB berikutnya
  /// [type] 1: Suntik 1 Bulan (28 hari)
  /// [type] 3: Suntik 3 Bulan (84 hari)
  static CalculationResult calcKbInjection({
    required DateTime lastInjection,
    required int type,
  }) {
    if (lastInjection.isAfter(DateTime.now())) {
      return CalculationResult(
        moduleName: 'Kalkulator KB',
        label: 'Jadwal Kembali',
        value: '-',
        unit: '',
        interpretation: '⚠️ Tanggal suntik terakhir tidak valid (masa depan)',
        severity: CalcSeverity.danger,
        steps: ['Tanggal suntik tidak boleh melebihi hari ini.'],
      );
    }

    final intervalDays = type == 3 ? 84 : 28;
    final nextInjection = lastInjection.add(Duration(days: intervalDays));
    
    // Mnemonic calculation for 3-month (Date -7, Month +3)
    // Note: This is a reference, the app uses precise day addition.
    String mnemonic = '';
    if (type == 3) {
      final mDay = lastInjection.day - 7;
      final mMonth = lastInjection.month + 3;
      mnemonic = ' (Mnemonic: Tanggal ${mDay > 0 ? mDay : "sebelumnya"}, Bulan ${mMonth > 12 ? mMonth - 12 : mMonth})';
    }

    final today = DateTime.now();
    final daysToNext = nextInjection.difference(today).inDays;

    String interpretation;
    CalcSeverity severity;

    if (daysToNext < 0) {
      interpretation = '⚠️ Sudah melewati jadwal (${-daysToNext} hari lalu)';
      severity = CalcSeverity.danger;
    } else if (daysToNext <= 3) {
      interpretation = '⚠️ Segera kembali ($daysToNext hari lagi)';
      severity = CalcSeverity.warning;
    } else {
      interpretation = 'Jadwal rutin – $daysToNext hari lagi';
      severity = CalcSeverity.normal;
    }

    return CalculationResult(
      moduleName: 'Kalkulator KB',
      label: 'Jadwal Kembali',
      value: _formatDate(nextInjection),
      unit: '',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Interval standar: $intervalDays hari (${type == 3 ? "12 minggu" : "4 minggu"})',
        'Tanggal terakhir: ${_formatDate(lastInjection)}',
        'Metode: Penambahan hari presisi (Gold Standard)',
        'Hasil: ${_formatDate(nextInjection)}$mnemonic',
      ],
      extras: {
        'Tipe KB': 'Suntik $type Bulan',
        'Sisa Waktu': '$daysToNext hari',
      },
      sourceLabel: 'Standar Klinis Indonesia (BKKBN/Kemenkes)',
      confidenceLabel: 'Presisi Hari (Akurasi Tinggi)',
      interpretationHint: daysToNext < 0
          ? 'Interpretasi umum: Jadwal sudah terlewati. Segera lakukan penyuntikan dan gunakan kontrasepsi tambahan (kondom) selama 7 hari bila perlu.'
          : 'Interpretasi umum: Jadwal penyuntikan rutin sesuai interval medis. Disarankan kembali tepat waktu untuk efektivitas maksimal.',
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
