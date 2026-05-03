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
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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

}
