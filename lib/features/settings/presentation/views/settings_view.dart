import 'package:flutter/material.dart';
import 'about_view.dart';
import 'privacy_policy_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: const Color(0xFF607D8B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildSettingsItem(
            context,
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi versi dan pengembang',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutView()),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Kebijakan Privasi',
            subtitle: 'Data dan keamanan pengguna',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Column(
              children: [
                const Text(
                  'Institutional Data Integrity Verified',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Developed by ',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      TextSpan(
                        text: 'GilangRizky',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF607D8B).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF607D8B)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
