import 'package:flutter/material.dart';
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
  
  bool _isPregnant = false;
  bool _hasKidneyIssue = false;
  bool _hasLiverIssue = false;
  
  String _result = '';
  String _formulaDetail = '';
  List<String> _warnings = [];

  double _calculateBSA() {
    final w = double.tryParse(_weightController.text) ?? 0;
    final h = double.tryParse(_heightController.text) ?? 0;
    if (w <= 0 || h <= 0) return 0;
    // Mosteller Formula: sqrt( (h * w) / 3600 )
    return math.sqrt((h * w) / 3600);
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final age = int.tryParse(_ageController.text) ?? 30; // Default adult if empty
    
    if (weight <= 0) {
      setState(() => _result = 'Masukkan berat badan');
      return;
    }

    _warnings = [];
    
    // Clinical Pinnacle: Age-Guard
    if (age < 12 && (widget.detail.dosisAnak == '-' || widget.detail.dosisAnak == null)) {
      _warnings.add('🚨 AGE-GUARD: Obat ini terindikasi khusus DEWASA. Gunakan dengan sangat hati-hati pada anak.');
    }

    // Advanced range calculation logic
    double? minDosePerKg;
    double? maxDosePerKg;
    double? dosePerM2;
    
    final doseAnak = widget.detail.dosisAnak ?? '';
    final doseDewasa = widget.detail.dosisDewasa ?? '';
    
    // Regex for mg/kg
    final rangeMatch = RegExp(r'(\d+\.?\d*)\s*-\s*(\d+\.?\d*)').firstMatch(doseAnak);
    final singleMatch = RegExp(r'(\d+\.?\d*)\s*mg/kg').firstMatch(doseAnak);
    
    // Regex for mg/m2 (Specialist BSA)
    final bsaMatch = RegExp(r'(\d+\.?\d*)\s*mg/m2').firstMatch(doseAnak);

    // Regex for Adult Max Dose extraction (Safety Buffer)
    double adultMax = 999999;
    final adultMaxMatch = RegExp(r'Max:\s*(\d+\.?\d*)').firstMatch(doseDewasa) ?? 
                          RegExp(r'(\d+\.?\d*)\s*mg').firstMatch(doseDewasa);
    if (adultMaxMatch != null) {
      adultMax = double.tryParse(adultMaxMatch.group(1)!) ?? adultMax;
    }

    double finalMin = 0;
    double finalMax = 0;

    if (bsaMatch != null) {
      dosePerM2 = double.tryParse(bsaMatch.group(1)!);
      final bsa = _calculateBSA();
      if (bsa > 0 && dosePerM2 != null) {
        finalMin = bsa * dosePerM2;
        finalMax = finalMin;
        _formulaDetail = 'Rumus: BSA (${bsa.toStringAsFixed(2)} m²) × $dosePerM2 mg/m²';
      }
    } else if (rangeMatch != null) {
      minDosePerKg = double.tryParse(rangeMatch.group(1)!);
      maxDosePerKg = double.tryParse(rangeMatch.group(2)!);
      if (minDosePerKg != null && maxDosePerKg != null) {
        finalMin = weight * minDosePerKg;
        finalMax = weight * maxDosePerKg;
        _formulaDetail = 'Rumus: BB ($weight kg) × ($minDosePerKg-$maxDosePerKg) mg/kg';
      }
    } else if (singleMatch != null) {
      minDosePerKg = double.tryParse(singleMatch.group(1)!);
      if (minDosePerKg != null) {
        finalMin = weight * minDosePerKg;
        finalMax = finalMin;
        _formulaDetail = 'Rumus: BB ($weight kg) × $minDosePerKg mg/kg';
      }
    }

    // Safety Buffer: Check against Adult Max
    bool capped = false;
    if (finalMin > adultMax) { finalMin = adultMax; capped = true; }
    if (finalMax > adultMax) { finalMax = adultMax; capped = true; }
    
    if (capped) {
      _warnings.add('🛡️ SAFETY BUFFER: Dosis disesuaikan agar tidak melebihi Dosis Maksimum Dewasa ($adultMax mg).');
    }

    // Renal/Hepatic Adjustment
    if (_hasKidneyIssue && widget.detail.penyesuaianGinjal != '-') {
      _warnings.add('🧬 RENAL GUARD: ${widget.detail.penyesuaianGinjal}');
    }

    setState(() {
      if (finalMin <= 0) {
        _result = 'Manual';
      } else if (finalMin == finalMax) {
        _result = '${finalMin.toStringAsFixed(1)} ${widget.detail.satuan ?? 'mg'}';
      } else {
        _result = '${finalMin.toStringAsFixed(1)} - ${finalMax.toStringAsFixed(1)} ${widget.detail.satuan ?? 'mg'}';
      }
      
      if (_allergyController.text.isNotEmpty) {
        _warnings.add('⚠️ ALERGI: Pasien sensitif terhadap ${_allergyController.text}.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Dosis Klinis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicineHeader(),
            const SizedBox(height: 24),
            _buildInputSection(),
            const SizedBox(height: 24),
            _buildConditionsSection(),
            const SizedBox(height: 32),
            _buildResultPanel(),
            if (_warnings.isNotEmpty) _buildWarningSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.medicine.namaGenerik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(widget.detail.kelasTerapi ?? '-', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(4)),
            child: Text('CAT: ${widget.detail.kategoriKehamilan ?? "?"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(_weightController, 'Berat (kg)', Icons.monitor_weight),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_heightController, 'Tinggi (cm)', Icons.height),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_ageController, 'Umur (thn)', Icons.calendar_today),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_allergyController, 'Alergi', Icons.warning_amber),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
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
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildResultPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('ESTIMASI DOSIS KLINIS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(_result, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(widget.detail.frekuensi ?? '-', style: const TextStyle(color: Colors.white60, fontSize: 14)),
          if (_formulaDetail.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            Text(_formulaDetail, style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('SAFETY GUARD ANALYTICS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.redAccent)),
        const SizedBox(height: 12),
        ..._warnings.map((w) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
          child: Row(
            children: [
              const Icon(Icons.shield, color: Colors.redAccent, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(w, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
        )),
      ],
    );
  }
}
