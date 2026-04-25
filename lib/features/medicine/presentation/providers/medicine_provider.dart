import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/medicine.dart';

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filter Providers
final categoryFilterProvider = StateProvider<String>((ref) => 'Semua');
final formFilterProvider = StateProvider<String>((ref) => 'Semua');

// Search Results Provider (with automatic debouncing via watch)
final medicineListProvider = FutureProvider<List<MedicineSimple>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(categoryFilterProvider);
  final form = ref.watch(formFilterProvider);
  
  return await DatabaseHelper.instance.searchMedicines(
    query, 
    category: category, 
    form: form,
  );
});

// ISOLATED SEARCH for Interaction Checker (to prevent global search interference)
final interactionSearchQueryProvider = StateProvider<String>((ref) => '');

final interactionMedicineListProvider = FutureProvider<List<MedicineSimple>>((ref) async {
  final query = ref.watch(interactionSearchQueryProvider);
  return await DatabaseHelper.instance.searchMedicines(query);
});

// Trending Medicines - each searched separately to avoid FTS AND-match returning zero
final trendingMedicinesProvider = FutureProvider<List<MedicineSimple>>((ref) async {
  const topDrugs = ['Amoxicillin', 'Paracetamol', 'Amlodipine', 'Metformin', 'Omeprazole'];
  final results = <MedicineSimple>[];
  for (final drug in topDrugs) {
    final found = await DatabaseHelper.instance.searchMedicines(drug);
    if (found.isNotEmpty) results.add(found.first);
  }
  return results;
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
