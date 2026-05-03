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

    // Professional Interaction Matrix (Class-to-Class) with Severity
    final interactionMatrix = {
      'ACEI': {
        'NSAID': {'txt': 'Risiko penurunan fungsi ginjal & penurunan efek antihipertensi.', 'sev': 'Moderate'},
        'KALIUM': {'txt': 'Risiko Hiperkalemia berat (Potassium-sparing interaction).', 'sev': 'Major'},
        'SPIRONOLAKTON': {'txt': 'Risiko Hiperkalemia berat.', 'sev': 'Major'},
        'DIURETIK': {'txt': 'Risiko Hipotensi mendadak pada dosis pertama.', 'sev': 'Moderate'},
      },
      'ARB': {
        'NSAID': {'txt': 'Risiko penurunan fungsi ginjal.', 'sev': 'Moderate'},
        'KALIUM': {'txt': 'Risiko Hiperkalemia.', 'sev': 'Major'},
        'SPIRONOLAKTON': {'txt': 'Risiko Hiperkalemia.', 'sev': 'Major'},
      },
      'BETA BLOCKER': {
        'INSULIN': {'txt': 'Menutupi gejala hipoglikemia (palpitasi/tremor). Penting untuk DM.', 'sev': 'Moderate'},
        'EPINEFRIN': {'txt': 'Risiko kenaikan tekanan darah mendadak (Hipertensi Paroksimal).', 'sev': 'Major'},
        'VERAPAMIL': {'txt': 'Risiko Bradikardia berat & AV Block.', 'sev': 'Major'},
        'DILTIAZEM': {'txt': 'Risiko depresi fungsi jantung & bradikardia.', 'sev': 'Major'},
      },
      'NSAID': {
        'WARFARIN': {'txt': 'Peningkatan risiko perdarahan hebat (Synergy Antiplatelet).', 'sev': 'Major'},
        'ASPIRIN': {'txt': 'Menurunkan efek perlindungan jantung Aspirin.', 'sev': 'Moderate'},
        'STEROID': {'txt': 'Risiko tinggi perlukaan lambung/tukak/perforasi.', 'sev': 'Major'},
        'METOTREKSAT': {'txt': 'Meningkatkan toksisitas Metotreksat.', 'sev': 'Major'},
        'QUINOLONE': {'txt': 'Risiko stimulasi SSP & kejang (jarang).', 'sev': 'Minor'},
      },
      'PPI': {
        'CLOPIDOGREL': {'txt': 'Menurunkan efektivitas antithrombotik Clopidogrel (CYP2C19 inhib).', 'sev': 'Moderate'},
        'KETOKONAZOL': {'txt': 'Menurunkan penyerapan obat antijamur.', 'sev': 'Minor'},
      },
      'ANTASIDA': {
        'TETRASIKLIN': {'txt': 'Kelasi: Menurunkan penyerapan antibiotik secara drastis.', 'sev': 'Major'},
        'QUINOLONE': {'txt': 'Kelasi: Menurunkan penyerapan antibiotik (Ciprofloxacin dll).', 'sev': 'Major'},
        'LEVO-TIROKSIN': {'txt': 'Menurunkan penyerapan hormon tiroid.', 'sev': 'Moderate'},
        'DIGOXIN': {'txt': 'Dapat menurunkan penyerapan Digoxin.', 'sev': 'Minor'},
      },
      'DIGOXIN': {
        'FUROSEMID': {'txt': 'Hipokalemia meningkatkan risiko toksisitas Digoxin.', 'sev': 'Major'},
        'AMIODARON': {'txt': 'Meningkatkan kadar Digoxin plasma (Risiko Aritmia).', 'sev': 'Major'},
        'VERAPAMIL': {'txt': 'Meningkatkan risiko Bradikardia & kadar Digoxin.', 'sev': 'Major'},
      },
      'WARFARIN': {
        'AMIODARON': {'txt': 'Meningkatkan efek antikoagulan (Risiko Perdarahan Berat).', 'sev': 'Major'},
        'ERITROMISIN': {'txt': 'Meningkatkan efek antikoagulan.', 'sev': 'Major'},
        'STATIN': {'txt': 'Beberapa statin meningkatkan efek Warfarin.', 'sev': 'Moderate'},
      },
      'STATIN': {
        'ERITROMISIN': {'txt': 'Peningkatan risiko Rhabdomyolysis.', 'sev': 'Major'},
        'KLARITROMISIN': {'txt': 'Peningkatan risiko Rhabdomyolysis.', 'sev': 'Major'},
        'GEMFIBROZIL': {'txt': 'Risiko tinggi miopati/rhabdomyolysis.', 'sev': 'Major'},
      },
      'SILDENAFIL': {
        'NITRAT': {'txt': 'KONTRAINDIKASI VITAL: Hipotensi berat yang mematikan.', 'sev': 'Major'},
        'NITROGLISERIN': {'txt': 'KONTRAINDIKASI VITAL: Hipotensi berat yang mematikan.', 'sev': 'Major'},
      },
      'METFORMIN': {
        'STEROID': {'txt': 'Steroid meningkatkan gula darah, melawan efek Metformin.', 'sev': 'Moderate'},
        'DIURETIK': {'txt': 'Risiko asidosis laktat (jarang).', 'sev': 'Minor'},
      },
    };

    String normalizeClass(String? raw) {
      if (raw == null) return '';
      final r = raw.toUpperCase();
      
      // ACE Inhibitor
      if (r.contains('ACE-INHIBITOR') || r.contains('ACE INHIBITOR') || r.contains('PENGHAMBAT ACE')) return 'ACEI';
      
      // ARB
      if (r.contains('ARB') || r.contains('ANGIOTENSIN RECEPTOR BLOCKER') || r.contains('ANTAGONIS RESEPTOR ANGIOTENSIN')) return 'ARB';
      
      // NSAID
      if (r.contains('NSAID') || r.contains('NON STEROID') || r.contains('ANTI-INFLAMASI NON-STEROID') || r.contains('AINS')) return 'NSAID';
      
      // PPI
      if (r.contains('PPI') || r.contains('PUMP INHIBITOR') || r.contains('PENGHAMBAT POMPA PROTON')) return 'PPI';
      
      // Beta Blocker
      if (r.contains('BETA-BLOCKER') || r.contains('BETA BLOCKER') || r.contains('PENGHAMBAT BETA')) return 'BETA BLOCKER';
      
      // CCB
      if (r.contains('CALCIUM CHANNEL') || r.contains('ANTAGONIS KALSIUM')) return 'CCB';
      
      // Statin
      if (r.contains('STATIN') || r.contains('KOLESTEROL')) return 'STATIN';
      if (r.contains('SPIRONOLAKTON') || r.contains('HEMAT KALIUM')) return 'SPIRONOLAKTON';
      if (r.contains('DIGOXIN') || r.contains('GLIKOSIDA JANTUNG')) return 'DIGOXIN';
      if (r.contains('STEROID') || r.contains('KORTIKOSTEROID')) return 'STEROID';
      if (r.contains('METFORMIN') || r.contains('ANTIDIABETIK')) return 'METFORMIN';
      if (r.contains('QUINOLONE') || r.contains('KUINOLON') || r.contains('CIPROFLOXACIN')) return 'QUINOLONE';
      if (r.contains('KALIUM') || r.contains('POTASSIUM')) return 'KALIUM';
      if (r.contains('DIURETIK') || r.contains('FUROSEMID')) return 'DIURETIK';
      if (r.contains('WARFARIN') || r.contains('ANTIKOAGULAN')) return 'WARFARIN';
      if (r.contains('NITRAT') || r.contains('ISDN') || r.contains('NITROGLISERIN')) return 'NITRAT';
      
      return r;
    }

    // Scan for interactions
    for (var i = 0; i < details.length; i++) {
      final current = details[i];
      final currentClass = normalizeClass(current.kelasTerapi ?? current.golongan);
      
      for (var j = 0; j < details.length; j++) {
        if (i == j) continue;
        final other = details[j];
        final otherName = other.namaGenerik.toLowerCase().trim();
        final otherClass = normalizeClass(other.kelasTerapi ?? other.golongan);
        
        // 1. Direct Keyword Check (Concrete Regex Matching)
        // Menggunakan regex \b (word boundary) agar "Aspirin" tidak match dengan "Aspirin-like compound" secara salah
        if (current.interaksi != null) {
          final escapedName = RegExp.escape(otherName);
          final regExp = RegExp('\\b$escapedName\\b', caseSensitive: false);
          if (regExp.hasMatch(current.interaksi!)) {
            warnings.add('MAJOR|⚠️ [DATA KONKRET] ${current.namaGenerik} memiliki catatan interaksi spesifik dengan $otherName di database.');
          }
        }

        // 2. Class-based Matrix Check (Deep Clinical Logic)
        if (interactionMatrix.containsKey(currentClass)) {
          final interClassDict = interactionMatrix[currentClass]!;
          // Check if other's name OR other's class exists in the matrix for currentClass
          // Priority: Specific Drug Name > Broad Pharmacological Class
          final matchKey = [otherName.toUpperCase(), otherClass].firstWhere(
            (key) => interClassDict.containsKey(key),
            orElse: () => '',
          );

          if (matchKey.isNotEmpty) {
            final data = interClassDict[matchKey]!;
            final sev = data['sev']!.toUpperCase();
            warnings.add('$sev|${current.namaGenerik} + ${other.namaGenerik}: ${data['txt']}');
          }
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
      appBar: AppBar(title: const Text('Cek Interaksi Clinical')),
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
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F8E9), // green.shade50
        border: Border(bottom: BorderSide(color: Color(0xFFC8E6C9))), // green.shade100
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.green, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aplikasi memindai database 20k+ obat menggunakan Pharmacological Class-Matrix v1.0.',
              style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
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
        children: [
          Icon(Icons.medication_liquid, size: 100, color: Colors.green.shade50),
          const SizedBox(height: 16),
          Text('Belum ada obat dipilih.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
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
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Hero(
              tag: 'med-${medicine.id}',
              child: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.medication, color: Colors.green, size: 20),
              ),
            ),
            title: Text(medicine.namaGenerik, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(medicine.kelasTerapi ?? medicine.golongan ?? '-'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeMedicine(medicine.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningPanel() {
    if (_selectedMedicines.length == 1 && !_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.blue.shade50,
        child: const Text(
          '💡 Pilih satu obat lagi untuk memindai interaksi.',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_interactionWarnings.isEmpty && _selectedMedicines.length >= 2 && !_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.green.shade50,
        child: const Text(
          '✅ Tidak ditemukan interaksi spesifik di database.',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_interactionWarnings.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TEMUAN KLINIS HYPER-SUPREME:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ..._interactionWarnings.map((warningStr) {
              final parts = warningStr.split('|');
              final severity = parts[0];
              final msg = parts[1];
              
              Color color = Colors.blue;
              IconData icon = Icons.info_outline;
              if (severity == 'MAJOR') { color = Colors.red; icon = Icons.report; }
              if (severity == 'MODERATE') { color = Colors.orange; icon = Icons.warning_amber; }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(severity, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(msg, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMedicinePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final medicines = ref.watch(interactionMedicineListProvider);
            return Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari 20.565+ obat...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (val) => ref.read(interactionSearchQueryProvider.notifier).state = val,
                  ),
                ),
                Expanded(
                  child: medicines.when(
                    data: (list) => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final m = list[index];
                        final isSelected = _selectedMedicines.any((sel) => sel.id == m.id);
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(m.namaGenerik, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(m.namaDagang ?? '-'),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade50,
                            child: Text(m.kategoriKehamilan ?? '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.add_circle_outline, color: Colors.grey),
                          onTap: () {
                            if (!isSelected) _addMedicine(m);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Gagal memuat data pencarian')),
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
