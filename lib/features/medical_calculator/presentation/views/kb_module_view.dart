import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/kb_logic.dart';
import '../../domain/models/calc_result.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_banner_ad_widget.dart';
import '../../../../../core/services/notification_service.dart';

class KbModuleView extends ConsumerStatefulWidget {
  const KbModuleView({super.key});

  @override
  ConsumerState<KbModuleView> createState() => _KbModuleState();
}

class _KbModuleState extends ConsumerState<KbModuleView> {
  DateTime? _lastInjection;
  int _kbType = 3; // Default to 3 months (most common)
  CalculationResult? _result;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.onFeatureUsed('kb_calculator');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Suntik Terakhir',
    );
    if (picked != null) {
      setState(() {
        _lastInjection = picked;
        _calculate();
      });
    }
  }

  void _calculate() {
    if (_lastInjection == null) return;
    setState(() {
      _result = KbLogic.calcKbInjection(
        lastInjection: _lastInjection!,
        type: _kbType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE65100); // Deep Orange for KB
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator KB'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipe Kontrasepsi Suntik',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(3, '3 Bulan', 'Setiap 12 Minggu', accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(1, '1 Bulan', 'Setiap 4 Minggu', accentColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Data Kunjungan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                  color: accentColor.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tanggal Suntik Terakhir',
                              style: TextStyle(color: accentColor.withOpacity(0.7), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _lastInjection != null
                                ? '${_lastInjection!.day.toString().padLeft(2, '0')}-${_lastInjection!.month.toString().padLeft(2, '0')}-${_lastInjection!.year}'
                                : 'Ketuk untuk memilih tanggal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _lastInjection != null ? accentColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: accentColor),
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              CalcResultCard(result: _result!),
              const SizedBox(height: 16),
              const CalcBannerAdWidget(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(int type, String title, String subtitle, Color color) {
    final selected = _kbType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _kbType = type;
          _calculate();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
