import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/emergency_logic.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';

class EmergencyModuleView extends ConsumerStatefulWidget {
  const EmergencyModuleView({super.key});
  @override
  ConsumerState<EmergencyModuleView> createState() => _EmergencyState();
}

class _EmergencyState extends ConsumerState<EmergencyModuleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // GCS
  int _gcsE = 4, _gcsV = 5, _gcsM = 6;
  CalculationResult? _gcsResult;

  // APGAR
  int _apA = 2, _apP = 2, _apG = 2, _apAc = 2, _apR = 2;
  int _apMinute = 1;
  CalculationResult? _apgarResult;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _calcGCS();
    _calcAPGAR();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _calcGCS() => setState(() {
    _gcsResult = EmergencyLogic.calcGCS(eye: _gcsE, verbal: _gcsV, motor: _gcsM);
  });

  void _calcAPGAR() => setState(() {
    _apgarResult = EmergencyLogic.calcAPGAR(
      appearance: _apA, pulse: _apP, grimace: _apG,
      activity: _apAc, respiration: _apR, minuteAfterBirth: _apMinute,
    );
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB71C1C);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Score'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'GCS'),
            Tab(text: 'APGAR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_gcsTab(accent), _apgarTab(accent)],
      ),
    );
  }

  Widget _gcsTab(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scoreRow('E – Eye Opening', _gcsE, 1, 4,
              ['Tidak ada', 'Nyeri', 'Suara', 'Spontan'],
              (v) => setState(() { _gcsE = v; _calcGCS(); }), accent),
          const SizedBox(height: 12),
          _scoreRow('V – Verbal', _gcsV, 1, 5,
              ['Tidak ada', 'Suara', 'Kata', 'Bingung', 'Orientasi'],
              (v) => setState(() { _gcsV = v; _calcGCS(); }), accent),
          const SizedBox(height: 12),
          _scoreRow('M – Motor', _gcsM, 1, 6,
              ['Tidak ada', 'Ekstensi', 'Fleksi abn', 'Fleksi normal', 'Lokalisasi', 'Ikuti Perintah'],
              (v) => setState(() { _gcsM = v; _calcGCS(); }), accent),
          const SizedBox(height: 24),
          if (_gcsResult != null) CalcResultCard(result: _gcsResult!),
        ],
      ),
    );
  }

  Widget _apgarTab(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _apgarRow('A – Appearance (Warna)', _apA, (v) => setState(() { _apA = v; _calcAPGAR(); }), accent),
          _apgarRow('P – Pulse (Nadi)', _apP, (v) => setState(() { _apP = v; _calcAPGAR(); }), accent),
          _apgarRow('G – Grimace (Refleks)', _apG, (v) => setState(() { _apG = v; _calcAPGAR(); }), accent),
          _apgarRow('A – Activity (Tonus)', _apAc, (v) => setState(() { _apAc = v; _calcAPGAR(); }), accent),
          _apgarRow('R – Respiration (Nafas)', _apR, (v) => setState(() { _apR = v; _calcAPGAR(); }), accent),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Menit ke:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              ChoiceChip(label: const Text('1'), selected: _apMinute == 1,
                onSelected: (_) => setState(() { _apMinute = 1; _calcAPGAR(); })),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('5'), selected: _apMinute == 5,
                onSelected: (_) => setState(() { _apMinute = 5; _calcAPGAR(); })),
            ],
          ),
          const SizedBox(height: 24),
          if (_apgarResult != null) CalcResultCard(result: _apgarResult!),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int value, int min, int max,
      List<String> labels, ValueChanged<int> onChanged, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
              child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: accent,
          label: labels[value - min],
          onChanged: (v) => onChanged(v.toInt()),
        ),
        Text(labels[value - min],
            style: TextStyle(color: accent, fontSize: 12, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _apgarRow(String label, int value, ValueChanged<int> onChanged, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: value == i ? accent : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('$i',
                    style: TextStyle(
                      color: value == i ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ))),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
