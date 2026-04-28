import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/medicine.dart';

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filter Providers
final categoryFilterProvider = StateProvider<String>((ref) => 'Semua');
final formFilterProvider = StateProvider<String>((ref) => 'Semua');

// Search Results Provider — dengan debounce 350ms agar tidak query DB setiap ketukan
final medicineListProvider = FutureProvider<List<MedicineSimple>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(categoryFilterProvider);
  final form = ref.watch(formFilterProvider);

  // [PERF FIX] Debounce 350ms: tunggu user berhenti mengetik sebelum query ke DB
  await Future.delayed(const Duration(milliseconds: 350));

  // Jika state berubah selama delay, batalkan request ini
  final currentQuery = ref.read(searchQueryProvider);
  final currentCategory = ref.read(categoryFilterProvider);
  final currentForm = ref.read(formFilterProvider);
  if (currentQuery != query || currentCategory != category || currentForm != form) {
    return [];
  }

  return await DatabaseHelper.instance.searchMedicines(
    query,
    category: category,
    form: form,
  );
});

// ISOLATED SEARCH for Interaction Checker
final interactionSearchQueryProvider = StateProvider<String>((ref) => '');

final interactionMedicineListProvider = FutureProvider<List<MedicineSimple>>((ref) async {
  final query = ref.watch(interactionSearchQueryProvider);
  await Future.delayed(const Duration(milliseconds: 300));
  final current = ref.read(interactionSearchQueryProvider);
  if (current != query) return [];
  return await DatabaseHelper.instance.searchMedicines(query);
});

// [PERF FIX] Trending Medicines — satu query batch, bukan 5 query serial
final trendingMedicinesProvider = FutureProvider<List<MedicineSimple>>((ref) async {
  return await DatabaseHelper.instance.getTrendingMedicines();
});

// Medicine Detail Provider (Auto-disposing to save memory)
final medicineDetailProvider = FutureProvider.autoDispose.family<MedicineDetail?, int>((ref, id) async {
  return await DatabaseHelper.instance.getMedicineDetail(id);
});

// Medicines by Category Provider
final categoryMedicinesProvider = FutureProvider.family<List<MedicineSimple>, int>((ref, categoryId) async {
  return await DatabaseHelper.instance.getMedicinesByCategory(categoryId);
});

// Favorites Provider (SQLite Persistent)
class FavoritesNotifier extends StateNotifier<AsyncValue<List<MedicineSimple>>> {
  FavoritesNotifier() : super(const AsyncValue.loading()) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = const AsyncValue.loading();
    try {
      final list = await DatabaseHelper.instance.getFavorites();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(int id) async {
    await DatabaseHelper.instance.toggleFavorite(id);
    _loadFavorites();
  }

  bool isFavorite(int id) {
    return state.when(
      data: (list) => list.any((m) => m.id == id),
      error: (_, __) => false,
      loading: () => false,
    );
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<MedicineSimple>>>((ref) {
  return FavoritesNotifier();
});

// [PERF FIX] Atomized Favorite Provider: 
// Hanya men-trigger rebuild untuk Tile yang ID-nya berubah, bukan seluruh list.
final isFavoriteProvider = Provider.family<bool, int>((ref, id) {
  return ref.watch(favoritesProvider).when(
    data: (list) => list.any((m) => m.id == id),
    loading: () => false,
    error: (_, __) => false,
  );
});

// Categories Provider
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getCategories();
});

// Search History Provider
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]);

  void add(String query) {
    if (query.isEmpty) return;
    state = [query, ...state.where((q) => q != query)].take(10).toList();
  }

  void clear() => state = [];
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});
