import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _ageController = TextEditingController();
  final _allergyController = TextEditingController();
  
  bool _isPregnant = false;
  bool _hasKidneyIssue = false;
  bool _hasLiverIssue = false;
  
  String _result = '';
  List<String> _warnings = [];

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (weight <= 0) {
      setState(() => _result = 'Masukkan berat badan valid');
      return;
    }

    // Advanced range calculation logic
    double? minDosePerKg;
    double? maxDosePerKg;
    
    final doseAnak = widget.detail.dosisAnak ?? '';
    // Regex to find decimal ranges like "0.5-1.5" or single "0.2"
    final rangeMatch = RegExp(r'(\d+\.?\d*)\s*-\s*(\d+\.?\d*)').firstMatch(doseAnak);
    final singleMatch = RegExp(r'(\d+\.?\d*)\s*mg/kg').firstMatch(doseAnak);

    if (rangeMatch != null) {
      minDosePerKg = double.tryParse(rangeMatch.group(1)!);
      maxDosePerKg = double.tryParse(rangeMatch.group(2)!);
    } else if (singleMatch != null) {
      minDosePerKg = double.tryParse(singleMatch.group(1)!);
      maxDosePerKg = minDosePerKg;
    }

    if (minDosePerKg == null || maxDosePerKg == null) {
      setState(() => _result = 'Dosis otomatis tidak tersedia.\nLihat referensi teks di atas.');
      return;
    }

    final minDose = weight * minDosePerKg;
    final maxDose = weight * maxDosePerKg;
    
    setState(() {
      if (minDose == maxDose) {
        _result = '${minDose.toStringAsFixed(2)} ${widget.detail.satuan ?? 'mg'}';
      } else {
        _result = '${minDose.toStringAsFixed(2)} - ${maxDose.toStringAsFixed(2)} ${widget.detail.satuan ?? 'mg'}';
      }
      
      _warnings = [];
      
      if (_allergyController.text.isNotEmpty) {
        _warnings.add('⚠️ ALERT ALERGI: Pasien alergi terhadap ${_allergyController.text}.');
      }
      if (_isPregnant) _warnings.add('⚠️ Kontraindikasi: Hati-hati penggunaan pada ibu hamil.');
      if (_hasKidneyIssue) _warnings.add('⚠️ Dosis mungkin perlu disesuaikan untuk gangguan ginjal.');
      if (_hasLiverIssue) _warnings.add('⚠️ Peringatan: Obat ini dimetabolisme di hati.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Dosis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.medicine.namaGenerik,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Berat Badan (kg)',
                prefixIcon: const Icon(Icons.monitor_weight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Umur (tahun)',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _allergyController,
              decoration: InputDecoration(
                labelText: 'Alergi Pasien',
                hintText: 'Misal: Penisilin, Debu, dll',
                prefixIcon: const Icon(Icons.warning_amber),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.red.shade50.withOpacity(0.3),
              ),
              onChanged: (_) => _calculate(),
            ),
            
            const SizedBox(height: 24),
            const Text('Kondisi Pasien:', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('Hamil'),
              value: _isPregnant,
              onChanged: (val) => setState(() { _isPregnant = val!; _calculate(); }),
            ),
            CheckboxListTile(
              title: const Text('Gangguan Ginjal'),
              value: _hasKidneyIssue,
              onChanged: (val) => setState(() { _hasKidneyIssue = val!; _calculate(); }),
            ),
            CheckboxListTile(
              title: const Text('Gangguan Hati'),
              value: _hasLiverIssue,
              onChanged: (val) => setState(() { _hasLiverIssue = val!; _calculate(); }),
            ),
            
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Text('DOSIS ESTIMASI:', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    _result.isEmpty ? '-' : _result,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  Text(widget.detail.frekuensi ?? ''),
                ],
              ),
            ),
            
            if (_warnings.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('PERINGATAN CLINICAL:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.red, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              ..._warnings.map((w) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              )),
            ]
          ],
        ),
      ),
    );
  }
}
