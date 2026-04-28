import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/obstetric_logic.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_banner_ad_widget.dart';
import '../../../../../core/services/notification_service.dart';

class ObstetricModuleView extends ConsumerStatefulWidget {
  const ObstetricModuleView({super.key});
  @override
  ConsumerState<ObstetricModuleView> createState() => _ObstetricState();
}

class _ObstetricState extends ConsumerState<ObstetricModuleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // HPL & Usia Kehamilan
  DateTime? _hpht;
  CalculationResult? _hplResult;
  CalculationResult? _ageResult;

  // TBJ
  final _tfuCtrl = TextEditingController();
  bool _isEngaged = false;
  CalculationResult? _tbjResult;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // [Behavioral Tracker] — silent, zero friction
    NotificationService.instance.onFeatureUsed('hpl');
    NotificationService.instance.onFeatureUsed('gestational_age');
    NotificationService.instance.onFeatureUsed('tbj');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _tfuCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHPHT() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 84)),
      // Allow up to 2 years ago (appropriate for HPHT clinical range)
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
      helpText: 'Pilih HPHT (Hari Pertama Haid Terakhir)',
    );
    if (picked != null) {
      setState(() {
        _hpht = picked;
        _hplResult = ObstetricLogic.calcHPL(hpht: picked);
        _ageResult = ObstetricLogic.calcGestationalAge(hpht: picked);
      });
    }
  }

  void _calcTBJ() {
    final tfu = double.tryParse(_tfuCtrl.text);
    if (tfu == null || tfu <= 0) return;
    setState(() {
      _tbjResult = ObstetricLogic.calcFetalWeight(
        fundalHeightCm: tfu,
        isEngaged: _isEngaged,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFAD1457);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Kebidanan'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'HPL & Usia Kehamilan'),
            Tab(text: 'Taksiran Berat Janin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _hplTab(accentColor),
          _tbjTab(accentColor),
        ],
      ),
    );
  }

  Widget _hplTab(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HPHT Picker
          GestureDetector(
            onTap: _pickHPHT,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: accent.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
                color: accent.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HPHT (Hari Pertama Haid Terakhir)',
                            style: TextStyle(color: accent.withOpacity(0.7), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _hpht != null
                              ? '${_hpht!.day.toString().padLeft(2, '0')}-${_hpht!.month.toString().padLeft(2, '0')}-${_hpht!.year}'
                              : 'Ketuk untuk memilih tanggal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _hpht != null ? accent : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: accent),
                ],
              ),
            ),
          ),
          if (_hplResult != null) ...[
            const SizedBox(height: 20),
            CalcResultCard(result: _hplResult!),
            const SizedBox(height: 16),
            CalcResultCard(result: _ageResult!),
            const CalcBannerAdWidget(), // [STAGE 2] High-dwell banner
          ],
        ],
      ),
    );
  }

  Widget _tbjTab(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _tfuCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calcTBJ(),
            decoration: InputDecoration(
              labelText: 'Tinggi Fundus Uteri (TFU)',
              suffixText: 'cm',
              prefixIcon: const Icon(Icons.straighten),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Kepala Sudah Masuk Panggul', style: TextStyle(fontSize: 14)),
            subtitle: const Text('n=11 (engaged) / n=12 (belum)', style: TextStyle(fontSize: 11)),
            value: _isEngaged,
            activeColor: accent,
            onChanged: (v) => setState(() { _isEngaged = v; _calcTBJ(); }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.child_care),
              label: const Text('HITUNG TBJ'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _calcTBJ,
            ),
          ),
          if (_tbjResult != null) ...[
            const SizedBox(height: 24),
            CalcResultCard(result: _tbjResult!),
            const CalcBannerAdWidget(), // [STAGE 2] High-dwell banner
          ],
        ],
      ),
    );
  }
}
