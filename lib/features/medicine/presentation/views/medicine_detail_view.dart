import 'package:flutter/material.dart';
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
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecialHeader(detail),
          const SizedBox(height: 16),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSpecialHeader(MedicineDetail detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          _buildBadge('PREGNANCY', detail.kategoriKehamilan ?? 'N/A', Colors.indigo),
          const SizedBox(width: 12),
          _buildBadge('CLASS', detail.kelasTerapi ?? '-', Colors.green),
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
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String? content, IconData icon, Color color) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
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
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: color.withOpacity(0.8),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
}
