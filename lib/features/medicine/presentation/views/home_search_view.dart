import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import 'medicine_detail_view.dart';
import 'interaction_checker_view.dart';
import 'category_views.dart';
import '../../../favorites/presentation/views/favorites_view.dart';
import '../widgets/medicine_list_tile.dart';

class HomeSearchView extends ConsumerWidget {
  const HomeSearchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicineList = ref.watch(medicineListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TemanNakes'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Panduan Penggunaan'),
              onTap: () {
                Navigator.pop(context);
                _showGuideDialog(context);
              },
            ),
            const Spacer(),
            InkWell(
              onTap: () => _launchGitHub(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    Text('Developed by', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    SizedBox(height: 4),
                    Text('GilangRizky', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    Text('github.com/gilangrizkyr', style: TextStyle(color: Colors.blue, fontSize: 10, decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBox(ref),
          Expanded(
            child: medicineList.when(
              data: (medicines) {
                if (medicines.isEmpty && ref.read(searchQueryProvider).isEmpty) {
                  return _buildHistory(ref);
                }
                if (medicines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data untuk "${ref.watch(searchQueryProvider)}"',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text('Coba gunakan kata kunci lain', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    return ProjectMedicineListTile(medicine: medicine);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(WidgetRef ref) {
    final selectedForm = ref.watch(formFilterProvider);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
            decoration: InputDecoration(
              hintText: 'Cari nama generik, dagang, atau kode...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ref.watch(searchQueryProvider).isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Semua', provider: formFilterProvider),
                _FilterChip(label: 'Tablet', provider: formFilterProvider),
                _FilterChip(label: 'Sirup', provider: formFilterProvider),
                _FilterChip(label: 'Kapsul', provider: formFilterProvider),
                _FilterChip(label: 'Injeksi', provider: formFilterProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = q;
              },
            )).toList(),
          ),
          const Divider(),
        ],
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
        const Text('• 280+ Database Obat Alodokter A-Z'),
        const Text('• Ultra-Fast FTS5 Advanced Search'),
        const Text('• Smart Interaction Scanner (Keyword-Reactive)'),
        const Text('• Kalkulator Dosis Desimal (Pediatrik & Dewasa)'),
      ],
    );
  }

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/gilangrizkyr');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Panduan Penggunaan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('1. Pencarian:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Gunakan kolom cari untuk mencari nama generik, dagang, atau kode obat.'),
              SizedBox(height: 8),
              Text('2. Quick Info:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Ketuk ikon petir (⚡) di daftar obat untuk melihat ringkasan cepat dosis dan indikasi.'),
              SizedBox(height: 8),
              Text('3. Cek Interaksi:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Pilih menu "Cek Interaksi" di drawer, lalu tambahkan obat yang ingin diperiksa.'),
              SizedBox(height: 8),
              Text('4. Kalkulator Dosis:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Buka detail obat, lalu klik tombol "Kalkulator Dosis" di pojok kanan bawah.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final StateProvider<String> provider;
  const _FilterChip({required this.label, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(provider);
    final isSelected = selected == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (val) {
          ref.read(provider.notifier).state = label;
        },
      ),
    );
  }
}

