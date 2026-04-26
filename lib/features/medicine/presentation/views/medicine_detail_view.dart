import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../../../calculator/presentation/views/dose_calculator_view.dart';

class MedicineDetailView extends ConsumerWidget {
  final MedicineSimple medicine;
  const MedicineDetailView({super.key, required this.medicine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(medicineDetailProvider(medicine.id));
    final isFavorite = ref.watch(favoritesProvider.notifier).isFavorite(medicine.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(medicine.namaGenerik),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(medicine.id);
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Data detail tidak ditemukan.'));
          }
          return _buildDetailContent(context, detail);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: detailAsync.when(
        data: (detail) => detail != null ? FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoseCalculatorView(medicine: medicine, detail: detail),
              ),
            );
          },
          label: const Text('Kalkulator Dosis'),
          icon: const Icon(Icons.calculate),
        ) : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, MedicineDetail detail) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecialHeader(detail),
          _buildQuickActions(context, detail),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInfoSection(context, 'Indikasi', detail.indikasi, Icons.info_outline, Colors.blue),
                _buildInfoSection(context, 'Dosis Dewasa', detail.dosisDewasa, Icons.person, Colors.teal),
          _buildInfoSection(context, 'Dosis Anak', detail.dosisAnak, Icons.child_care, Colors.orange),
          _buildInfoSection(context, 'Mutiara Klinis (G-Pearls)', detail.clinicalPearls, Icons.tips_and_updates, Colors.purple),
          _buildInfoSection(context, 'Penyesuaian Ginjal', detail.penyesuaianGinjal, Icons.health_and_safety, Colors.teal.shade700),
          _buildInfoSection(context, 'Efek Samping', detail.efekSamping, Icons.warning_amber_rounded, Colors.red),
          _buildInfoSection(context, 'Kontraindikasi', detail.kontraindikasi, Icons.block, Colors.redAccent),
          _buildInfoSection(context, 'Interaksi', detail.interaksi, Icons.compare_arrows, Colors.deepPurple),
          _buildInfoSection(context, 'Penyimpanan (Storage)', detail.storage, Icons.ac_unit, Colors.lightBlue),
          _buildInfoSection(context, 'Peringatan', detail.peringatan, Icons.priority_high, Colors.amber),
          _buildInfoSection(context, 'Overdosis', detail.overdosis, Icons.warning, Colors.red.shade900),
                _buildInfoSection(context, 'Edukasi', detail.edukasi, Icons.school_outlined, Colors.green),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'DATA TERVERIFIKASI PINNACLE V2.0',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialHeader(MedicineDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF004D40),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          _buildBadge('PREGNANCY', detail.kategoriKehamilan ?? 'N/A', Colors.amber),
          const SizedBox(width: 12),
          _buildBadge('CLASS', detail.kelasTerapi ?? '-', Colors.white),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, MedicineDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoseCalculatorView(medicine: medicine, detail: detail))),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Kalkulasi Dosis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${medicine.namaGenerik}\nDosis: ${detail.dosisDewasa}\nIndikasi: ${detail.indikasi}'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detail obat disalin ke clipboard')));
            },
            icon: const Icon(Icons.copy_all, color: Color(0xFF00796B)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.teal.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withOpacity(0.6), letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String? content, IconData icon, Color color) {
    final bool isEmpty = content == null || content.isEmpty || content == '-';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: isEmpty ? Colors.grey.shade400 : color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: isEmpty ? Colors.grey : color, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                title.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: isEmpty ? Colors.grey : color.withOpacity(0.8),
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          if (isEmpty) 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Text('DATA KHUSUS/KOSONG', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isEmpty)
                        _buildEmptyContent(context, title)
                      else
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi belum tersedia di database luring atau obat ini mungkin memiliki indikasi/kontraindikasi khusus.',
          style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse('https://cekbpom.pom.go.id/'), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new, size: 14),
          label: const Text('VERIFIKASI BPOM ONLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: Colors.indigo,
          ),
        ),
      ],
    );
  }
}
