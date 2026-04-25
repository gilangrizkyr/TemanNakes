import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
// import 'home_search_view.dart';
import '../widgets/medicine_list_tile.dart';

class CategoryListView extends ConsumerWidget {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Penyakit')),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: const Icon(Icons.category_outlined, color: Color(0xFF2E7D32)),
              title: Text(cat['nama']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailView(
                      categoryId: cat['id'],
                      categoryName: cat['nama'],
                    ),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class CategoryDetailView extends ConsumerWidget {
  final int categoryId;
  final String categoryName;

  const CategoryDetailView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(categoryMedicinesProvider(categoryId));

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: medicinesAsync.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('Tidak ada obat di kategori ini.'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => ProjectMedicineListTile(medicine: list[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
