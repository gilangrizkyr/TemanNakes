import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import '../../domain/models/medicine.dart';
// import 'medicine_detail_view.dart';
import 'interaction_checker_view.dart';
import 'category_views.dart';
import '../../../favorites/presentation/views/favorites_view.dart';
import '../../../medical_calculator/presentation/views/medical_calc_home.dart';
import '../widgets/medicine_list_tile.dart';

class HomeSearchView extends ConsumerStatefulWidget {
  const HomeSearchView({super.key});

  @override
  ConsumerState<HomeSearchView> createState() => _HomeSearchViewState();
}

class _HomeSearchViewState extends ConsumerState<HomeSearchView> {
  bool _isEmergencyMode = false;

  void _toggleEmergencyMode() {
    setState(() {
      _isEmergencyMode = !_isEmergencyMode;
    });
    if (_isEmergencyMode) {
      ref.read(searchQueryProvider.notifier).state = "Adrenaline Atropine Epinephrine Dextrose Diazepam";
    } else {
      ref.read(searchQueryProvider.notifier).state = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicineList = ref.watch(medicineListProvider);
    final history = ref.watch(searchHistoryProvider);
    final trending = ref.watch(trendingMedicinesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('TemanNakes Hyper-Supreme'),
        actions: [
          _buildEmergencyToggle(),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => _showHistory(context, history),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildSearchHeader(context),
          _buildSmartSuggestions(trending),
          Expanded(
            child: medicineList.when(
              data: (list) {
                if (list.isEmpty && ref.read(searchQueryProvider).isEmpty) {
                  return _buildHistorySection();
                }
                if (list.isEmpty) return _buildNoResults();
                return _buildMedicinesList(list);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Koneksi Database Error: $err')),
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
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2E7D32)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text('TemanNakes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
            leading: const Icon(Icons.flash_on, color: Colors.orange),
            title: const Text('Cek Interaksi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InteractionCheckerTray()));
            },
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
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Favorit'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesView()));
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          const Spacer(),
          const Text('Developed by GilangRizky', style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 16),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil untuk "${ref.watch(searchQueryProvider)}"',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
                  ref.read(searchQueryProvider.notifier).state = m.namaGenerik;
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

  Widget _buildSearchHeader(BuildContext context) {
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
            onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Cari 20.565+ Obat (Nama, NIE, Sediaan...)',
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
          const SizedBox(height: 16),
          _buildStatsDashboard(),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('20,565', 'DATABASE', Icons.storage),
        _buildStatItem('BM25 v2', 'RANKING', Icons.leaderboard),
        _buildStatItem('OFFLINE', 'STATUS', Icons.cloud_off),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
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
            onPressed: () => ref.read(searchQueryProvider.notifier).state = q,
          )).toList(),
        ),
      ],
    );
  }

  void _showHistory(BuildContext context, List<String> history) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Riwayat Terkini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            if (history.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Kosong')),
            ...history.map((h) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(h),
              onTap: () {
                ref.read(searchQueryProvider.notifier).state = h;
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TemanNakes',
      applicationVersion: '1.5.0 (Hyper-Supreme)',
      applicationIcon: const Icon(Icons.medication_liquid, size: 40, color: Color(0xFF1B5E20)),
      children: [
        const Text('TemanNakes adalah asisten klinis referensi obat offline yang dirancang untuk tenaga kesehatan Indonesia dengan presisi tinggi.'),
        const SizedBox(height: 16),
        const Text('Pengembang:', style: TextStyle(fontWeight: FontWeight.bold)),
        InkWell(
          onTap: () => _launchGitHub(),
          child: const Text('GilangRizky (github.com/gilangrizkyr)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        const Text('Fitur Supreme:'),
        const Text('• 20,565 Database Obat BPOM Terverifikasi'),
        const Text('• Ultra-Fast FTS5 BM25 Ranked Search'),
        const Text('• Pharmacological Class-Matrix v2.0 Checker'),
        const Text('• Kalkulator Dosis BSA (Mosteller) & Renal Guard'),
      ],
    );
  }

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/gilangrizkyr');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}

