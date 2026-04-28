import '../models/calc_result.dart';

class DoseLogic {
  static CalculationResult calculate({
    required double weightKg,
    required double dosePerKg,
    required double? maxDoseMg,
    required String drugName,
    double? concentration, // mg/mL untuk sirup/injeksi
    double? tabletStrength, // mg per tablet
  }) {
    final rawDose = weightKg * dosePerKg;
    final effectiveMax = maxDoseMg;
    final finalDose = (effectiveMax != null && rawDose > effectiveMax)
        ? effectiveMax
        : rawDose;
    final capped = effectiveMax != null && rawDose > effectiveMax;

    CalcSeverity severity;
    String interpretation;
    final steps = <String>[
      'Rumus: Dosis Total = BB × Dosis/kgBB',
      'Dosis Total = $weightKg kg × $dosePerKg mg/kg',
      'Dosis Total = ${rawDose.toStringAsFixed(2)} mg',
    ];

    if (capped) {
      severity = CalcSeverity.warning;
      interpretation = '⚠️ Dibatasi dosis maksimal ($maxDoseMg mg)';
      steps.add('Dosis melebihi batas aman → dibatasi ke $maxDoseMg mg');
    } else if (maxDoseMg != null && rawDose >= maxDoseMg * 0.8) {
      severity = CalcSeverity.warning;
      interpretation = '⚠️ Mendekati batas dosis maksimal';
    } else {
      severity = CalcSeverity.normal;
      interpretation = 'Dosis dalam batas aman';
    }

    final extras = <String, String>{
      'Dosis Total': '${finalDose.toStringAsFixed(2)} mg',
    };

    // Konversi ke tablet
    if (tabletStrength != null && tabletStrength > 0) {
      final tablets = finalDose / tabletStrength;
      extras['Konversi Tablet (${tabletStrength.toStringAsFixed(0)} mg)'] =
          '${tablets.toStringAsFixed(2)} tablet';
      steps.add(
          'Konversi tablet: ${finalDose.toStringAsFixed(2)} ÷ $tabletStrength = ${tablets.toStringAsFixed(2)} tablet');
    }

    // Konversi ke sirup/injeksi
    if (concentration != null && concentration > 0) {
      final volumeMl = finalDose / concentration;
      extras['Konversi Sediaan Cair (${concentration}mg/mL)'] =
          '${volumeMl.toStringAsFixed(2)} mL';
      steps.add(
          'Konversi cair: ${finalDose.toStringAsFixed(2)} ÷ $concentration = ${volumeMl.toStringAsFixed(2)} mL');
    }

    return CalculationResult(
      moduleName: 'Dosis Obat',
      label: 'Dosis $drugName',
      value: finalDose.toStringAsFixed(2),
      unit: 'mg',
      interpretation: interpretation,
      severity: severity,
      steps: steps,
      extras: extras,
      sourceLabel: 'WHO guideline',
      confidenceLabel: 'Kalkulasi Dosis',
      interpretationHint: 'Interpretasi umum: Hasil berdasarkan berat badan aktual. '
          'Pertimbangkan kondisi klinis pasien, fungsi organ, dan interaksi obat sebelum pemberian.',
    );
  }

  /// Unit conversion utilities
  static double mgToGram(double mg) => mg / 1000;
  static double gramToMg(double g) => g * 1000;
  static double mlToLiter(double ml) => ml / 1000;
  static double literToMl(double l) => l * 1000;
}
