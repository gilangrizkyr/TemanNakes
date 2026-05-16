import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/medicine/presentation/views/home_search_view.dart';
import 'core/services/ad_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // V6.0: Initialize AdMob in background to prevent startup jank
  AdService().initialize();

  // Smart Notification System: init + return-user trigger
  NotificationService.instance.initialize();
  NotificationService.instance.onAppOpen(); // checks if user was absent >= 3 days

  runApp(
    const ProviderScope(
      child: TemanNakesApp(),
    ),
  );
}

class TemanNakesApp extends StatefulWidget {
  const TemanNakesApp({super.key});

  @override
  State<TemanNakesApp> createState() => _TemanNakesAppState();
}

class _TemanNakesAppState extends State<TemanNakesApp> {
  @override
  void initState() {
    super.initState();
    // Initial load for App Open Ad (Ready for Disclaimer transition)
    AppOpenAdManager().loadAd();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TemanNakes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorObservers: [GlobalFocusObserver()],
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // V7.3: Global Double-Kill (Tap)
            FocusManager.instance.primaryFocus?.unfocus();
            FocusScope.of(context).requestFocus(FocusNode());
          },
          onVerticalDragStart: (_) {
            // V7.3: Global Double-Kill (Drag)
            FocusManager.instance.primaryFocus?.unfocus();
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                // V7.2: Global Unfocus on Scroll for EVERY page in the app
                FocusManager.instance.primaryFocus?.unfocus();
              }
              return false;
            },
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DisclaimerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 140, height: 140),
            const SizedBox(height: 24),
            Text(
              'TemanNakes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asisten Klinis Terintegrasi & Luring',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'PENTING',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aplikasi ini hanya sebagai alat bantu dan bukan pengganti keputusan medis profesional. Selalu verifikasi dosis dan interaksi obat dengan standar medis yang berlaku.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // V7.0: Move to dedicated Ad Transition Page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdTransitionPage()),
                    );
                  },
                  child: const Text('SAYA MENGERTI & LANJUTKAN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [V7.0] Dedicated Ad Transition Page
/// Provides a clean, professional space for App Open Ads during entry flow.
class AdTransitionPage extends StatefulWidget {
  const AdTransitionPage({super.key});

  @override
  State<AdTransitionPage> createState() => _AdTransitionPageState();
}

class _AdTransitionPageState extends State<AdTransitionPage> {
  @override
  void initState() {
    super.initState();
    _triggerAdFlow();
  }

  void _triggerAdFlow() {
    // Small delay to let the page settle
    Future.delayed(const Duration(milliseconds: 300), () {
      AppOpenAdManager().showAdIfAvailable(
        onComplete: () {
          if (mounted) {
            _navigateToHome();
          }
        },
      );
    });

    // Safety Timeout: If ad fails or takes too long, continue to home
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeSearchView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E), // Dark professional background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              strokeWidth: 2,
            ),
            const SizedBox(height: 32),
            Text(
              'Menyiapkan Layanan...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [V7.2] Global Navigator Observer to kill focus on any transition
/// This ensures Swipe Back or Push always cleans up the blinking cursor "|"
class GlobalFocusObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _forceUnfocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _forceUnfocus();
  }

  void _forceUnfocus() {
    // V7.3: Double-Kill Focus Strategy (Global)
    FocusManager.instance.primaryFocus?.unfocus();
    // Use a small delay if needed or direct requestFocus
    // For Observer, FocusManager is usually enough, but let's be aggressive
  }
}
