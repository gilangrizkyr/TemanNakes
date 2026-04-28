import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import '../../domain/models/medicine.dart';
import '../views/medicine_detail_view.dart';

class ProjectMedicineListTile extends ConsumerWidget {
  final MedicineSimple medicine;
  const ProjectMedicineListTile({super.key, required this.medicine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Clinical Indicator Logic
    Color indicatorColor = Colors.green;
    String indicatorLabel = 'B'; // Bebas
    
    if (medicine.golongan?.contains('Keras') ?? false) {
      indicatorColor = Colors.red;
      indicatorLabel = 'K';
    } else if (medicine.golongan?.contains('Terbatas') ?? false) {
      indicatorColor = Colors.blue;
      indicatorLabel = 'T';
    }

    final isFavorite = ref.watch(isFavoriteProvider(medicine.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Hero(
          tag: 'med-${medicine.id}',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: indicatorColor.withOpacity(0.2), width: 2),
            ),
            child: Center(
              child: Text(
                indicatorLabel,
                style: TextStyle(color: indicatorColor, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
        ),
        title: Text(
          medicine.namaGenerik,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medicine.namaDagang ?? '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildTag(medicine.bentuk ?? 'Sediaan', Colors.grey.shade100, Colors.grey.shade700),
                const SizedBox(width: 6),
                _buildTag(medicine.kodeNie ?? 'NIE', Colors.blue.shade50, Colors.blue.shade700),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
                size: 22,
              ),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(medicine.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.orange, size: 22),
              onPressed: () => _showQuickAction(context, medicine, ref),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailView(medicine: medicine),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showQuickAction(BuildContext context, MedicineSimple medicine, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        // Must use Consumer inside builder — parent ref can't watch inside a separate widget sub-tree
        return Consumer(
          builder: (context, innerRef, _) {
            final detailAsync = innerRef.watch(medicineDetailProvider(medicine.id));
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: detailAsync.when(
                data: (detail) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(medicine.namaGenerik,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        Text(medicine.kodeNie ?? '',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildQuickRow('INDIKASI', detail?.indikasi ?? '-'),
                    const SizedBox(height: 16),
                    _buildQuickRow('DOSIS DEWASA', detail?.dosisDewasa ?? '-'),
                    const SizedBox(height: 16),
                    _buildQuickRow('PREGNANCY', detail?.kategoriKehamilan ?? '?', color: Colors.indigo),
                    const SizedBox(height: 16),
                    _buildQuickRow('KELAS TERAPI', detail?.kelasTerapi ?? '-', color: Colors.green),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Gagal memuat info.', textAlign: TextAlign.center),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickRow(String label, String value, {Color color = Colors.grey}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
