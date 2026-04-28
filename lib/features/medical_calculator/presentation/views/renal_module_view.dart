import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/renal_logic.dart';
import '../../domain/logic/medical_validator.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_input_field.dart';
import '../widgets/calc_banner_ad_widget.dart';
import '../../../../../core/services/notification_service.dart';

class RenalModuleView extends ConsumerStatefulWidget {
  const RenalModuleView({super.key});
  @override
  ConsumerState<RenalModuleView> createState() => _RenalState();
}

class _RenalState extends ConsumerState<RenalModuleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _creatCtrl = TextEditingController();
  bool _isFemale = false;

  CalculationResult? _clcrResult;
  CalculationResult? _egfrResult;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // [Behavioral Tracker] — silent, zero friction
    NotificationService.instance.onFeatureUsed('renal_clcr');
    NotificationService.instance.onFeatureUsed('renal_egfr');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [_ageCtrl, _weightCtrl, _creatCtrl]) { c.dispose(); }
    super.dispose();
  }

  void _calculate() {
    final age = double.tryParse(_ageCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    final creat = double.tryParse(_creatCtrl.text);
    if (age == null || weight == null || creat == null) return;
    if (age <= 0 || weight <= 0 || creat <= 0) return;

    setState(() {
      _clcrResult = RenalLogic.calcCreatinineClearance(
        ageyears: age,
        weightKg: weight,
        serumCreatinine: creat,
        isFemale: _isFemale,
      );
      _egfrResult = RenalLogic.calcEGFR(
        serumCreatinine: creat,
        ageyears: age,
        isFemale: _isFemale,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0277BD);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fungsi Ginjal & Obat'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CrCl (Cockcroft-Gault)'),
            Tab(text: 'eGFR (CKD-EPI)'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildTab(accent, 'HITUNG CLCR', _clcrResult),
        _buildTab(accent, 'HITUNG eGFR', _egfrResult),
      ]),
    );
  }

  Widget _buildTab(Color accent, String buttonLabel, CalculationResult? result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: CalcInputField(
                controller: _ageCtrl,
                label: 'Usia',
                unit: 'tahun',
                prefixIcon: const Icon(Icons.person),
                validator: MedicalValidator.age,
                onChanged: _calculate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalcInputField(
                controller: _weightCtrl,
                label: 'Berat Badan',
                unit: 'kg',
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                validator: MedicalValidator.weight,
                onChanged: _calculate,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          CalcInputField(
            controller: _creatCtrl,
            label: 'Kreatinin Serum',
            unit: 'mg/dL',
            defaultValue: '1.0',
            prefixIcon: const Icon(Icons.science_outlined),
            validator: MedicalValidator.creatinine,
            onChanged: _calculate,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Jenis Kelamin Perempuan', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Faktor koreksi 0.85 untuk perempuan'),
            value: _isFemale,
            activeColor: accent,
            onChanged: (v) => setState(() { _isFemale = v; _calculate(); }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.science),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _calculate,
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 24),
            CalcResultCard(result: result),
            const CalcBannerAdWidget(), // [STAGE 2] High-dwell banner
          ],
        ],
      ),
    );
  }
}
