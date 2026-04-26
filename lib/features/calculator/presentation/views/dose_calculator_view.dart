import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../medicine/domain/models/medicine.dart';

class DoseCalculatorView extends StatefulWidget {
  final MedicineSimple medicine;
  final MedicineDetail detail;

  const DoseCalculatorView({
    super.key,
    required this.medicine,
    required this.detail,
  });

  @override
  State<DoseCalculatorView> createState() => _DoseCalculatorViewState();
}

class _DoseCalculatorViewState extends State<DoseCalculatorView> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController(); // New for BSA
  final _ageController = TextEditingController();
  final _allergyController = TextEditingController();
  
  final _concentrationMgController = TextEditingController();
  final _concentrationMlController = TextEditingController();
  
  bool _isPregnant = false;
  bool _hasKidneyIssue = false;
  bool _hasLiverIssue = false;
  
  String _result = '';
  String _formulaDetail = '';
  String _volumeResult = '';
  List<String> _warnings = [];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _allergyController.dispose();
    _concentrationMgController.dispose();
    _concentrationMlController.dispose();
    super.dispose();
  }

  double _calculateBSA() {
    final w = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    final h = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0;
    if (w <= 0 || h <= 0) return 0;
    return math.sqrt((h * w) / 3600);
  }

  Map<String, double> _parseFrequencyRange(String? freq) {
    if (freq == null || freq.isEmpty) return {'min': 1, 'max': 1};
    final f = freq.toLowerCase();
    
    final matchXRange = RegExp(r'(\d+)-(\d+)\s*x').firstMatch(f);
    if (matchXRange != null) {
      return {
        'min': math.max(1.0, double.tryParse(matchXRange.group(1)!) ?? 1),
        'max': math.max(1.0, double.tryParse(matchXRange.group(2)!) ?? 1),
      };
    }

    final matchX = RegExp(r'(\d+)\s*x').firstMatch(f);
    if (matchX != null) {
      final val = math.max(1.0, double.tryParse(matchX.group(1)!) ?? 1);
      return {'min': val, 'max': val};
    }

    final matchJamRange = RegExp(r'tiap\s*(\d+)-(\d+)\s*jam').firstMatch(f);
    if (matchJamRange != null) {
      final h1 = double.tryParse(matchJamRange.group(1)!) ?? 8;
      final h2 = double.tryParse(matchJamRange.group(2)!) ?? 6;
      final f1 = 24 / (h1 > 0 ? h1 : 8);
      final f2 = 24 / (h2 > 0 ? h2 : 6);
      return {
        'min': math.min(f1, f2),
        'max': math.max(f1, f2),
      };
    }
    
    if (f.contains('tiap 8 jam')) return {'min': 3, 'max': 3};
    if (f.contains('tiap 12 jam')) return {'min': 2, 'max': 2};
    if (f.contains('tiap 6 jam')) return {'min': 4, 'max': 4};
    if (f.contains('tiap 4 jam')) return {'min': 6, 'max': 6};
    
    return {'min': 1, 'max': 1};
  }

  void _calculate() {
    final weightStr = _weightController.text.replaceAll(',', '.');
    final weight = double.tryParse(weightStr) ?? 0;
    final ageStr = _ageController.text.replaceAll(',', '.');
    final age = double.tryParse(ageStr) ?? 30; // Default adult if empty
    
    if (weight <= 0) {
      setState(() => _result = 'Masukkan berat badan');
      return;
    }

    _warnings = [];
    
    // Age-Guard
    if (age < 12 && (widget.detail.dosisAnak == '-' || widget.detail.dosisAnak == null)) {
      _warnings.add('🚨 AGE-GUARD: Obat ini terindikasi khusus DEWASA. Gunakan dengan sangat hati-hati pada anak.');
    }

    double? minDosePerKg;
    double? maxDosePerKg;
    double? fixedDose;
    
    final doseAnak = widget.detail.dosisAnak ?? '';
    final doseDewasa = widget.detail.dosisDewasa ?? '';
    final doseString = (doseAnak.isNotEmpty && doseAnak != '-') ? doseAnak : doseDewasa;

    final normalizedWeight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    
    const u = r'(mg|mcg|ug|IU|unit|units)';
    final rangeKgMatch = RegExp('(\\d+\\.?\\d*)\\s*-\\s*(\\d+\\.?\\d*)\\s*$u/kg', caseSensitive: false).firstMatch(doseString);
    final singleKgMatch = RegExp('(\\d+\\.?\\d*)\\s*$u/kg', caseSensitive: false).firstMatch(doseString);
    final rangeM2Match = RegExp('(\\d+\\.?\\d*)\\s*-\\s*(\\d+\\.?\\d*)\\s*$u/m2', caseSensitive: false).firstMatch(doseString);
    final singleM2Match = RegExp('(\\d+\\.?\\d*)\\s*$u/m2', caseSensitive: false).firstMatch(doseString);
    final rangeFixedMatch = RegExp('(\\d+\\.?\\d*)\\s*-\\s*(\\d+\\.?\\d*)\\s*$u(?!\\/k)(?!\\/m)', caseSensitive: false).firstMatch(doseString);
    final fixedMatch = RegExp('(\\d+\\.?\\d*)\\s*$u(?!\\/k)(?!\\/m)', caseSensitive: false).firstMatch(doseString);

    String detectedUnit = widget.detail.satuan ?? 'mg';

    double adultMax = 999999;
    final maxExplicit = RegExp(r'max:\s*(\d+\.?\d*)', caseSensitive: false).firstMatch(doseDewasa);
    if (maxExplicit != null) {
      adultMax = double.tryParse(maxExplicit.group(1)!) ?? adultMax;
    } else {
      final mgMatch = RegExp(r'(\d+\.?\d*)\s*mg(?!\/k)(?!\/m)', caseSensitive: false).firstMatch(doseDewasa);
      if (mgMatch != null) {
        adultMax = double.tryParse(mgMatch.group(1)!) ?? adultMax;
      }
    }
    if (adultMax <= 0) adultMax = 999999;

    double finalMin = 0;
    double finalMax = 0;

    if (rangeM2Match != null) {
      final bsa = _calculateBSA();
      finalMin = (double.tryParse(rangeM2Match.group(1)!) ?? 0) * bsa;
      finalMax = (double.tryParse(rangeM2Match.group(2)!) ?? 0) * bsa;
      detectedUnit = rangeM2Match.group(3)!;
      _formulaDetail = 'Sifat: BSA (m²) × Range $detectedUnit/m²';
    } else if (singleM2Match != null) {
      final bsa = _calculateBSA();
      finalMin = (double.tryParse(singleM2Match.group(1)!) ?? 0) * bsa;
      finalMax = finalMin;
      detectedUnit = singleM2Match.group(2)!;
      _formulaDetail = 'Sifat: BSA (m²) × $detectedUnit/m²';
    } else if (rangeKgMatch != null) {
      minDosePerKg = double.tryParse(rangeKgMatch.group(1)!);
      maxDosePerKg = double.tryParse(rangeKgMatch.group(2)!);
      finalMin = (minDosePerKg ?? 0) * normalizedWeight;
      finalMax = (maxDosePerKg ?? 0) * normalizedWeight;
      detectedUnit = rangeKgMatch.group(3)!;
      _formulaDetail = 'Sifat: BB (kg) × Range $detectedUnit/kg';
    } else if (singleKgMatch != null) {
      minDosePerKg = double.tryParse(singleKgMatch.group(1)!);
      finalMin = (minDosePerKg ?? 0) * normalizedWeight;
      finalMax = finalMin;
      detectedUnit = singleKgMatch.group(2)!;
      _formulaDetail = 'Sifat: BB (kg) × $detectedUnit/kg';
    } else if (rangeFixedMatch != null) {
      finalMin = double.tryParse(rangeFixedMatch.group(1)!) ?? 0;
      finalMax = double.tryParse(rangeFixedMatch.group(2)!) ?? 0;
      detectedUnit = rangeFixedMatch.group(3)!;
      _formulaDetail = 'Sifat: Range Dosis Tetap (Fixed Range)';
    } else if (fixedMatch != null) {
      fixedDose = double.tryParse(fixedMatch.group(1)!);
      finalMin = fixedDose ?? 0;
      finalMax = finalMin;
      detectedUnit = fixedMatch.group(2)!;
      _formulaDetail = 'Sifat: Dosis Tetap (Fixed Dose)';
    }

    bool capped = false;
    if (finalMin > adultMax) { finalMin = adultMax; capped = true; }
    if (finalMax > adultMax) { finalMax = adultMax; capped = true; }
    
    if (capped) {
      _warnings.add('🛡️ SAFETY BUFFER: Dosis disesuaikan agar tidak melebihi Dosis Maksimum Dewasa ($adultMax mg).');
    }

    if (_hasKidneyIssue && widget.detail.penyesuaianGinjal != '-') {
      _warnings.add('🧬 RENAL GUARD: ${widget.detail.penyesuaianGinjal}');
    }

    final doseStringLower = doseString.toLowerCase();
    final isDailySource = doseStringLower.contains('hari') || 
                         doseStringLower.contains('day') || 
                         doseStringLower.contains('24 jam') || 
                         ((minDosePerKg != null && minDosePerKg >= 20) || (maxDosePerKg != null && maxDosePerKg >= 20));

    final freq = _parseFrequencyRange(widget.detail.frekuensi);
    final freqMin = freq['min']!;
    final freqMax = freq['max']!;
    
    double singleMin = 0;
    double singleMax = 0;
    double totalMin = 0;
    double totalMax = 0;

    if (isDailySource) {
      totalMin = finalMin;
      totalMax = finalMax;
      singleMin = totalMin / freqMax; 
      singleMax = totalMax / freqMin; 
      _formulaDetail += '\nStatus: Dosis Harian Total (TDD) → dibagi frekuensi';
    } else {
      singleMin = finalMin;
      singleMax = finalMax;
      totalMin = singleMin * freqMin;
      totalMax = singleMax * freqMax;
      _formulaDetail += '\nStatus: Dosis Sekali (Single Dose) → dikali frekuensi';
    }

    // Volume conversion (ml)
    final concMg = double.tryParse(_concentrationMgController.text.replaceAll(',', '.')) ?? 0;
    final concMl = double.tryParse(_concentrationMlController.text.replaceAll(',', '.')) ?? 0;
    String volumeStr = '';
    if (concMg > 0 && concMl > 0) {
      final volMin = (singleMin / concMg) * concMl;
      final volMax = (singleMax / concMg) * concMl;
      if (volMin == volMax) {
        volumeStr = '${volMin.toStringAsFixed(1)} ml';
      } else {
        volumeStr = '${volMin.toStringAsFixed(1)}-${volMax.toStringAsFixed(1)} ml';
      }
    }

    setState(() {
      final unit = detectedUnit;
      _volumeResult = volumeStr;
      
      // Ultra-Precision logic: 3 decimals for <0.1mg, 2 for <1mg, 1 otherwise
      int precision = 1;
      if (singleMin < 0.1 || singleMax < 0.1) {
        precision = 3;
      } else if (singleMin < 1 || singleMax < 1) {
        precision = 2;
      }

      if (finalMin <= 0) {
        _result = 'Hitung Manual';
        _formulaDetail = 'Data dosis tidak terbaca secara otomatis atau BB belum diisi.';
      } else if (singleMin == singleMax) {
        _result = '${singleMin.toStringAsFixed(precision)} $unit';
      } else {
        _result = '${singleMin.toStringAsFixed(precision)} - ${singleMax.toStringAsFixed(precision)} $unit';
      }

      String tddDisplay = '';
      if (totalMin == totalMax) {
        tddDisplay = '${totalMin.toStringAsFixed(precision)} $unit/hari';
      } else {
        tddDisplay = '${totalMin.toStringAsFixed(precision)}-${totalMax.toStringAsFixed(precision)} $unit/hari';
      }
      _calculationMetadata = tddDisplay;

      if (_allergyController.text.isNotEmpty) {
        _warnings.add('⚠️ ALERGI: Pasien sensitif terhadap "${_allergyController.text}". Pertimbangkan alternatif yang aman.');
      }
      if (_isPregnant) {
        final cat = widget.detail.kategoriKehamilan ?? 'tidak diketahui';
        _warnings.add('🤱 KEHAMILAN: Kategori $cat. Konsultasikan keamanan penggunaan pada ibu hamil.');
      }
      if (_hasLiverIssue) {
        _warnings.add('🟡 GANGGUAN HATI: Hati-hati dengan metabolisme hepatik.');
      }
    });
  }

  String _calculationMetadata = '';

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF2E7D32);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kalkulator Dosis Klinis'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicineHeader(themeColor),
            const SizedBox(height: 24),
            _buildSectionTitle('DATA PASIEN'),
            _buildInputSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('KONDISI KHUSUS'),
            _buildConditionsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('KONVERSI VOLUME (SIRUP/SUSPENSI)'),
            _buildConcentrationSection(themeColor),
            const SizedBox(height: 32),
            _buildResultPanel(themeColor),
            if (_warnings.isNotEmpty) _buildWarningSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildMedicineHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.medicine.namaGenerik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(widget.detail.kelasTerapi ?? '-', style: TextStyle(color: color.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          _buildPillTag('CAT: ${widget.detail.kategoriKehamilan ?? "?"}', color),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildInputSection() {
    final bool isDataMissing = (widget.detail.dosisAnak == '-' || widget.detail.dosisAnak!.isEmpty);
    return Column(
      children: [
        if (isDataMissing) 
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PANDUAN DOSIS TIDAK TERSEDIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                      Text('Silakan masukkan parameter dosis secara manual dari referensi luar.', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(child: _buildTextField(_weightController, 'Berat (kg)', Icons.monitor_weight)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_heightController, 'Tinggi (cm)', Icons.height)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_ageController, 'Umur (thn)', Icons.calendar_today)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_allergyController, 'Alergi', Icons.warning_amber, isNumeric: false)),
          ],
        ),
      ],
    );
  }


  Widget _buildConcentrationSection(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Masukkan kekuatan sediaan obat cair untuk hitung Volume (ml):', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(_concentrationMgController, 'Mg', null, hint: 'Contoh: 125')),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('/', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
              Expanded(child: _buildTextField(_concentrationMlController, 'Per Ml', null, hint: 'Contoh: 5')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? icon, {bool isNumeric = true, String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        fillColor: Colors.white,
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _buildConditionsSection() {
    return Wrap(
      spacing: 8,
      children: [
        _buildChoiceChip('Hamil', _isPregnant, (v) => setState(() { _isPregnant = v; _calculate(); })),
        _buildChoiceChip('Ggn Ginjal', _hasKidneyIssue, (v) => setState(() { _hasKidneyIssue = v; _calculate(); })),
        _buildChoiceChip('Ggn Hati', _hasLiverIssue, (v) => setState(() { _hasLiverIssue = v; _calculate(); })),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool selected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildResultPanel(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('HASIL KALKULASI DOSIS', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          const Text('HASIL DOSIS PER SEKALI BERI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, color: Colors.white30, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'Dosis ${widget.medicine.namaGenerik}: $_result/sekali (Total $_calculationMetadata), Volume: $_volumeResult/sekali'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Hasil disalin ke clipboard'), duration: Duration(seconds: 1)));
                },
              ),
            ],
          ),
          const Text('dosis per satu kali minum/pemberian', style: TextStyle(color: Colors.white70, fontSize: 12)),
          
          if (_volumeResult.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24)),
            const Text('VOLUME CAIRAN', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(_volumeResult, style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('Volume per satu kali minum (ml)', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
          
          const Divider(color: Colors.white24, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResultSub('DOSIS TOTAL 24 JAM', _calculationMetadata),
              _buildResultSub('FREKUENSI', widget.detail.frekuensi ?? '-'),
            ],
          ),
          if (_formulaDetail.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_formulaDetail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic, height: 1.5)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildResultSub(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildWarningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text('SAFETY GUARD ANALYTICS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent, letterSpacing: 1)),
        const SizedBox(height: 16),
        ..._warnings.map((w) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red.shade50.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
          child: Row(
            children: [
              const Icon(Icons.shield, color: Colors.redAccent, size: 20),
              const SizedBox(width: 16),
              Expanded(child: Text(w, style: const TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.w600, fontSize: 14))),
            ],
          ),
        )),
      ],
    );
  }
}
