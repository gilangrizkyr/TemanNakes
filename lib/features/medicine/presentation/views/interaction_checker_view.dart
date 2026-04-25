import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../../../../core/database/database_helper.dart';

class InteractionCheckerTray extends StatefulWidget {
  const InteractionCheckerTray({super.key});

  @override
  State<InteractionCheckerTray> createState() => _InteractionCheckerTrayState();
}

class _InteractionCheckerTrayState extends State<InteractionCheckerTray> {
  final List<MedicineSimple> _selectedMedicines = [];
  final List<String> _interactionWarnings = [];
  bool _isLoading = false;

  void _addMedicine(MedicineSimple medicine) {
    if (_selectedMedicines.any((m) => m.id == medicine.id)) return;
    setState(() {
      _selectedMedicines.add(medicine);
    });
    _checkInteractions();
  }

  void _removeMedicine(int id) {
    setState(() {
      _selectedMedicines.removeWhere((m) => m.id == id);
    });
    _checkInteractions();
  }

  Future<void> _checkInteractions() async {
    if (_selectedMedicines.length < 2) {
      setState(() => _interactionWarnings.clear());
      return;
    }

    setState(() => _isLoading = true);
    
    final List<String> warnings = [];
    final List<MedicineDetail> details = [];

    // Fetch all details
    for (final m in _selectedMedicines) {
      final detail = await DatabaseHelper.instance.getMedicineDetail(m.id);
      if (detail != null) details.add(detail);
    }

    // Real keyword scan logic
    for (var i = 0; i < details.length; i++) {
      final currentDetail = details[i];
      final currentName = _selectedMedicines[i].namaGenerik.toLowerCase();
      final interactionText = currentDetail.interaksi?.toLowerCase() ?? '';

      for (var j = 0; j < _selectedMedicines.length; j++) {
        if (i == j) continue;
        final otherName = _selectedMedicines[j].namaGenerik.toLowerCase();
        
        if (interactionText.contains(otherName)) {
          warnings.add('⚠️ POTENSI INTERAKSI: ${_selectedMedicines[i].namaGenerik} dapat berinteraksi dengan ${_selectedMedicines[j].namaGenerik}.');
        }
      }
    }

    setState(() {
      _interactionWarnings.clear();
      _interactionWarnings.addAll(warnings.toSet().toList()); // Deduplicate
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Interaksi')),
      body: Column(
        children: [
          _buildInfoPanel(),
          Expanded(
            child: _selectedMedicines.isEmpty 
              ? _buildEmptyState()
              : _buildSelectedList(),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          _buildWarningPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMedicinePicker(context),
        label: const Text('Tambah Obat'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pilih minimal 2 obat untuk memindai interaksi secara otomatis.',
              style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.medication, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Belum ada obat dipilih.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSelectedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedMedicines.length,
      itemBuilder: (context, index) {
        final medicine = _selectedMedicines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.medication, color: Colors.green, size: 20),
            ),
            title: Text(medicine.namaGenerik, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(medicine.golongan ?? '-'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeMedicine(medicine.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningPanel() {
    if (_interactionWarnings.isEmpty && _selectedMedicines.length >= 2 && !_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.green.shade100,
        child: const Text(
          '✅ Tidak ditemukan interaksi spesifik dalam database untuk kombinasi ini.',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_interactionWarnings.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('TEMUAN KLINIS:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.orange, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          ..._interactionWarnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(w, style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _showMedicinePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, _) {
            final medicines = ref.watch(medicineListProvider);
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Pilih Obat untuk Dicek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(
                  child: medicines.when(
                    data: (list) => ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final m = list[index];
                        final isSelected = _selectedMedicines.any((sel) => sel.id == m.id);
                        return ListTile(
                          title: Text(m.namaGenerik),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          onTap: () {
                            if (!isSelected) _addMedicine(m);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Gagal memuat'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
