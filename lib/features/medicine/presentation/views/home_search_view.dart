import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import 'category_views.dart';
import '../../../medical_calculator/presentation/views/medical_calc_home.dart';
import '../../../patient_form/presentation/views/patient_form_home.dart';
import '../widgets/medicine_list_tile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temannakes/core/services/ad_service.dart';
import 'package:temannakes/features/settings/presentation/views/settings_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeSearchView extends ConsumerStatefulWidget {
  const HomeSearchView({super.key});

  @override
  ConsumerState<HomeSearchView> createState() => _HomeSearchViewState();
}

class _HomeSearchViewState extends ConsumerState<HomeSearchView> {
  int _currentIndex = 2; // Default to Dashboard (Home)

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // V7.3: Kill focus on ANY back gesture (swipe or button)
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            CategoryListView(),
            PatientFormHome(),
            MedicineDashboardContent(),
            MedicalCalcHome(),
            SettingsView(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // V7.3: Double-Kill Focus Strategy
          // 1. Tell the manager to unfocus
          FocusManager.instance.primaryFocus?.unfocus();
          // 2. Force the scope to focus on a "dummy" node (The Ultimate Fix)
          FocusScope.of(context).requestFocus(FocusNode());
          setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.category_outlined, 'activeIcon': Icons.category, 'label': 'Kategori', 'color': const Color(0xFF3F51B5)},
      {'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment, 'label': 'Pasien', 'color': const Color(0xFF009688)},
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'label': 'Home', 'color': const Color(0xFF2E7D32)},
      {'icon': Icons.calculate_outlined, 'activeIcon': Icons.calculate, 'label': 'Hitung', 'color': const Color(0xFFE65100)},
      {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': 'Setelan', 'color': const Color(0xFF607D8B)},
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = screenWidth / items.length;

    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Liquid Morphing Indicator (The "Infinity" Glow)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              left: currentIndex * itemWidth + (itemWidth * 0.15),
              bottom: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: itemWidth * 0.7,
                height: 4,
                decoration: BoxDecoration(
                  color: items[currentIndex]['color'],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (items[currentIndex]['color'] as Color).withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = currentIndex == index;
                final itemColor = items[index]['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    // V7.1: Force unfocus to prevent keyboard pop-ups when switching tabs
                    FocusScope.of(context).unfocus();
                    onTap(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
                          child: Column(
                            children: [
                              Icon(
                                isSelected ? items[index]['activeIcon'] : items[index]['icon'],
                                color: isSelected ? itemColor : Colors.grey.shade400,
                                size: isSelected ? 30 : 24,
                              ),
                              if (isSelected) 
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isSelected ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      items[index]['label'],
                                      style: TextStyle(
                                        color: itemColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isSelected)
                          const SizedBox(height: 22), // Space for labels of non-selected
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicineDashboardContent extends ConsumerStatefulWidget {
  const MedicineDashboardContent({super.key});

  @override
  ConsumerState<MedicineDashboardContent> createState() => _MedicineDashboardContentState();
}

class _MedicineDashboardContentState extends ConsumerState<MedicineDashboardContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isEmergencyMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBannerWithRetry();
    });
  }

  Future<void> _initBannerWithRetry({int attempt = 1}) async {
    const maxAttempts = 3;
    if (_isBannerLoaded) return;
    
    final isOnline = await AdService().isOnline();
    if (!isOnline) return;

    if (!_isBannerLoaded) _bannerAd?.dispose();

    final ad = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (!mounted) { ad.dispose(); return; }
        setState(() => _isBannerLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        if (!mounted) return;
        setState(() => _isBannerLoaded = false);
        if (attempt < maxAttempts) {
          Future.delayed(Duration(seconds: attempt == 1 ? 2 : 6), () {
            if (mounted) _initBannerWithRetry(attempt: attempt + 1);
          });
        }
      },
    );

    if (ad != null) {
      _bannerAd = ad..load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _toggleEmergencyMode() {
    setState(() {
      _isEmergencyMode = !_isEmergencyMode;
    });
    if (_isEmergencyMode) {
      ref.read(categoryFilterProvider.notifier).state = 'Darurat';
      ref.read(formFilterProvider.notifier).state = 'Semua';
    } else {
      ref.read(categoryFilterProvider.notifier).state = 'Semua';
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicineList = ref.watch(medicineListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'TemanNakes',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        actions: [
          _buildEmergencyToggle(),
          _buildNetworkIndicator(ref),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(context, ref),
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
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      // V7.2: Kill focus as soon as user starts browsing results
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120), // Space for dock
                    itemCount: list.length,
                    itemBuilder: (context, index) => ProjectMedicineListTile(medicine: list[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          // V7.4: Removed double SafeArea to prevent the ad from floating too high above the bottom dock
          if (_isBannerLoaded && _bannerAd != null && MediaQuery.of(context).viewInsets.bottom == 0)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildEmergencyToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: ActionChip(
        onPressed: _toggleEmergencyMode,
        backgroundColor: _isEmergencyMode ? Colors.red : Colors.red.shade50,
        avatar: Icon(Icons.flash_on, color: _isEmergencyMode ? Colors.white : Colors.red, size: 16),
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
      ),
      child: Column(
        children: [
          TextField(
            autofocus: false,
            focusNode: _searchFocusNode,
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari 20.000+ Referensi Obat...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterRow(),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final categoryFilter = ref.watch(categoryFilterProvider);
    final formFilter = ref.watch(formFilterProvider);
    const golonganOptions = [
      'Semua', 'Antibiotik', 'Analgetik', 'NSAID', 'Diabetes', 
      'HT', 'Vitamin', 'Antivirus', 'Antijamur', 'Steroid', 
      'Psikotropika', 'Darurat', 'Lambung'
    ];
    const bentukOptions = [
      'Semua', 'Tablet', 'Kapsul', 'Sirup', 'Susp', 'Drop', 'Inj', 'Infus',
      'Krim', 'Sachet', 'Tetes', 'Inhaler'
    ];

    return Column(
      children: [
        _buildChipList('Golongan:', golonganOptions, categoryFilter, (v) => ref.read(categoryFilterProvider.notifier).state = v),
        const SizedBox(height: 8),
        _buildChipList('Bentuk:', bentukOptions, formFilter, (v) => ref.read(formFilterProvider.notifier).state = v),
      ],
    );
  }

  Widget _buildChipList(String label, List<String> options, String current, Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ...options.map((o) {
            final selected = current == o;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onSelect(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(o, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? Colors.green.shade900 : Colors.white)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) return const Center(child: Icon(Icons.inventory_2_outlined, size: 60, color: Colors.black12));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Riwayat Pencarian', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => ref.read(searchHistoryProvider.notifier).clear(), child: const Text('Hapus')),
          ],
        ),
        Wrap(
          spacing: 8,
          children: history.map((q) => ActionChip(label: Text(q), onPressed: () {
            _searchCtrl.text = q;
            ref.read(searchQueryProvider.notifier).state = q;
          })).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Tidak ada hasil.', style: TextStyle(color: Colors.grey.shade600)),
          TextButton(onPressed: () => launchUrl(Uri.parse('https://cekbpom.pom.go.id/')), child: const Text('Cek BPOM Online')),
        ],
      ),
    );
  }
}

