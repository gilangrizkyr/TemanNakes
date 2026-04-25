import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannakes/features/medicine/presentation/providers/medicine_provider.dart';
import 'package:temannakes/features/medicine/presentation/widgets/medicine_list_tile.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Obat Favorit')),
      body: favoritesAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada obat favorit.'));
          }
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
