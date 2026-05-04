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



// Medicine Detail Provider (Auto-disposing to save memory)
final medicineDetailProvider = FutureProvider.autoDispose.family<MedicineDetail?, int>((ref, id) async {
  return await DatabaseHelper.instance.getMedicineDetail(id);
});

// Medicines by Category Provider
final categoryMedicinesProvider = FutureProvider.family<List<MedicineSimple>, int>((ref, categoryId) async {
  return await DatabaseHelper.instance.getMedicinesByCategory(categoryId);
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
