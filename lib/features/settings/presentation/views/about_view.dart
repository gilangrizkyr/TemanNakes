import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:temannakes/core/theme/app_theme.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Image.asset('assets/images/logo.png', width: 100, height: 100),
            const SizedBox(height: 20),
            const Text(
              'TemanNakes',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'Zenith Edition V1.0 — Production Ready',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildInfoSection(
              title: 'Misi & Visi',
              content: 'Asisten Klinis Terintegrasi untuk Tenaga Kesehatan Profesional Indonesia. TemanNakes menghadirkan referensi obat komprehensif, kalkulator medis presisi tinggi, dan efisiensi manajemen data pasien dalam satu platform luring yang andal.',
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              title: 'Sumber Data (Medical Sourcing)',
              content: '• Data Obat: Diolah dari referensi publik resmi BPOM RI, MIMS Indonesia, dan literatur Farmakope.\n'
                       '• Kalkulator Medis: Formula merujuk pada standar klinis internasional (WHO, KDIGO, JNC) serta konsensus spesialis terkait di Indonesia.',
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              title: 'Sanggahan Klinis (Medical Disclaimer)',
              content: 'TemanNakes adalah alat bantu keputusan klinis (Clinical Decision Support Tool) dan BUKAN pengganti penilaian klinis profesional. '
                       'Selalu verifikasi dosis dan rencana terapi dengan panduan resmi institusi Anda serta penilaian fisik pasien secara langsung. '
                       'Akurasi kalkulasi telah diaudit secara ketat namun tetap bergantung pada keakuratan input data pengguna.',
              isWarning: true,
            ),
            const SizedBox(height: 48),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Versi ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Dibuat dengan ❤️ untuk Nakes Indonesia',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isWarning ? Colors.red : AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isWarning ? Colors.red[900] : Colors.black87,
            fontStyle: isWarning ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}
