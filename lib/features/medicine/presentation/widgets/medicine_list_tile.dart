import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import '../views/medicine_detail_view.dart';

class ProjectMedicineListTile extends ConsumerWidget {
  final dynamic medicine;
  const ProjectMedicineListTile({super.key, required this.medicine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.notifier).isFavorite(medicine.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          medicine.namaGenerik,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${medicine.namaDagang ?? "-"} • ${medicine.bentuk ?? "-"}'),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : null,
              ),
              onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(medicine.id),
              tooltip: 'Favorit',
            ),
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.orange),
              onPressed: () => _showQuickAction(context, medicine, ref),
              tooltip: 'Quick Info',
            ),
            const Icon(Icons.chevron_right),
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

  void _showQuickAction(BuildContext context, dynamic medicine, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final detailAsync = ref.watch(medicineDetailProvider(medicine.id));
        return Container(
          padding: const EdgeInsets.all(24),
          child: detailAsync.when(
            data: (detail) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Info: ${medicine.namaGenerik}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                const Text('INDIKASI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                Text(detail?.indikasi ?? 'Tidak ada data'),
                const SizedBox(height: 16),
                const Text('DOSIS DEWASA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                Text(detail?.dosisDewasa ?? 'Tidak ada data'),
                const SizedBox(height: 16),
                const Text('DOSIS ANAK:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                Text(detail?.dosisAnak ?? 'Tidak ada data'),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Gagal memuat data'),
          ),
        );
      },
    );
  }
}
