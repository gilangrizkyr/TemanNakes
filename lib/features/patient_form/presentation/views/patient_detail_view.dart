import 'package:flutter/material.dart';
import '../../domain/models/form_template.dart';
import '../../domain/models/patient_record.dart';

class PatientDetailView extends StatelessWidget {
  final PatientRecord record;
  final FormTemplate template;

  const PatientDetailView({
    super.key,
    required this.record,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${record.createdAt.day.toString().padLeft(2, '0')}-${record.createdAt.month.toString().padLeft(2, '0')}-${record.createdAt.year}';
    final timeStr =
        '${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detail Pemeriksaan'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF00695C),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.formName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        '$dateStr • $timeStr',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ...template.fields.map((f) => _buildDataCard(f.label, record.displayValue(f.id))),
                  
                  // Handle fields that exist in record but are missing from current template
                  ...record.values.entries
                      .where((e) => !template.fields.any((f) => f.id == e.key))
                      .map((e) => _buildDataCard(
                            'Field Terhapus (${e.key})',
                            record.displayValue(e.key),
                            isOrphan: true,
                          )),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Footer Info
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'PINNACLE V5.5 CLINICAL AUDIT SEAL',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Record ID: ${record.id.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value, {bool isOrphan = false}) {
    IconData icon = Icons.info_outline;
    final lowerLabel = label.toLowerCase();
    
    if (lowerLabel.contains('nama')) {
      icon = Icons.badge_outlined;
    } else if (lowerLabel.contains('usia') || lowerLabel.contains('umur')) {
      icon = Icons.cake_outlined;
    } else if (lowerLabel.contains('alamat')) {
      icon = Icons.home_outlined;
    } else if (lowerLabel.contains('telp') || lowerLabel.contains('phone')) {
      icon = Icons.phone_outlined;
    } else if (lowerLabel.contains('diagnosa')) {
      icon = Icons.medical_services_outlined;
    } else if (lowerLabel.contains('obat')) {
      icon = Icons.medication_outlined;
    } else if (lowerLabel.contains('catatan')) {
      icon = Icons.description_outlined;
    } else if (lowerLabel.contains('keluhan')) {
      icon = Icons.sick_outlined;
    } else if (lowerLabel.contains('tekanan') || lowerLabel.contains('tensi')) {
      icon = Icons.speed_outlined;
    } else if (lowerLabel.contains('berat')) {
      icon = Icons.monitor_weight_outlined;
    } else if (lowerLabel.contains('tinggi')) {
      icon = Icons.height_outlined;
    } else if (lowerLabel.contains('suhu') || lowerLabel.contains('temp')) {
      icon = Icons.thermostat_outlined;
    } else if (lowerLabel.contains('nadi') || lowerLabel.contains('pulse') || lowerLabel.contains('hr')) {
      icon = Icons.favorite_outline;
    } else if (lowerLabel.contains('nafas') || lowerLabel.contains('respirasi') || lowerLabel.contains('rr')) {
      icon = Icons.air_outlined;
    } else if (lowerLabel.contains('saturasi') || lowerLabel.contains('spo2')) {
      icon = Icons.bloodtype_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isOrphan ? Colors.orange : const Color(0xFF00695C)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isOrphan ? Colors.orange : const Color(0xFF00695C), size: 24),
        ),
        title: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isOrphan ? Colors.orange.shade800 : Colors.grey.shade500,
            letterSpacing: 1.1,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
