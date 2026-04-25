import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/infus_logic.dart';
import '../../domain/logic/medical_validator.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_input_field.dart';

class InfusModuleView extends ConsumerStatefulWidget {
  const InfusModuleView({super.key});

  @override
  ConsumerState<InfusModuleView> createState() => _InfusModuleViewState();
}

class _InfusModuleViewState extends ConsumerState<InfusModuleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _formKeyDrop = GlobalKey<FormState>();
  final _formKeyPump = GlobalKey<FormState>();

  // Tetesan
  final _volDropCtrl = TextEditingController();
  final _durDropCtrl = TextEditingController();
  int _dropFactor = 20;

  // Pump
  final _volPumpCtrl = TextEditingController();
  final _durPumpCtrl = TextEditingController();

  CalculationResult? _resultDrop;
  CalculationResult? _resultPump;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [_volDropCtrl, _durDropCtrl, _volPumpCtrl, _durPumpCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calcDrop() {
    if (!_formKeyDrop.currentState!.validate()) return;
    setState(() {
      _resultDrop = InfusLogic.calcDropRate(
        volumeMl: double.parse(_volDropCtrl.text),
        durationMinutes: double.parse(_durDropCtrl.text),
        dropFactor: _dropFactor,
      );
    });
  }

  void _calcPump() {
    if (!_formKeyPump.currentState!.validate()) return;
    setState(() {
      _resultPump = InfusLogic.calcPumpRate(
        volumeMl: double.parse(_volPumpCtrl.text),
        durationHours: double.parse(_durPumpCtrl.text),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Infus'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tetes/Menit', icon: Icon(Icons.water_drop, size: 18)),
            Tab(text: 'Pump mL/jam', icon: Icon(Icons.speed, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDropTab(),
          _buildPumpTab(),
        ],
      ),
    );
  }

  Widget _buildDropTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeyDrop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: CalcInputField(
                  controller: _volDropCtrl,
                  label: 'Volume Infus',
                  unit: 'mL',
                  defaultValue: '500',
                  prefixIcon: const Icon(Icons.local_drink),
                  validator: (v) => MedicalValidator.volume(v, 'Volume'),
                  onChanged: _calcDrop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalcInputField(
                  controller: _durDropCtrl,
                  label: 'Durasi',
                  unit: 'menit',
                  defaultValue: '480',
                  prefixIcon: const Icon(Icons.timer),
                  validator: (v) => MedicalValidator.positiveNumber(v, 'Durasi', max: 10000),
                  onChanged: _calcDrop,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('Faktor Tetes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _dropChip(20, 'Makro (20)'),
                const SizedBox(width: 8),
                _dropChip(60, 'Mikro (60)'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('HITUNG TETESAN'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _calcDrop,
              ),
            ),
            if (_resultDrop != null) ...[
              const SizedBox(height: 24),
              CalcResultCard(result: _resultDrop!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPumpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeyPump,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: CalcInputField(
                  controller: _volPumpCtrl,
                  label: 'Volume Infus',
                  unit: 'mL',
                  defaultValue: '500',
                  prefixIcon: const Icon(Icons.local_drink),
                  validator: (v) => MedicalValidator.volume(v, 'Volume'),
                  onChanged: _calcPump,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalcInputField(
                  controller: _durPumpCtrl,
                  label: 'Durasi',
                  unit: 'jam',
                  defaultValue: '8',
                  prefixIcon: const Icon(Icons.timer),
                  validator: (v) => MedicalValidator.positiveNumber(v, 'Durasi', max: 72),
                  onChanged: _calcPump,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.speed),
                label: const Text('HITUNG KECEPATAN PUMP'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _calcPump,
              ),
            ),
            if (_resultPump != null) ...[
              const SizedBox(height: 24),
              CalcResultCard(result: _resultPump!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropChip(int value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _dropFactor == value,
      onSelected: (_) => setState(() { _dropFactor = value; _calcDrop(); }),
      selectedColor: const Color(0xFF00695C).withOpacity(0.2),
      checkmarkColor: const Color(0xFF00695C),
    );
  }
}
