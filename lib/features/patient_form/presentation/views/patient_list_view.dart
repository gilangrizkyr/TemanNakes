import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/form_template.dart';
import '../../domain/models/patient_record.dart';
import '../providers/patient_form_provider.dart';
import 'patient_input_view.dart';
import 'patient_detail_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temannakes/core/services/ad_service.dart';

/// Daftar semua data pasien dengan search & filter
class PatientListView extends ConsumerStatefulWidget {
  const PatientListView({super.key});

  @override
  ConsumerState<PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends ConsumerState<PatientListView> {
  final _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(patientRecordsProvider);
    final templatesAsync = ref.watch(formTemplatesProvider);
    final selectedForm = ref.watch(recordFormFilterProvider);
    final fromDate = ref.watch(recordFromDateProvider);
    final toDate = ref.watch(recordToDateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Data Pasien'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, templatesAsync),
          ),
        ],
      ),
      floatingActionButton: templatesAsync.when(
        data: (templates) => templates.isEmpty
            ? null
            : FloatingActionButton.extended(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Data'),
                onPressed: () => _selectForm(context, templates),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(recordSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Cari data pasien...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(recordSearchProvider.notifier).state = '';
                        })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Active filters indicator
          if (selectedForm.isNotEmpty || fromDate != null || toDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Filter aktif', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero),
                    onPressed: () {
                      ref.read(recordFormFilterProvider.notifier).state = '';
                      ref.read(recordFromDateProvider.notifier).state = null;
                      ref.read(recordToDateProvider.notifier).state = null;
                    },
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: recordsAsync.when(
              data: (records) => records.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: records.length,
                      itemBuilder: (context, i) =>
                          _buildRecordCard(context, ref, records[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada data pasien',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, WidgetRef ref, PatientRecord record) {
    final d = record.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

    // Show first 2 non-empty values as preview
    final preview = record.values.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .take(2)
        .map((e) => e.value.toString())
        .join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00695C).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Color(0xFF00695C)),
        ),
        title: Text(record.formName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.isNotEmpty)
              Text(preview,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              // Need the template to edit
              final templates = ref.read(formTemplatesProvider).value ?? [];
              final template = templates.firstWhere(
                  (t) => t.id == record.formId,
                  orElse: () => FormTemplate(
                      id: record.formId,
                      name: record.formName,
                      fields: [],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now()));
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PatientInputView(template: template, existingRecord: record)));
              ref.invalidate(patientRecordsProvider);
            } else if (action == 'delete') {
              _confirmDelete(context, ref, record);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red)))),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showDetail(context, ref, record),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, PatientRecord record) {
    final templates = ref.read(formTemplatesProvider).value ?? [];
    final template = templates.firstWhere((t) => t.id == record.formId,
        orElse: () => FormTemplate(
            id: record.formId,
            name: record.formName,
            fields: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailView(record: record, template: template)),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PatientRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data ini?'),
        content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(patientRecordsNotifierProvider.notifier).deleteRecord(record.id);
              ref.invalidate(patientRecordsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectForm(BuildContext context, List<FormTemplate> templates) async {
    if (templates.length == 1) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => PatientInputView(template: templates.first)));
      ref.invalidate(patientRecordsProvider);
      return;
    }
    final selected = await showModalBottomSheet<FormTemplate>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Form', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ...templates.map((t) => ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.fields.length} field'),
                  leading: const Icon(Icons.dynamic_form),
                  onTap: () => Navigator.pop(context, t),
                )),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => PatientInputView(template: selected)));
      ref.invalidate(patientRecordsProvider);
    }
  }

  void _showFilterSheet(BuildContext context, AsyncValue<List<FormTemplate>> templatesAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _FilterSheet(templatesAsync: templatesAsync),
    );
  }
}

// ─── Filter Sheet ────────────────────────────────────────────────────────────
class _FilterSheet extends ConsumerStatefulWidget {
  final AsyncValue<List<FormTemplate>> templatesAsync;
  const _FilterSheet({required this.templatesAsync});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  @override
  Widget build(BuildContext context) {
    final selectedForm = ref.watch(recordFormFilterProvider);
    final fromDate = ref.watch(recordFromDateProvider);
    final toDate = ref.watch(recordToDateProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          // Form filter
          widget.templatesAsync.when(
            data: (templates) => DropdownButtonFormField<String>(
              value: selectedForm.isEmpty ? null : selectedForm,
              decoration: const InputDecoration(
                  labelText: 'Form', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: '', child: Text('Semua Form')),
                ...templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
              ],
              onChanged: (v) => ref.read(recordFormFilterProvider.notifier).state = v ?? '',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          // Date range
          Row(
            children: [
              Expanded(
                child: _DatePicker(
                  label: 'Dari Tanggal',
                  value: fromDate,
                  onChanged: (d) => ref.read(recordFromDateProvider.notifier).state = d,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePicker(
                  label: 'Sampai Tanggal',
                  value: toDate,
                  onChanged: (d) => ref.read(recordToDateProvider.notifier).state = d,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(recordFormFilterProvider.notifier).state = '';
                    ref.read(recordFromDateProvider.notifier).state = null;
                    ref.read(recordToDateProvider.notifier).state = null;
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePicker({required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(value != null
                  ? '${value!.day.toString().padLeft(2,'0')}-${value!.month.toString().padLeft(2,'0')}-${value!.year}'
                  : 'Pilih', style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}
