import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medicine_provider.dart';
import '../widgets/medicine_list_tile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temannakes/core/services/ad_service.dart';

class CategoryListView extends ConsumerStatefulWidget {
  const CategoryListView({super.key});

  @override
  ConsumerState<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends ConsumerState<CategoryListView> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() async {
    final isOnline = await AdService().isOnline();
    if (!isOnline) return;

    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() => _isBannerLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('BannerAd failed: $error');
        if (!mounted) return;
        setState(() => _isBannerLoaded = false);
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Penyakit')),
      body: Column(
        children: [
          Expanded(
            child: categoriesAsync.when(
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
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryDetailView extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryDetailView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends ConsumerState<CategoryDetailView> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() async {
    final isOnline = await AdService().isOnline();
    if (!isOnline) return;

    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() => _isBannerLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('BannerAd failed: $error');
        if (!mounted) return;
        setState(() => _isBannerLoaded = false);
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
    final medicinesAsync = ref.watch(categoryMedicinesProvider(widget.categoryId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: Column(
        children: [
          Expanded(
            child: medicinesAsync.when(
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
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}
