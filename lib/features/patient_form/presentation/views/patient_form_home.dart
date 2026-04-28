import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannakes/core/services/ad_service.dart';
import 'package:temannakes/features/patient_form/presentation/providers/patient_form_provider.dart';
import 'form_builder_view.dart';
import 'patient_list_view.dart';
import 'report_view.dart';

class PatientFormHome extends ConsumerStatefulWidget {
  const PatientFormHome({super.key});

  @override
  ConsumerState<PatientFormHome> createState() => _PatientFormHomeState();
}

class _PatientFormHomeState extends ConsumerState<PatientFormHome> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(formTemplatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form Data Pasien',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Dinamis & Laporan Otomatis',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFE1F5FE),
            child: const Row(
              children: [
                Icon(Icons.cloud_off, color: Color(0xFF0277BD), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Semua data tersimpan di perangkat ini. Berfungsi penuh tanpa internet.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0277BD)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 3 Main Action Cards ────────────────────────────────────
                  _buildActionCard(
                    context,
                    icon: Icons.dynamic_form,
                    iconBg: const Color(0xFF0277BD),
                    title: 'Form Builder',
                    subtitle: 'Buat & kelola template form\nsesuai kebutuhan klinis Anda',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FormBuilderListView())),
                  ),
                  const SizedBox(height: 14),
                  _buildActionCard(
                    context,
                    icon: Icons.people_alt_rounded,
                    iconBg: const Color(0xFF00695C),
                    title: 'Data Pasien',
                    subtitle: 'Input, lihat, edit, dan hapus\ndata pasien dari form aktif',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PatientListView())),
                  ),
                  const SizedBox(height: 14),
                  _buildActionCard(
                    context,
                    icon: Icons.summarize_rounded,
                    iconBg: const Color(0xFF6A1B9A),
                    title: 'Laporan & Export',
                    subtitle: 'Generate laporan Excel (.xlsx)\ndan PDF profesional offline',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ReportView())),
                  ),

                  const SizedBox(height: 28),
                  // ── Stats Section ──────────────────────────────────────────
                  const Text('Ringkasan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  templatesAsync.when(
                    data: (templates) => _buildStats(templates.length),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ).paddingBottom(50), // Prevent coverage by banner
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required Color iconBg,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(int templateCount) {
    return Row(
      children: [
        _buildStatChip(
            Icons.dynamic_form, '$templateCount', 'Template Form', const Color(0xFF0277BD)),
        const SizedBox(width: 12),
        _buildStatChip(Icons.cloud_off, 'OFFLINE', 'Status', const Color(0xFF2E7D32)),
        const SizedBox(width: 12),
        _buildStatChip(Icons.lock_outline, 'LOKAL', 'Privasi', const Color(0xFF6A1B9A)),
      ],
    );
  }

  Widget _buildStatChip(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(label,
                style:
                    TextStyle(fontSize: 9, color: Colors.grey.shade600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  Widget paddingBottom(double p) => Padding(padding: EdgeInsets.only(bottom: p), child: this);
}
