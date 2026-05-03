import 'package:shared_preferences/shared_preferences.dart';

/// [SMART NOTIFICATION SYSTEM — LAYER 1]
/// Silent behavioral tracker. No UI required by user.
///
/// Runs silently every time a calculator feature is used.
/// Derives user segment (IGD, Bidan, General) from WEIGHTED usage pattern.
///
/// Feature Keys & Weights:
///   IGD-signal  : 'gcs'(3), 'map'(2), 'shock_index'(2)
///   Bidan-signal: 'hpl'(3), 'apgar'(3), 'tbj'(2), 'gestational_age'(1)
///   General     : 'dose'(1), 'renal_clcr'(1), 'renal_egfr'(1),
///                  'infus_drop'(1), 'infus_pump'(1)
///
/// Weighting ensures segment is stable even with sparse usage data:
///   Opening GCS once = 3 signal points vs opening dose once = 1 point

enum UserSegment { igd, bidan, general, unknown }

class UsageTracker {
  UsageTracker._();
  static final UsageTracker instance = UsageTracker._();

  static const _prefKey             = 'feature_usage_v1';
  static const _distinctFeaturesKey = 'distinct_features_v1';
  static const _notifActivatedKey   = 'notif_system_activated_v1';

  // ── Weighted feature map ──────────────────────────────────────────────────
  // IGD signals
  static const _igdWeights = <String, int>{
    'gcs': 3,
    'map': 2,
    'shock_index': 2,
  };

  // Bidan signals
  static const _bidanWeights = <String, int>{
    'hpl': 3,
    'apgar': 3,
    'tbj': 2,
    'gestational_age': 1,
    'kb_calculator': 2,
  };

  // General signals (also used to detect non-specialized users)
  static const _generalWeights = <String, int>{
    'dose': 1,
    'renal_clcr': 1,
    'renal_egfr': 1,
    'infus_drop': 1,
    'infus_pump': 1,
  };

  // ── Record feature use ────────────────────────────────────────────────────
  /// Call this (via NotificationService.onFeatureUsed) every time a feature
  /// screen is opened. Zero friction — runs fully async in background.
  Future<void> recordFeatureUse(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();

    // Increment count for this feature
    final current = prefs.getInt('$_prefKey.$featureKey') ?? 0;
    await prefs.setInt('$_prefKey.$featureKey', current + 1);

    // Track distinct features used (for the >= 3 activation trigger)
    final distinctRaw = prefs.getStringList(_distinctFeaturesKey) ?? [];
    final distinctSet = distinctRaw.toSet()..add(featureKey);
    await prefs.setStringList(_distinctFeaturesKey, distinctSet.toList());
  }

  // ── Distinct feature count ────────────────────────────────────────────────
  Future<int> get distinctFeaturesCount async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_distinctFeaturesKey) ?? []).length;
  }

  // ── Activation check ──────────────────────────────────────────────────────
  /// Returns true when notification system should activate.
  /// Trigger: >= 3 DIFFERENT features used (not same feature many times).
  Future<bool> get shouldActivateNotifications async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_notifActivatedKey) ?? false) return true;
    if (await distinctFeaturesCount >= 3) {
      await prefs.setBool(_notifActivatedKey, true);
      return true;
    }
    return false;
  }

  // ── Weighted segment derivation ───────────────────────────────────────────
  /// Derives segment from WEIGHTED usage — 2-layer confidence system:
  ///   Layer 1: total weighted score must exceed threshold (prevents noise)
  ///   Layer 2: segment confidence requires EITHER:
  ///     - 1 strong signal: single feature contributes >= 3 weighted points
  ///     - 2 medium signals: two features each contribute >= 2 weighted points
  ///
  /// Example: MAP clicked once → contribution = 1×2 = 2 → only medium, not confident.
  ///          GCS clicked once → contribution = 1×3 = 3 → strong signal → IGD confident.
  ///          MAP + Shock each once → 2+2 = 4, two mediums → IGD confident.
  Future<UserSegment> get derivedSegment async {
    final prefs = await SharedPreferences.getInstance();

    int igdTotal = 0;
    bool igdStrong = false;   // any single IGD feature contributed >= 3 pts
    int igdMediums = 0;       // count of IGD features contributing >= 2 pts

    int bidanTotal = 0;
    bool bidanStrong = false;
    int bidanMediums = 0;

    for (final entry in _igdWeights.entries) {
      final contribution = (prefs.getInt('$_prefKey.${entry.key}') ?? 0) * entry.value;
      igdTotal += contribution;
      if (contribution >= 3) igdStrong = true;
      if (contribution >= 2) igdMediums++;
    }

    for (final entry in _bidanWeights.entries) {
      final contribution = (prefs.getInt('$_prefKey.${entry.key}') ?? 0) * entry.value;
      bidanTotal += contribution;
      if (contribution >= 3) bidanStrong = true;
      if (contribution >= 2) bidanMediums++;
    }

    // Layer 2: confidence check
    final igdConfident   = igdStrong || igdMediums >= 2;
    final bidanConfident = bidanStrong || bidanMediums >= 2;

    // Classify only if confident
    if (igdConfident && bidanConfident) {
      return igdTotal >= bidanTotal ? UserSegment.igd : UserSegment.bidan;
    }
    if (igdConfident)   return UserSegment.igd;
    if (bidanConfident) return UserSegment.bidan;

    // Not confident enough → general (safe fallback)
    return UserSegment.general;
  }

  // ── Top feature ───────────────────────────────────────────────────────────
  /// Returns the single most-used feature key (for usage-based notif content).
  Future<String?> get topFeature async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = [
      ..._igdWeights.keys,
      ..._bidanWeights.keys,
      ..._generalWeights.keys,
    ];
    String? top;
    int maxCount = 0;
    for (final key in allKeys) {
      final count = prefs.getInt('$_prefKey.$key') ?? 0;
      if (count > maxCount) { maxCount = count; top = key; }
    }
    return top;
  }

  // ── Debug helper ──────────────────────────────────────────────────────────
  Future<Map<String, int>> get allUsage async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = [
      ..._igdWeights.keys,
      ..._bidanWeights.keys,
      ..._generalWeights.keys,
    ];
    return {for (final k in allKeys) k: prefs.getInt('$_prefKey.$k') ?? 0};
  }
}
