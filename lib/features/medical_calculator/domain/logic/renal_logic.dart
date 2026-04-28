import 'dart:math' as math;
import '../models/calc_result.dart';

class RenalLogic {
  /// Cockcroft-Gault formula for Creatinine Clearance (mL/min)
  static CalculationResult calcCreatinineClearance({
    required double ageyears,
    required double weightKg,
    required double serumCreatinine, // mg/dL
    required bool isFemale,
  }) {
    if (serumCreatinine <= 0 || weightKg <= 0 || ageyears <= 0) {
      return CalculationResult(
        moduleName: 'Ginjal & Obat',
        label: 'Klirens Kreatinin (CrCl)',
        value: '0',
        unit: 'mL/menit',
        interpretation: '⚠️ Input tidak valid',
        severity: CalcSeverity.danger,
        steps: ['Kreatinin, Berat, dan Usia harus > 0'],
      );
    }
    double clcr = ((140 - ageyears) * weightKg) / (72 * serumCreatinine);
    if (isFemale) clcr *= 0.85;

    String interpretation;
    CalcSeverity severity;

    if (clcr >= 90) {
      interpretation = '✅ Normal / Tahap 1 (≥ 90 mL/min)';
      severity = CalcSeverity.normal;
    } else if (clcr >= 60) {
      interpretation = '⚠️ Penurunan Ringan – CKD Tahap 2';
      severity = CalcSeverity.warning;
    } else if (clcr >= 30) {
      interpretation = '🔴 Penurunan Sedang – CKD Tahap 3';
      severity = CalcSeverity.danger;
    } else if (clcr >= 15) {
      interpretation = '🔴 Penurunan Berat – CKD Tahap 4';
      severity = CalcSeverity.danger;
    } else {
      interpretation = '🔴 Gagal Ginjal – CKD Tahap 5 (<15)';
      severity = CalcSeverity.danger;
    }

    return CalculationResult(
      moduleName: 'Ginjal & Obat',
      label: 'Klirens Kreatinin (CrCl)',
      value: clcr.toStringAsFixed(1),
      unit: 'mL/menit',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus Cockcroft-Gault:',
        'ClCr = [(140 – Usia) × BB] ÷ (72 × Kreatinin)',
        if (isFemale) '× 0.85 (faktor koreksi perempuan)',
        'ClCr = [(140 – $ageyears) × $weightKg] ÷ (72 × $serumCreatinine)',
        'ClCr = ${clcr.toStringAsFixed(1)} mL/menit',
      ],
      sourceLabel: 'Rumus Cockcroft-Gault',
      confidenceLabel: 'Estimasi Klinis',
      interpretationHint: clcr >= 90
          ? 'Interpretasi umum: Fungsi ginjal dalam batas normal (Cockcroft-Gault). Tetap pertimbangkan faktor klinis pasien.'
          : clcr >= 60
              ? 'Interpretasi umum: Penurunan ringan. Pertimbangkan pemantauan berkala sesuai kondisi klinis.'
              : clcr >= 30
                  ? 'Interpretasi umum: Penurunan sedang. Pertimbangkan evaluasi penyesuaian dosis obat tertentu bersama dokter.'
                  : clcr >= 15
                      ? 'Interpretasi umum: Penurunan berat. Konsultasi tatalaksana farmakologi sangat dianjurkan.'
                      : 'Interpretasi umum: Nilai sangat rendah. Evaluasi klinis dan rujukan sesuai pertimbangan dokter.',
    );
  }

  /// CKD-EPI 2021 eGFR estimation
  static CalculationResult calcEGFR({
    required double serumCreatinine, // mg/dL
    required double ageyears,
    required bool isFemale,
  }) {
    if (serumCreatinine <= 0 || ageyears <= 0) {
      return CalculationResult(
        moduleName: 'Ginjal & Obat',
        label: 'eGFR (CKD-EPI 2021)',
        value: '0',
        unit: 'mL/mnt/1.73m²',
        interpretation: '⚠️ Input tidak valid',
        severity: CalcSeverity.danger,
        steps: ['Kreatinin dan Usia harus > 0'],
      );
    }
    final k = isFemale ? 0.7 : 0.9;
    final alpha = isFemale ? -0.241 : -0.302;
    const factor = 142.0;
    final scOverK = serumCreatinine / k;

    double eGFR;
    if (scOverK <= 1) {
      eGFR = factor *
          math.pow(scOverK, alpha).toDouble() *
          math.pow(0.9938, ageyears).toDouble() *
          (isFemale ? 1.012 : 1.0);
    } else {
      eGFR = factor *
          math.pow(scOverK, -1.200).toDouble() *
          math.pow(0.9938, ageyears).toDouble() *
          (isFemale ? 1.012 : 1.0);
    }

    String interpretation;
    CalcSeverity severity;

    if (eGFR >= 90) {
      interpretation = '✅ Normal – CKD G1';
      severity = CalcSeverity.normal;
    } else if (eGFR >= 60) {
      interpretation = '⚠️ Penurunan Ringan – CKD G2';
      severity = CalcSeverity.warning;
    } else if (eGFR >= 45) {
      interpretation = '⚠️ Penurunan Ringan-Sedang – CKD G3a';
      severity = CalcSeverity.warning;
    } else if (eGFR >= 30) {
      interpretation = '🔴 Penurunan Sedang-Berat – CKD G3b';
      severity = CalcSeverity.danger;
    } else if (eGFR >= 15) {
      interpretation = '🔴 Penurunan Berat – CKD G4';
      severity = CalcSeverity.danger;
    } else {
      interpretation = '🔴 Gagal Ginjal – CKD G5';
      severity = CalcSeverity.danger;
    }

    return CalculationResult(
      moduleName: 'Ginjal & Obat',
      label: 'eGFR (CKD-EPI 2021)',
      value: eGFR.toStringAsFixed(1),
      unit: 'mL/mnt/1.73m²',
      interpretation: interpretation,
      severity: severity,
      steps: [
        'Rumus: CKD-EPI 2021',
        'Kreatinin serum: $serumCreatinine mg/dL',
        'Usia: $ageyears tahun, ${isFemale ? "Perempuan" : "Laki-laki"}',
        'eGFR = ${eGFR.toStringAsFixed(1)} mL/mnt/1.73m²',
        'Referensi: ≥60 = fungsi ginjal cukup (KDIGO)',
      ],
      sourceLabel: 'KDIGO (CKD-EPI 2021)',
      confidenceLabel: 'High Confidence (Validated)',
      interpretationHint: eGFR >= 90
          ? 'Interpretasi umum: eGFR dalam batas normal (KDIGO CKD-EPI 2021). Fungsi filtrasi ginjal baik.'
          : eGFR >= 60
              ? 'Interpretasi umum: Penurunan ringan. Pertimbangkan pemantauan lanjut sesuai pedoman klinis.'
              : eGFR >= 30
                  ? 'Interpretasi umum: Penurunan sedang. Pertimbangkan evaluasi komorbid dan obat-obatan nefrotoksik.'
                  : 'Interpretasi umum: Penurunan berat. Evaluasi klinis menyeluruh sangat dianjurkan.',
    );
  }
}
