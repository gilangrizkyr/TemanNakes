import 'package:flutter/material.dart';
import 'package:temannakes/core/theme/app_theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Terakhir Diperbarui: 27 April 2026',
              'TemanNakes sangat menghargai privasi Anda. Halaman ini menjelaskan bagaimana kami mengelola data Anda.',
            ),
            const Divider(),
            _buildSection(
              '1. Pengumpulan Data Pribadi',
              'Aplikasi TemanNakes tidak mengumpulkan data pribadi identitas (seperti nama, NIK, atau lokasi) dari pengguna. Seluruh data rekam medis pasien yang Anda masukkan disimpan secara offline di perangkat Anda sendiri dan tidak dikirim ke server kami.',
            ),
            _buildSection(
              '2. Layanan Pihak Ketiga (Google AdMob)',
              'Kami menggunakan layanan pihak ketiga yaitu Google AdMob untuk menampilkan iklan. '
                  'Google AdMob dapat mengumpulkan informasi tertentu secara otomatis untuk meningkatkan kualitas layanan dan menampilkan iklan yang relevan, termasuk namun tidak terbatas pada:\n'
                  '• ID perangkat (Device ID)\n'
                  '• Data penggunaan aplikasi\n'
                  '• Informasi jaringan dan koneksi\n'
                  '• Alamat IP\n\n'
                  'Informasi tersebut dikelola langsung oleh Google dan tunduk pada kebijakan privasi Google. '
                  'Untuk informasi lebih lanjut, silakan kunjungi: https://policies.google.com/privacy',
            ),
            _buildSection(
              '3. Konektivitas Internet',
              'Iklan hanya akan ditampilkan saat perangkat terhubung ke internet. Aplikasi tetap berfungsi penuh secara offline tanpa mengganggu fitur yang sudah disediakan oleh aplikasi.',
            ),
            _buildSection(
              '4. Hak Pengguna',
              'Dengan menggunakan aplikasi ini, Anda setuju dengan pengumpulan data teknis oleh Google AdMob sesuai dengan kebijakan privasi Google.',
            ),
            _buildSection(
              '5. Penyimpanan Data',
              'Semua data yang dimasukkan oleh pengguna, termasuk data pasien dan laporan, disimpan secara lokal di perangkat pengguna. '
              'Aplikasi TemanNakes tidak mengirimkan data tersebut ke server mana pun.',
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'TemanNakes Pinnacle © 2026',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
