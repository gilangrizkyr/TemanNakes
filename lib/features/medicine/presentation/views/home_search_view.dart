import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import '../../domain/models/medicine.dart';
// import 'medicine_detail_view.dart';
import 'interaction_checker_view.dart';
import 'category_views.dart';
// import '../../../favorites/presentation/views/favorites_view.dart';
import '../../../medical_calculator/presentation/views/medical_calc_home.dart';
import '../../../patient_form/presentation/views/patient_form_home.dart';
import '../widgets/medicine_list_tile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temannakes/core/services/ad_service.dart';
import 'package:temannakes/features/settings/presentation/views/about_view.dart';
import 'package:temannakes/features/settings/presentation/views/privacy_policy_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeSearchView extends ConsumerStatefulWidget {
  const HomeSearchView({super.key});

  @override
  ConsumerState<HomeSearchView> createState() => _HomeSearchViewState();
}

class _HomeSearchViewState extends ConsumerState<HomeSearchView> {
  bool _isEmergencyMode = false;
  final _searchCtrl = TextEditingController();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    // [FIX D] Timing guard: start banner AFTER first frame to avoid race condition
    // where AdMob SDK is not yet ready when widget initializes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBannerWithRetry();
    });
  }

  // [RPM OPT] Slow-network banner retry with cache guard.
  // IMPORTANT: If banner already loaded, do nothing — never destroy a live ad.
  Future<void> _initBannerWithRetry({int attempt = 1}) async {
    const maxAttempts = 3;

    // [CACHE GUARD] Exit immediately if banner is already successfully loaded.
    // This prevents accidentally disposing a healthy live banner on a retry call.
    if (_isBannerLoaded) {
      debugPrint('🎯 Banner cache hit — skipping reload.');
      return;
    }

    debugPrint('🔍 HomeSearchView: Banner attempt $attempt/$maxAttempts...');

    final isOnline = await AdService().isOnline();
    if (!isOnline) {
      debugPrint('📵 HomeSearchView: Offline — Banner skipped.');
      return;
    }

    // Only dispose if not loaded (safe cleanup of previous failed attempt)
    if (!_isBannerLoaded) _bannerAd?.dispose();

    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        debugPrint('🎯 HomeSearchView: Banner loaded on attempt $attempt.');
        setState(() => _isBannerLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('💥 Banner failed (attempt $attempt): ${error.message}');
        if (!mounted) return;
        setState(() => _isBannerLoaded = false);

        // [FIX B] Retry with exponential backoff if attempts remain
        if (attempt < maxAttempts) {
          final delay = Duration(seconds: attempt == 1 ? 2 : 6);
          debugPrint('🔄 Retrying banner in ${delay.inSeconds}s...');
          Future.delayed(delay, () {
            if (mounted) _initBannerWithRetry(attempt: attempt + 1);
          });
        } else {
          debugPrint('⛔ Banner max attempts reached. Running without ads.');
        }
      },
    )..load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _setSearch(String value) {
    _searchCtrl.text = value;
    _searchCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    _onSearchChanged(value);
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _toggleEmergencyMode() {
    setState(() {
      _isEmergencyMode = !_isEmergencyMode;
    });
    if (_isEmergencyMode) {
      // Emergency: filter by 'Darurat' golongan — exact match from DB
      ref.read(categoryFilterProvider.notifier).state = 'Darurat';
      ref.read(formFilterProvider.notifier).state = 'Semua';
      _setSearch('');
    } else {
      ref.read(categoryFilterProvider.notifier).state = 'Semua';
      _setSearch('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicineList = ref.watch(medicineListProvider);
    final trending = ref.watch(trendingMedicinesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('TemanNakes'),
        actions: [
          _buildEmergencyToggle(),
          _buildNetworkIndicator(ref),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildSearchHeader(context, ref),
          _buildSmartSuggestions(trending),
          Expanded(
            child: medicineList.when(
              data: (list) {
                final query = ref.watch(searchQueryProvider);
                if (list.isEmpty && query.isEmpty &&
                    ref.watch(categoryFilterProvider) == 'Semua' &&
                    ref.watch(formFilterProvider) == 'Semua') {
                  return _buildHistorySection();
                }
                if (list.isEmpty) return _buildNoResults();
                return _buildMedicinesList(list);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Koneksi Database Error: $err')),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', width: 60, height: 60),
                  const SizedBox(height: 10),
                  const Text('TemanNakes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Cari Obat'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Kategori Penyakit'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryListView()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: Color(0xFF1B5E20)),
            title: const Text('Kalkulator Medis'),
            subtitle: const Text('6 modul klinis', style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicalCalcHome()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Color(0xFF0277BD)),
            title: const Text('Form Pasien'),
            subtitle: const Text('Data & Laporan Otomatis', style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientFormHome()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutView()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan Privasi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyView()));
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Institutional Data Integrity Verified',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Developed by ',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      TextSpan(
                        text: 'GilangRizky',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMedicinesList(List<MedicineSimple> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) => ProjectMedicineListTile(medicine: list[index]),
    );
  }

  Widget _buildNoResults() {
    final query = ref.watch(searchQueryProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil untuk "$query"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan ejaan benar atau gunakan nama generik. Jika obat baru saja rilis, silakan cek database online.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://cekbpom.pom.go.id/'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('CEK BPOM ONLINE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: ActionChip(
        onPressed: _toggleEmergencyMode,
        backgroundColor: _isEmergencyMode ? Colors.red : Colors.red.shade50,
        avatar: Icon(Icons.emergency_share, color: _isEmergencyMode ? Colors.white : Colors.red, size: 16),
        label: Text(
          'EMERGENCY',
          style: TextStyle(
            color: _isEmergencyMode ? Colors.white : Colors.red,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSmartSuggestions(AsyncValue<List<MedicineSimple>> trending) {
    return trending.when(
      data: (list) => Container(
        height: 50,
        color: Colors.white,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 12),
              child: Text('Sering Dicari:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ...list.take(4).map((m) => Container(
              margin: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(m.namaGenerik, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  _setSearch(m.namaGenerik);
                  ref.read(searchHistoryProvider.notifier).add(m.namaGenerik);
                },
                backgroundColor: Colors.green.shade50,
                side: BorderSide(color: Colors.green.shade100),
                visualDensity: VisualDensity.compact,
              ),
            )),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Cari 20.000+ Produk & Referensi...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 10),
          _buildFilterRow(),
        ],
      ),
    );
  }

  Widget _buildNetworkIndicator(WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    return connectivity.when(
      data: (result) {
        final isOnline = result != ConnectivityResult.none;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.lightGreenAccent : Colors.redAccent,
            size: 20,
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
      ),
      error: (_, __) => const Icon(Icons.wifi_off, color: Colors.white24, size: 20),
    );
  }

  Widget _buildFilterRow() {
    final categoryFilter = ref.watch(categoryFilterProvider);
    final formFilter = ref.watch(formFilterProvider);
    const golonganOptions = [
      'Semua', 
      'Antibiotik', 
      'Analgetik', 
      'NSAID', 
      'Diabetes', 
      'HT', // Matches HT/Angina, ACEI, ARB via UI Label mapping or LIKE
      'Vitamin', 
      'Antivirus', 
      'Antijamur', 
      'Steroid', 
      'Psikotropika', 
      'Darurat',
      'Lambung' // Matches PPI, H2 Blocker
    ];
    const bentukOptions = [
      'Semua', 
      'Tablet', 
      'Kapsul', 
      'Sirup', 
      'Inj', 
      'Infus',
      'Krim',
      'Sachet',
      'Tetes', 
      'Inhaler'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Golongan:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ...golonganOptions.map((g) {
                final selected = categoryFilter == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => ref.read(categoryFilterProvider.notifier).state = g,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(g,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected ? const Color(0xFF1B5E20) : Colors.white,
                          )),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Bentuk:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ...bentukOptions.map((b) {
                final selected = formFilter == b;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => ref.read(formFilterProvider.notifier).state = b,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(b,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected ? const Color(0xFF1B5E20) : Colors.white,
                          )),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildHistorySection() {
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text('Siap melayani referensi klinis.', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Riwayat Pencarian', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
              child: const Text('Hapus'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: history.map((q) => ActionChip(
            label: Text(q),
            onPressed: () => _setSearch(q),
          )).toList(),
        ),
      ],
    );
  }


}

