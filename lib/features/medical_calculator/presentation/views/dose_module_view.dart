import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/dose_logic.dart';
import '../../domain/logic/medical_validator.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_input_field.dart';

class DoseCalcModuleView extends ConsumerStatefulWidget {
  const DoseCalcModuleView({super.key});

  @override
  ConsumerState<DoseCalcModuleView> createState() => _DoseCalcModuleViewState();
}

class _DoseCalcModuleViewState extends ConsumerState<DoseCalcModuleView> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController(text: '');
  final _doseCtrl = TextEditingController(text: '');
  final _maxDoseCtrl = TextEditingController(text: '');
  final _tabletCtrl = TextEditingController(text: '');
  final _concCtrl = TextEditingController(text: '');
  final _drugCtrl = TextEditingController(text: 'Obat');

  final _wFocus = FocusNode();
  final _dFocus = FocusNode();
  final _mFocus = FocusNode();

  CalculationResult? _result;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = DoseLogic.calculate(
        weightKg: double.parse(_weightCtrl.text),
        dosePerKg: double.parse(_doseCtrl.text),
        maxDoseMg: _maxDoseCtrl.text.isNotEmpty
            ? double.tryParse(_maxDoseCtrl.text)
            : null,
        drugName: _drugCtrl.text.isEmpty ? 'Obat' : _drugCtrl.text,
        tabletStrength: _tabletCtrl.text.isNotEmpty
            ? double.tryParse(_tabletCtrl.text)
            : null,
        concentration: _concCtrl.text.isNotEmpty
            ? double.tryParse(_concCtrl.text)
            : null,
      );
    });
  }

  @override
  void dispose() {
    for (final c in [_weightCtrl, _doseCtrl, _maxDoseCtrl, _tabletCtrl, _concCtrl, _drugCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Dosis Obat'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('DATA PASIEN & OBAT'),
              const SizedBox(height: 12),
              CalcInputField(
                controller: _drugCtrl,
                label: 'Nama Obat',
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.medication),
                nextFocusNode: _wFocus,
                onChanged: _calculate,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CalcInputField(
                      controller: _weightCtrl,
                      label: 'Berat Badan',
                      unit: 'kg',
                      focusNode: _wFocus,
                      nextFocusNode: _dFocus,
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      validator: MedicalValidator.weight,
                      onChanged: _calculate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CalcInputField(
                      controller: _doseCtrl,
                      label: 'Dosis',
                      unit: 'mg/kgBB',
                      defaultValue: '10',
                      focusNode: _dFocus,
                      nextFocusNode: _mFocus,
                      prefixIcon: const Icon(Icons.colorize),
                      validator: MedicalValidator.dose,
                      onChanged: _calculate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CalcInputField(
                controller: _maxDoseCtrl,
                label: 'Dosis Maksimal (opsional)',
                unit: 'mg',
                focusNode: _mFocus,
                prefixIcon: const Icon(Icons.block, color: Colors.red),
                validator: (v) => v == null || v.isEmpty ? null : MedicalValidator.dose(v),
                onChanged: _calculate,
              ),
              const SizedBox(height: 20),
              _sectionLabel('KONVERSI SEDIAAN (OPSIONAL)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CalcInputField(
                      controller: _tabletCtrl,
                      label: 'Kekuatan Tablet',
                      unit: 'mg/tab',
                      prefixIcon: const Icon(Icons.tablet),
                      onChanged: _calculate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CalcInputField(
                      controller: _concCtrl,
                      label: 'Konsentrasi Cair',
                      unit: 'mg/mL',
                      prefixIcon: const Icon(Icons.water_drop),
                      onChanged: _calculate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.calculate),
                  label: const Text('HITUNG DOSIS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _calculate,
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                CalcResultCard(result: _result!),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Color(0xFF1565C0),
        ),
      );
}
