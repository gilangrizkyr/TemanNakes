import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import '../../domain/models/form_template.dart';
import '../../domain/models/patient_record.dart';
import '../../export/excel_exporter.dart';
import '../../export/pdf_exporter.dart';
import '../providers/patient_form_provider.dart';
import 'package:temannakes/core/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Layar untuk memilih template laporan & export Excel/PDF
class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView>
    with WidgetsBindingObserver {
  FormTemplate? _selectedTemplate;
  ReportTemplate _reportTemplate = ReportTemplate.ringkas;
  DateTime? _fromDate;
  DateTime? _toDate;
  final _institutionCtrl = TextEditingController(text: 'Fasilitas Kesehatan');
  bool _isExporting = false;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // [V1.0 UX FIX] Reward-flag pattern:
  // Tandai reward yang diperoleh, lalu jalankan aksi SETELAH layar iklan tutup.
  bool _rewardEarned = false;
  VoidCallback? _pendingExportAction;

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer for reward flag persistence
    WidgetsBinding.instance.addObserver(this);
    _loadRewardedAd();
  }

  // [REWARD PERSISTENCE] Catch the app-minimize edge case:
  // On low-end devices, if user minimizes during a rewarded ad,
  // onAdDismissedFullScreenContent may fire before onUserEarnedReward.
  // When app returns to foreground (resumed), we check if reward was
  // earned but the export action is still pending, and execute it safely.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_rewardEarned && _pendingExportAction != null) {
        debugPrint('📱 App resumed: executing deferred reward export action.');
        final action = _pendingExportAction!;
        _pendingExportAction = null; // Clear first to prevent double-execution
        _rewardEarned = false;
        action();
      }
    }
  }

  // [RPM OPT] Rewarded Waterfall Preload:
  // Load BEFORE user clicks, not when they click. Max 3 silent background retries.
  // This ensures near-zero delay when user taps Export, maximizing rewarded RPM.
  void _loadRewardedAd({int attempt = 1}) async {
    const maxAttempts = 3;
    if (_isAdLoaded) return; // Already loaded, nothing to do

    final isOnline = await AdService().isOnline();
    if (!isOnline) {
      debugPrint('📵 ReportView: Offline — Rewarded preload skipped.');
      return;
    }

    debugPrint('🔄 ReportView: Preloading RewardedAd (attempt $attempt/$maxAttempts)...');
    AdService().loadRewardedAd(
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        debugPrint('✅ ReportView: RewardedAd PRELOADED & READY (attempt $attempt).');
        setState(() {
          _rewardedAd = ad;
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: (error) {
        debugPrint('⚠️ RewardedAd preload failed (attempt $attempt): ${error.message}');
        if (!mounted) return;
        setState(() => _isAdLoaded = false);

        // Silent background retry after 15s — user never feels this
        if (attempt < maxAttempts) {
          Future.delayed(const Duration(seconds: 15), () {
            if (mounted && !_isAdLoaded) _loadRewardedAd(attempt: attempt + 1);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up lifecycle observer
    _institutionCtrl.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(formTemplatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Laporan & Export'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Color(0xFF6A1B9A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Export berjalan sepenuhnya offline di perangkat ini.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6A1B9A))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('1. Pilih Form'),
            const SizedBox(height: 8),
            templatesAsync.when(
              data: (templates) => templates.isEmpty
                  ? const Center(child: Text('Belum ada form. Buat form terlebih dahulu.'))
                  : DropdownButtonFormField<FormTemplate>(
                      value: _selectedTemplate,
                      decoration: const InputDecoration(
                          labelText: 'Template Form',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white),
                      items: templates
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTemplate = v),
                    ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat form'),
            ),

            const SizedBox(height: 20),
            _sectionTitle('2. Template Laporan'),
            const SizedBox(height: 8),
            Row(
              children: [
                _templateChip('Ringkas', ReportTemplate.ringkas, Icons.summarize),
                const SizedBox(width: 10),
                _templateChip('Detail', ReportTemplate.detail, Icons.table_chart),
              ],
            ),

            const SizedBox(height: 20),
            _sectionTitle('3. Filter Periode (Opsional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDateBtn('Dari', _fromDate, (d) => setState(() => _fromDate = d))),
                const SizedBox(width: 10),
                Expanded(child: _buildDateBtn('Sampai', _toDate, (d) => setState(() => _toDate = d))),
              ],
            ),
            if (_fromDate != null || _toDate != null)
              TextButton(
                onPressed: () => setState(() { _fromDate = null; _toDate = null; }),
                child: const Text('Hapus filter tanggal'),
              ),

            const SizedBox(height: 20),
            _sectionTitle('4. Nama Instansi (untuk header PDF)'),
            const SizedBox(height: 8),
            TextField(
              controller: _institutionCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nama Instansi / Fasilitas Kesehatan',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white),
            ),

            const SizedBox(height: 32),
            _sectionTitle('5. Export'),
            const SizedBox(height: 12),

            // Excel button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportExcel,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.table_rows),
                label: const Text('Export Excel (.xlsx)', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            // PDF button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportPdf,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('Preview & Export PDF', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));

  Widget _templateChip(String label, ReportTemplate t, IconData icon) {
    final selected = _reportTemplate == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _reportTemplate = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6A1B9A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF6A1B9A) : Colors.grey.shade300),
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFF6A1B9A).withOpacity(0.3), blurRadius: 8)]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBtn(String label, DateTime? date, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date != null
                ? '${date.day.toString().padLeft(2,'0')}-${date.month.toString().padLeft(2,'0')}-${date.year}'
                : 'Pilih',
                style: TextStyle(fontSize: 13, color: date != null ? Colors.black87 : Colors.grey)),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }

  Future<List<PatientRecord>> _fetchRecords() async {
    if (_selectedTemplate == null) return [];
    return await ref.read(patientRecordsProvider.future).then(
      (records) => records.where((r) {
        if (r.formId != _selectedTemplate!.id) return false;
        if (_fromDate != null && r.createdAt.isBefore(_fromDate!)) return false;
        if (_toDate != null &&
            r.createdAt.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList(),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _exportExcel() async {
    if (_selectedTemplate == null) {
      _showError('Pilih form terlebih dahulu');
      return;
    }

    final isOnline = await AdService().isOnline();
    if (isOnline && _isAdLoaded && _rewardedAd != null) {
      _showAdConfirmation(() {
        // Simpan aksi yang akan dijalankan setelah iklan ditutup
        _pendingExportAction = _performExcelExport;
        _rewardEarned = false;

        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
            _isAdLoaded = false;
            _loadRewardedAd(); // preload untuk export berikutnya
            // Jalankan export SETELAH layar iklan benar-benar bersih
            if (_rewardEarned && _pendingExportAction != null) {
              _pendingExportAction!();
              _pendingExportAction = null;
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('RewardedAd failed to show: $error');
            ad.dispose();
            _rewardedAd = null;
            _isAdLoaded = false;
            _loadRewardedAd();
            // Fallback: jalankan langsung jika iklan gagal tampil
            _performExcelExport();
          },
        );

        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            // Tandai reward sudah diperoleh, tapi jangan export dulu
            _rewardEarned = true;
            debugPrint('✅ Reward earned: ${reward.amount} ${reward.type}');
          },
        );
      });
    } else {
      // Offline or ad not ready → proceed directly
      _performExcelExport();
    }
  }

  Future<void> _performExcelExport() async {
    setState(() => _isExporting = true);
    try {
      final records = await _fetchRecords();
      if (records.isEmpty) {
        _showError('Tidak ada data untuk diexport');
        return;
      }
      final path = await ExcelExporter.export(
          template: _selectedTemplate!, records: records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Excel disimpan: $path'),
          action: SnackBarAction(
              label: 'Buka',
              onPressed: () async {
                try {
                  final result = await OpenFile.open(path);
                  if (result.type != ResultType.done) {
                    _showError('Gagal membuka file: ${result.message}\nPastikan aplikasi Excel/WPS terinstall.');
                  }
                } catch (e) {
                  _showError('Tidak dapat membuka file: $e');
                }
              }),
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      _showError('Gagal export Excel: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedTemplate == null) {
      _showError('Pilih form terlebih dahulu');
      return;
    }

    final isOnline = await AdService().isOnline();
    if (isOnline && _isAdLoaded && _rewardedAd != null) {
      _showAdConfirmation(() {
        _pendingExportAction = _performPdfExport;
        _rewardEarned = false;

        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
            _isAdLoaded = false;
            _loadRewardedAd();
            if (_rewardEarned && _pendingExportAction != null) {
              _pendingExportAction!();
              _pendingExportAction = null;
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('RewardedAd failed to show: $error');
            ad.dispose();
            _rewardedAd = null;
            _isAdLoaded = false;
            _loadRewardedAd();
            _performPdfExport();
          },
        );

        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            _rewardEarned = true;
            debugPrint('✅ Reward earned: ${reward.amount} ${reward.type}');
          },
        );
      });
    } else {
      _performPdfExport();
    }
  }

  Future<void> _performPdfExport() async {
    setState(() => _isExporting = true);
    try {
      final records = await _fetchRecords();
      if (records.isEmpty) {
        _showError('Tidak ada data untuk diexport');
        return;
      }
      final pdfBytes = await PdfExporter.exportBytes(
        template: _selectedTemplate!,
        records: records,
        reportTemplate: _reportTemplate,
        institutionName: _institutionCtrl.text.trim().isNotEmpty
            ? _institutionCtrl.text.trim()
            : 'Fasilitas Kesehatan',
      );
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      }
    } catch (e) {
      _showError('Gagal export PDF: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showAdConfirmation(VoidCallback onAccept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Laporan'),
        content: const Text('Tonton iklan singkat untuk mendukung pengembangan aplikasi dan mengunduh laporan Anda secara gratis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAccept();
            },
            child: const Text('Tonton Iklan & Export'),
          ),
        ],
      ),
    );
  }
}
