import 'package:flutter/material.dart';

void main() {
  runApp(const TemanNakesDemo());
}

class TemanNakesDemo extends StatelessWidget {
  const TemanNakesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teman Nakes Live Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeView(),
    );
  }
}

// --- MODELS ---
class Medicine {
  final int id;
  final String namaGenerik;
  final String namaDagang;
  final String golongan;
  final String indikasi;
  final String dosisDewasa;
  final String dosisAnak;
  final String satuan;
  final String frekuensi;
  final String peringatan;
  final String interaksi;

  Medicine({
    required this.id,
    required this.namaGenerik,
    required this.namaDagang,
    required this.golongan,
    required this.indikasi,
    required this.dosisDewasa,
    required this.dosisAnak,
    required this.satuan,
    required this.frekuensi,
    required this.peringatan,
    required this.interaksi,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      namaGenerik: map['nama_generik'],
      namaDagang: map['nama_dagang'] ?? '-',
      golongan: map['golongan'],
      indikasi: map['indikasi'] ?? '-',
      dosisDewasa: map['dosis_dewasa'] ?? '-',
      dosisAnak: map['dosis_anak'] ?? '-',
      satuan: map['satuan'] ?? 'mg',
      frekuensi: map['frekuensi'] ?? '-',
      peringatan: map['peringatan'] ?? '-',
      interaksi: map['interaksi'] ?? '-',
    );
  }
}

// --- DATA ---
const List<Map<String, dynamic>> rawMedicines = [
  {"id": 1, "nama_generik": "Paracetamol", "nama_dagang": "Sanmol, Panadol, Tempra", "sinonim": "Acetaminophen", "kode": "K001", "golongan": "Analgesik & Antipiretik", "indikasi": "Demam, nyeri ringan-sedang", "dosis_dewasa": "500-1000 mg", "dosis_anak": "10-15 mg/kgBB", "satuan": "mg", "frekuensi": "3-4x sehari", "peringatan": "Hati-hati ginjal", "interaksi": "Alkohol (toksik)"},
  {"id": 2, "nama_generik": "Antalgin", "nama_dagang": "Metampiron, Novalgin", "sinonim": "Methampyrone", "kode": "K002", "golongan": "Analgesik & Antipiretik", "indikasi": "Nyeri hebat, kolik", "dosis_dewasa": "500-1000 mg", "dosis_anak": "Tidak disarankan", "satuan": "mg", "frekuensi": "3x sehari", "peringatan": "Risiko darah", "interaksi": "Alkohol"},
  {"id": 3, "nama_generik": "Ibuprofen", "nama_dagang": "Proris, Ibuprofen", "sinonim": "IBU", "kode": "K003", "golongan": "NSAID", "indikasi": "Nyeri, demam, radang", "dosis_dewasa": "200-400 mg", "dosis_anak": "5-10 mg/kgBB", "satuan": "mg", "frekuensi": "3-4x sehari", "peringatan": "Ggn ginjal", "interaksi": "Warfarin, Aspirin"},
  {"id": 14, "nama_generik": "Amoxicillin", "nama_dagang": "Amoxisan", "sinonim": "Amoxycillin", "kode": "K014", "golongan": "Antibiotik", "indikasi": "Infeksi bakteri", "dosis_dewasa": "250-500 mg", "dosis_anak": "20-90 mg/kg", "satuan": "mg", "frekuensi": "3x sehari", "peringatan": "Habiskan antibiotik", "interaksi": "Probenecid"},
  {"id": 35, "nama_generik": "Amlodipine", "nama_dagang": "Norvask, Amlogard", "sinonim": "Amlodipine", "kode": "K035", "golongan": "Kardiovaskular", "indikasi": "Hipertensi, Angina", "dosis_dewasa": "5-10 mg", "dosis_anak": "-", "satuan": "mg", "frekuensi": "1x sehari", "peringatan": "Monitor TD", "interaksi": "Simvastatin"},
  // (Simplified for demo stability, but fully functional logic)
];

// --- VIEWS ---
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _searchController = TextEditingController();
  List<Medicine> _results = rawMedicines.map((m) => Medicine.fromMap(m)).toList();

  void _search(String query) {
    setState(() {
      _results = rawMedicines
          .where((m) =>
              m['nama_generik'].toLowerCase().contains(query.toLowerCase()) ||
              m['nama_dagang'].toLowerCase().contains(query.toLowerCase()))
          .map((m) => Medicine.fromMap(m))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teman Nakes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari obat...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final m = _results[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.medication)),
              title: Text(m.namaGenerik, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${m.golongan} • ${m.namaDagang}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailView(medicine: m))),
            ),
          );
        },
      ),
    );
  }
}

class DetailView extends StatelessWidget {
  final Medicine medicine;
  const DetailView({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(medicine.namaGenerik)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection(Icons.info, 'Indikasi', medicine.indikasi, Colors.blue),
            _buildSection(Icons.person, 'Dosis Dewasa', medicine.dosisDewasa, Colors.teal),
            _buildSection(Icons.child_care, 'Dosis Anak', medicine.dosisAnak, Colors.orange),
            _buildSection(Icons.warning, 'Peringatan', medicine.peringatan, Colors.brown),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoseCalculatorView(medicine: medicine))),
        label: const Text('Kalkulator Dosis'),
        icon: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, String content, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class DoseCalculatorView extends StatefulWidget {
  final Medicine medicine;
  const DoseCalculatorView({super.key, required this.medicine});

  @override
  State<DoseCalculatorView> createState() => _DoseCalculatorViewState();
}

class _DoseCalculatorViewState extends State<DoseCalculatorView> {
  final _weightController = TextEditingController();
  String _result = '-';

  void _calculate() {
    final w = double.tryParse(_weightController.text) ?? 0;
    if (w <= 0) {
      setState(() => _result = '-');
      return;
    }
    double min = 10, max = 15;
    final match = RegExp(r'(\d+)-(\d+)').firstMatch(widget.medicine.dosisAnak);
    if (match != null) {
      min = double.parse(match.group(1)!);
      max = double.parse(match.group(2)!);
    }
    setState(() {
      _result = '${(w * min).toStringAsFixed(1)} - ${(w * max).toStringAsFixed(1)} ${widget.medicine.satuan}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Dosis')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Berat Badan (kg)', border: OutlineInputBorder()),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('DOSIS AMAN:'),
                  Text(_result, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(widget.medicine.frekuensi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
