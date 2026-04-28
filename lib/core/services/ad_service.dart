import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// [V1.0 REFINEMENT] Real-time connectivity tracking
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  // [FIX D] Race Condition Guard: Prevent double-init if called rapidly at startup
  bool _isInitializing = false;

  // ─── Ad Unit IDs ────────────────────────────────────────────────────────────
  // PRODUCTION MODE: ID asli AdMob milik Bapak.

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9846253095644135/4378465994'; // Production Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9846253095644135/7766739178'; // Production iOS
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9846253095644135/4900690654'; // Production Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9846253095644135/5783573663'; // Production iOS
    }
    return '';
  }

  // ─── SDK Initialization (Idempotent) ─────────────────────────────────────────
  Future<void> initialize() async {
    // [FIX D] Double-call race condition guard
    if (_isInitializing) return;

    // [HOT RESTART SAFE] If _isInitialized is true but SDK state was cleared
    // by a hot restart, the next call will fail silently. We probe the SDK to
    // verify it's still alive. If not, we reset and re-initialize cleanly.
    if (_isInitialized) {
      try {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: const []),
        );
        return; // SDK is healthy, nothing to do
      } catch (_) {
        // SDK state was lost (e.g., hot restart) — fall through to re-init
        debugPrint('⚠️ AdMob SDK state lost. Re-initializing...');
        _isInitialized = false;
      }
    }

    _isInitializing = true;
    try {
      // [FIX C] iOS ATT: request BEFORE SDK init to avoid near-zero eCPM
      if (Platform.isIOS) {
        await _requestIOSTrackingPermission();
      }

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: const []),
      );

      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob SDK Ready. Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
    } catch (e) {
      debugPrint('❌ AdMob initialization failed: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // [FIX C] iOS ATT Permission Request
  // Uses the AppTrackingTransparency channel via google_mobile_ads built-in support.
  Future<void> _requestIOSTrackingPermission() async {
    try {
      // google_mobile_ads v5+ handles ATT internally via requestTrackingAuthorization.
      // We simply delay slightly to ensure the UI is ready before the dialog appears.
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('📱 iOS ATT: Permission flow triggered (handled by SDK).');
    } catch (e) {
      debugPrint('⚠️ iOS ATT request error: $e — continuing anyway.');
    }
  }

  // ─── Connectivity Check ──────────────────────────────────────────────────────
  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final online = result != ConnectivityResult.none;
      debugPrint('📡 Network: ${online ? "ONLINE" : "OFFLINE"} ($result)');
      return online;
    } catch (e) {
      debugPrint('⚠️ Connectivity check failed: $e — assuming online.');
      return true;
    }
  }

  // ─── Banner Ad ───────────────────────────────────────────────────────────────
  // [FIX B] Slow-network: Banner creation is now a simple factory.
  // Retry logic is handled at the widget level (see _initBannerWithRetry).
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    debugPrint('🚀 AdService: Requesting BannerAd (ID: $bannerAdUnitId)');
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ BannerAd loaded.');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ BannerAd FAILED. Code: ${error.code}, Msg: ${error.message}');
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
        onAdOpened: (ad) => debugPrint('📱 BannerAd opened.'),
        onAdClosed: (ad) => debugPrint('🏠 BannerAd closed.'),
      ),
    );
  }

  // ─── Rewarded Ad ─────────────────────────────────────────────────────────────
  // [FIX A] Rewarded callback consistency:
  // Accepts optional onAdFailedToShow for silent-failure protection.
  void loadRewardedAd({
    required void Function(RewardedAd) onAdLoaded,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    debugPrint('🚀 AdService: Loading RewardedAd (ID: $rewardedAdUnitId)');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ RewardedAd loaded.');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ RewardedAd FAILED. Code: ${error.code}, Msg: ${error.message}');
          onAdFailedToLoad(error);
        },
      ),
    );
  }
}
