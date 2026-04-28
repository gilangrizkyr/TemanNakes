import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calc_history_provider.dart';
import '../../domain/models/calc_result.dart';
import 'dose_module_view.dart';
import 'infus_module_view.dart';
import 'patient_status_module_view.dart';
import 'obstetric_module_view.dart';
import 'emergency_module_view.dart';
import 'renal_module_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temannakes/core/services/ad_service.dart';

class MedicalCalcHome extends ConsumerStatefulWidget {
  const MedicalCalcHome({super.key});

  @override
  ConsumerState<MedicalCalcHome> createState() => _MedicalCalcHomeState();
}

class _MedicalCalcHomeState extends ConsumerState<MedicalCalcHome> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() async {
    final isOnline = await AdService().isOnline();
    if (!isOnline) return;

    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() => _isBannerLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('BannerAd failed: $error');
        if (!mounted) return;
        setState(() => _isBannerLoaded = false);
      },
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  static const List<_ModuleCard> _modules = [
    _ModuleCard(
      title: 'Dosis Obat',
      subtitle: 'mg/kgBB, konversi\ntablet & sirup',
      icon: Icons.medication,
      color: Color(0xFF1565C0),
    ),
    _ModuleCard(
      title: 'Infus',
      subtitle: 'Tetes/menit &\npump mL/jam',
      icon: Icons.water_drop,
      color: Color(0xFF00695C),
    ),
    _ModuleCard(
      title: 'Status Pasien',
      subtitle: 'BMI, MAP &\nShock Index',
      icon: Icons.monitor_heart,
      color: Color(0xFF6A1B9A),
    ),
    _ModuleCard(
      title: 'Kebidanan',
      subtitle: 'HPL, Usia Hamil\n& TBJ',
      icon: Icons.pregnant_woman,
      color: Color(0xFFAD1457),
    ),
    _ModuleCard(
      title: 'Emergency',
      subtitle: 'GCS &\nAPGAR Score',
      icon: Icons.emergency,
      color: Color(0xFFB71C1C),
    ),
    _ModuleCard(
      title: 'Ginjal & Obat',
      subtitle: 'CrCl &\neGFR (CKD-EPI)',
      icon: Icons.science,
      color: Color(0xFF0277BD),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(calcHistoryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kalkulator Medis Nakes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('6 Modul Klinis Terintegrasi',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Riwayat',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _HistoryView()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFF8E1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alat bantu pengambilan keputusan. Bukan pengganti keputusan klinis tenaga kesehatan.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFF57F17),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Module grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemCount: _modules.length,
                itemBuilder: (ctx, i) => _buildModuleCard(ctx, i),
              ),
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, int index) {
    final m = _modules[index];
    return GestureDetector(
      onTap: () => _navigateTo(context, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: m.color.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: m.color.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(m.icon, color: m.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              m.title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: m.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              m.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    final views = <Widget>[
      const DoseCalcModuleView(),
      const InfusModuleView(),
      const PatientStatusModuleView(),
      const ObstetricModuleView(),
      const EmergencyModuleView(),
      const RenalModuleView(),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (_) => views[index]));
  }
}

class _ModuleCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _HistoryView extends ConsumerWidget {
  const _HistoryView();

  Color _severityColor(CalcSeverity s) => switch (s) {
        CalcSeverity.normal => const Color(0xFF2E7D32),
        CalcSeverity.warning => const Color(0xFFF57F17),
        CalcSeverity.danger => const Color(0xFFC62828),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(calcHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Perhitungan'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => ref.read(calcHistoryProvider.notifier).clear(),
            child: const Text('Hapus', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada riwayat', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (ctx, i) {
                final r = history[i];
                final color = _severityColor(r.severity);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.moduleName,
                                style: TextStyle(color: color, fontSize: 10,
                                    fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            Text('${r.label}: ${r.value} ${r.unit}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(r.interpretation,
                                style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
