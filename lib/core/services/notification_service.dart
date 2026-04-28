import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_tracker.dart';

/// [SMART NOTIFICATION SYSTEM — LAYER 2 + 3]
/// NotificationService: event-based + context-aware + frequency-guarded.
///
/// Architecture:
///   onAppOpen()       — return user after >= 3 days absence (with context decay)
///   onFeatureUsed()   — main hook: tracks usage + requests permission at right moment
///   onExportComplete()— after user exports a patient report
///
/// Rules:
///   - Runtime permission requested after 3rd distinct feature use (NOT on install)
///   - Notifications ONLY activate after >= 3 distinct features used
///   - MAX 2 notif/week normally — drops to 1 if idle >= 7 days (context decay)
///   - Messages context-aware: UserSegment × shift hour
///   - Android-first. iOS follows after retention validation.
///
/// Wiring: Call [onFeatureUsed] in each calculator module's initState().
///         Call [onAppOpen] in main.dart.
///         Call [onExportComplete] after export success in report views.

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _weeklyCountKey    = 'notif_weekly_count_v1';
  static const _weekStartKey      = 'notif_week_start_v1';
  static const _permAskedKey      = 'notif_perm_asked_v1';
  static const _lastOpenKey       = 'last_open_timestamp';
  static const _reactivationKey   = 'reactivation_date_ms';
  static const _maxPerWeek        = 2;
  static const _permTriggerCount  = 3; // Request permission after 3 distinct features

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Android notification channel (silent — respectful of clinical env) ────
  static const _channel = AndroidNotificationChannel(
    'temannakes_smart',
    'TemanNakes — Pengingat Klinis',
    description: 'Notifikasi kontekstual berbasis pola penggunaan',
    importance: Importance.defaultImportance,
    showBadge: false,
    enableVibration: false,
    playSound: false,
  );

  // ── Initialize (called in main.dart) ──────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    _initialized = true;
    debugPrint('[NotificationService] Initialized (Android)');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT API
  // ══════════════════════════════════════════════════════════════════════════

  /// Main hook. Call in initState() of every calculator module.
  /// Handles:
  ///   1️⃣ UsageTracker recording
  ///   2️⃣ Permission request at the right moment (after 2nd feature)
  ///   3️⃣ Notification dispatch if activation threshold met
  Future<void> onFeatureUsed(String featureKey) async {
    await UsageTracker.instance.recordFeatureUse(featureKey);

    final distinct = await UsageTracker.instance.distinctFeaturesCount;

    // Step 1: After 2nd feature — soft-request permission (best UX moment)
    if (distinct >= _permTriggerCount) {
      await _requestPermissionIfNeeded();
    }

    // Step 2: After 3rd feature — system is "activated", try scheduling
    await _checkAndSchedule();
  }

  /// Event: user re-opens app after >= 3 days idle.
  /// Call this in main.dart on startup.
  Future<void> onAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenMs = prefs.getInt(_lastOpenKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSinceLastOpen = (now - lastOpenMs) ~/ (1000 * 60 * 60 * 24);
    await prefs.setInt(_lastOpenKey, now);

    // Detect long idle (>= 7 days) → start soft re-activation ramp
    if (daysSinceLastOpen >= 7 && lastOpenMs > 0) {
      // Only set reactivation date if not already in ramp period
      final existingRamp = prefs.getInt(_reactivationKey) ?? 0;
      if (existingRamp == 0) {
        await prefs.setInt(_reactivationKey, now);
      }
    }

    if (daysSinceLastOpen >= 3 && lastOpenMs > 0) {
      // Return users get warm re-entry copy, not a generic feature announcement
      final shouldActivate = await UsageTracker.instance.shouldActivateNotifications;
      if (shouldActivate && await _underWeeklyLimit()) {
        final payload = _returnUserPayload();
        await _sendNotification(payload.$1, payload.$2);
        await _incrementWeeklyCount();
      }
    }
  }

  /// Event: user completed an export.
  /// Call after successful PDF/XLS export in report views.
  Future<void> onExportComplete() async {
    final shouldActivate = await UsageTracker.instance.shouldActivateNotifications;
    if (!shouldActivate || !await _underWeeklyLimit()) return;

    final p = _pick(const [
      ('Laporan sudah siap. Kerja bagus. 📄', 'Tinggal dipakai untuk dokumentasi atau pelaporan.'),
      ('Export selesai ✅', 'Semua sudah dirangkum rapi — bisa langsung digunakan.'),
      ('Laporan siap 📋', 'Sudah tersimpan dan siap untuk dokumentasi shift.'),
    ]);
    await _sendNotification(p.$1, p.$2);
    await _incrementWeeklyCount();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INTERNAL: PERMISSION REQUEST
  // ══════════════════════════════════════════════════════════════════════════

  /// Requests POST_NOTIFICATIONS at the right moment (Android 13+).
  /// Only asks once. Never on first launch.
  Future<void> _requestPermissionIfNeeded() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_permAskedKey) ?? false;
    if (alreadyAsked) return;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Request permission (Android 13+ only — earlier versions auto-grant)
    final granted = await androidPlugin?.requestNotificationsPermission();
    await prefs.setBool(_permAskedKey, true);

    debugPrint('[NotificationService] Permission granted: $granted');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INTERNAL: SCHEDULING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _checkAndSchedule() async {
    final shouldActivate = await UsageTracker.instance.shouldActivateNotifications;
    if (!shouldActivate) return;
    if (!await _underWeeklyLimit()) return;

    final segment = await UsageTracker.instance.derivedSegment;
    final topFeature = await UsageTracker.instance.topFeature;
    final payload = _buildPayload(segment, topFeature);
    if (payload == null) return;

    await _sendNotification(payload.$1, payload.$2);
    await _incrementWeeklyCount();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INTERNAL: PAYLOAD BUILDER
  // Variants rotate by day-of-year — user sees different messages over time.
  // Principle: situation > feature | support > announcement | 1–2 sentences max
  // ══════════════════════════════════════════════════════════════════════════

  /// Day-based rotation — no randomness, stable & predictable.
  (String, String) _pick(List<(String, String)> variants) {
    final day = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return variants[day % variants.length];
  }

  /// Warm re-entry copy — warm-professional, no emoji overload.
  (String, String) _returnUserPayload() => _pick(const [
    ('Senang kamu kembali.', 'Kita lanjut bantu kerja lagi — semua alat klinis masih di sini seperti biasa.'),
    ('Shift sudah mulai lagi?', 'TemanNakes siap menemani. Semua kalkulator tersedia offline kapanpun.'),
    ('Selamat datang kembali.', 'Tinggal dibuka kapanpun dibutuhkan — tidak perlu koneksi internet.'),
  ]);

  (String, String)? _buildPayload(UserSegment segment, String? topFeature) {
    final hour = DateTime.now().hour;
    final isNightShift   = hour >= 19 || hour < 7;
    final isMorningShift = hour >= 7 && hour < 14;

    switch (segment) {
      case UserSegment.igd:
        if (isNightShift) {
          return _pick(const [
            ('Shift malam bisa sibuk.', 'Kalau ada yang tidak stabil, GCS, MAP, dan Shock Index sudah siap dipakai.'),
            ('Ada pasien kritis malam ini? 🫀', 'Butuh cek GCS atau MAP cepat? Semua bisa dihitung offline sekarang.'),
            ('TemanNakes siap menemani shift malam. 🚑', 'Emergency tools tersedia kapanpun — tidak perlu koneksi internet.'),
          ]);
        }
        return _pick(const [
          ('Ada pasien yang perlu asesmen? 🫀', 'GCS, MAP & Shock Index bisa dihitung langsung — tidak perlu internet.'),
          ('Ada yang tidak stabil hari ini?', 'Cek cepat lewat GCS, MAP, atau Shock Index — tanpa perlu koneksi.'),
          ('Butuh cek kondisi kritis? 🫀', 'TemanNakes siap membantu — semua emergency calculator tersedia offline.'),
        ]);

      case UserSegment.bidan:
        if (isMorningShift) {
          return _pick(const [
            ('Shift pagi biasanya padat. 🤰', 'HPL, APGAR & TBJ sudah siap — kalau ada yang perlu dihitung cepat.'),
            ('Ada pemeriksaan kehamilan hari ini?', 'HPL & Usia Kehamilan bisa langsung dicek — semua offline.'),
            ('Visite pagi? TemanNakes ikut bantu.', 'TBJ, APGAR, dan HPL siap digunakan kapanpun dibutuhkan.'),
          ]);
        }
        return _pick(const [
          ('Ada yang perlu dipantau hari ini? 🤰', 'HPL & APGAR siap membantu — kapanpun kamu butuh.'),
          ('Kalau ada persalinan hari ini,', 'TBJ dan APGAR sudah siap digunakan langsung — tanpa internet.'),
          ('TemanNakes ada kalau dibutuhkan.', 'Kalkulator kebidanan tersedia offline kapanpun di shift ini.'),
        ]);

      case UserSegment.general:
      case UserSegment.unknown:
        return _pick(const [
          ('Perlu hitung dosis cepat?', 'Kalkulator dosis, infus & fungsi ginjal tersedia offline — tanpa koneksi.'),
          ('💊 Lagi input obat atau infus?', 'Semua kalkulator klinis siap digunakan — tidak butuh koneksi internet.'),
          ('Biar lebih cepat.', 'Hitungan klinis bisa langsung di sini — dosis, infus, fungsi ginjal.'),
        ]);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INTERNAL: SEND + FREQUENCY GUARD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _sendNotification(String title, String body) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification'),
        styleInformation: BigTextStyleInformation(body),
        playSound: false,
        enableVibration: false,
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title,
      body,
      details,
    );
  }

  /// Soft re-activation ramp after long idle:
  ///   Day 0 (return day)  → 0 notif (complete silence, rebuilding trust)
  ///   Day 1 after return  → max 1 notif
  ///   Day 2+ after return → normal (max 2/week)
  ///
  /// Context decay only activates DURING the ramp window (first 2 days back).
  /// After day 2: weekly counter is reset and normal behavior resumes.
  Future<bool> _underWeeklyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final weekStartMs = prefs.getInt(_weekStartKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const weekMs  = 7 * 24 * 60 * 60 * 1000;
    const dayMs   = 1000 * 60 * 60 * 24;

    if (now - weekStartMs > weekMs) {
      await prefs.setInt(_weekStartKey, now);
      await prefs.setInt(_weeklyCountKey, 0);
      return true;
    }

    // Soft re-activation ramp
    final reactivationMs = prefs.getInt(_reactivationKey) ?? 0;
    if (reactivationMs > 0) {
      final daysSinceReactivation = (now - reactivationMs) ~/ dayMs;
      if (daysSinceReactivation == 0) return false;              // Day 0: complete silence
      if (daysSinceReactivation == 1) {                          // Day 1: max 1
        return (prefs.getInt(_weeklyCountKey) ?? 0) < 1;
      }
      if (daysSinceReactivation == 2) {                          // Day 2: max 2 (soft cap)
        return (prefs.getInt(_weeklyCountKey) ?? 0) < 2;
      }
      // Day 3+: ramp complete, user re-engaged → clear marker, resume normal
      await prefs.remove(_reactivationKey);
    }

    return (prefs.getInt(_weeklyCountKey) ?? 0) < _maxPerWeek;
  }

  Future<void> _incrementWeeklyCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weeklyCountKey, (prefs.getInt(_weeklyCountKey) ?? 0) + 1);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEGACY: kept for compatibility — calls onFeatureUsed internally
  // ══════════════════════════════════════════════════════════════════════════
  @Deprecated('Use onFeatureUsed(featureKey) instead')
  Future<void> checkAndSchedule() => _checkAndSchedule();
}
