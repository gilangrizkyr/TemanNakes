import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/patient_status_logic.dart';
import '../../domain/logic/medical_validator.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_input_field.dart';

class PatientStatusModuleView extends ConsumerStatefulWidget {
  const PatientStatusModuleView({super.key});
  @override
  ConsumerState<PatientStatusModuleView> createState() => _PatientStatusState();
}

class _PatientStatusState extends ConsumerState<PatientStatusModuleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // BMI
  final _wBMI = TextEditingController();
  final _hBMI = TextEditingController();
  CalculationResult? _bmiResult;

  // MAP
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  CalculationResult? _mapResult;

  // Shock Index
  final _hr = TextEditingController();
  final _sSI = TextEditingController();
  CalculationResult? _siResult;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [_wBMI, _hBMI, _sys, _dia, _hr, _sSI]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pasien'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'BMI'),
            Tab(text: 'MAP'),
            Tab(text: 'Shock Index'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_bmiTab(), _mapTab(), _shockTab()],
      ),
    );
  }

  Widget _bmiTab() => _calcPage(
    children: [
      Row(children: [
        Expanded(child: CalcInputField(controller: _wBMI, label: 'Berat Badan', unit: 'kg',
          prefixIcon: const Icon(Icons.monitor_weight_outlined),
          validator: MedicalValidator.weight, onChanged: _calcBMI)),
        const SizedBox(width: 12),
        Expanded(child: CalcInputField(controller: _hBMI, label: 'Tinggi Badan', unit: 'cm',
          prefixIcon: const Icon(Icons.height),
          validator: MedicalValidator.height, onChanged: _calcBMI)),
      ]),
      _button('HITUNG BMI', const Color(0xFF6A1B9A), _calcBMI),
      if (_bmiResult != null) CalcResultCard(result: _bmiResult!),
    ],
  );

  Widget _mapTab() => _calcPage(
    children: [
      Row(children: [
        Expanded(child: CalcInputField(controller: _sys, label: 'Sistolik', unit: 'mmHg',
          prefixIcon: const Icon(Icons.arrow_upward),
          validator: (v) => MedicalValidator.bloodPressure(v, 'Sistolik'), onChanged: _calcMAP)),
        const SizedBox(width: 12),
        Expanded(child: CalcInputField(controller: _dia, label: 'Diastolik', unit: 'mmHg',
          prefixIcon: const Icon(Icons.arrow_downward),
          validator: (v) => MedicalValidator.bloodPressure(v, 'Diastolik'), onChanged: _calcMAP)),
      ]),
      _button('HITUNG MAP', const Color(0xFF6A1B9A), _calcMAP),
      if (_mapResult != null) CalcResultCard(result: _mapResult!),
    ],
  );

  Widget _shockTab() => _calcPage(
    children: [
      Row(children: [
        Expanded(child: CalcInputField(controller: _hr, label: 'Nadi (HR)', unit: 'bpm',
          prefixIcon: const Icon(Icons.favorite),
          validator: (v) => MedicalValidator.positiveNumber(v, 'Nadi', max: 300), onChanged: _calcSI)),
        const SizedBox(width: 12),
        Expanded(child: CalcInputField(controller: _sSI, label: 'TD Sistolik', unit: 'mmHg',
          prefixIcon: const Icon(Icons.arrow_upward),
          validator: (v) => MedicalValidator.bloodPressure(v, 'Sistolik'), onChanged: _calcSI)),
      ]),
      _button('HITUNG SHOCK INDEX', const Color(0xFF6A1B9A), _calcSI),
      if (_siResult != null) CalcResultCard(result: _siResult!),
    ],
  );

  void _calcBMI() {
    final w = double.tryParse(_wBMI.text);
    final h = double.tryParse(_hBMI.text);
    if (w == null || h == null || w <= 0 || h <= 0) return;
    setState(() { _bmiResult = PatientStatusLogic.calcBMI(weightKg: w, heightCm: h); });
  }

  void _calcMAP() {
    final s = double.tryParse(_sys.text);
    final d = double.tryParse(_dia.text);
    if (s == null || d == null) return;
    setState(() { _mapResult = PatientStatusLogic.calcMAP(systolic: s, diastolic: d); });
  }

  void _calcSI() {
    final h = double.tryParse(_hr.text);
    final s = double.tryParse(_sSI.text);
    if (h == null || s == null || s <= 0) return;
    setState(() { _siResult = PatientStatusLogic.calcShockIndex(heartRate: h, systolic: s); });
  }

  Widget _calcPage({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 16), child: w)).toList(),
      ),
    );
  }

  Widget _button(String label, Color color, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      icon: const Icon(Icons.calculate),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    ),
  );
}
