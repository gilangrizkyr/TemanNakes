import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temannakes/core/services/ad_service.dart';

/// [STAGE 2 — REVENUE ENGINE]
/// Reusable banner widget khusus untuk layar hasil kalkulator.
/// 
/// Ditempatkan SETELAH CalcResultCard — posisi dengan dwell time tinggi (30-60 detik)
/// karena Nakes sedang membaca & menganalisis hasil kalkulasi.
/// 
/// Features:
/// - Self-contained: manage banner lifecycle sendiri
/// - 3-attempt retry dengan exponential backoff
/// - Cache guard: tidak reload banner yang sudah hidup
/// - Auto-dispose saat widget unmount
class CalcBannerAdWidget extends StatefulWidget {
  const CalcBannerAdWidget({super.key});

  @override
  State<CalcBannerAdWidget> createState() => _CalcBannerAdWidgetState();
}

class _CalcBannerAdWidgetState extends State<CalcBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Start loading after first frame — result card is already visible
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  Future<void> _loadBanner({int attempt = 1}) async {
    const maxAttempts = 3;
    if (_isLoaded) return; // Cache guard

    final isOnline = await AdService().isOnline();
    if (!isOnline || !mounted) return;

    _bannerAd?.dispose();
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (!mounted) { ad.dispose(); return; }
        setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        if (!mounted) return;
        setState(() => _isLoaded = false);
        if (attempt < maxAttempts) {
          Future.delayed(Duration(seconds: attempt == 1 ? 3 : 8), () {
            if (mounted && !_isLoaded) _loadBanner(attempt: attempt + 1);
          });
        }
      },
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
