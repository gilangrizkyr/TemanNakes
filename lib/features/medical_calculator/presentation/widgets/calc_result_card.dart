import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calc_result.dart';
import '../providers/calc_history_provider.dart';

/// Shared colorful result card for all medical calculators.
class CalcResultCard extends ConsumerWidget {
  final CalculationResult result;
  final bool showSaveButton;

  const CalcResultCard({
    super.key,
    required this.result,
    this.showSaveButton = true,
  });

  Color _bgColor() => switch (result.severity) {
        CalcSeverity.normal => const Color(0xFFE8F5E9),
        CalcSeverity.warning => const Color(0xFFFFF8E1),
        CalcSeverity.danger => const Color(0xFFFFEBEE),
      };

  Color _accentColor() => switch (result.severity) {
        CalcSeverity.normal => const Color(0xFF2E7D32),
        CalcSeverity.warning => const Color(0xFFF57F17),
        CalcSeverity.danger => const Color(0xFFC62828),
      };

  IconData _icon() => switch (result.severity) {
        CalcSeverity.normal => Icons.check_circle,
        CalcSeverity.warning => Icons.warning_amber_rounded,
        CalcSeverity.danger => Icons.error,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _accentColor();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_icon(), color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    result.label,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              if (showSaveButton)
                GestureDetector(
                  onTap: () {
                    ref.read(calcHistoryProvider.notifier).add(result);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tersimpan ke riwayat'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(Icons.save_outlined, color: accent, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Main Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    result.value,
                    style: TextStyle(
                      color: accent,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  result.unit,
                  style: TextStyle(color: accent.withOpacity(0.7), fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Interpretation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.interpretation,
              style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          // Extra key-value pairs
          if (result.extras != null && result.extras!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...result.extras!.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(e.key,
                          style: TextStyle(
                              color: accent.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(e.value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Education steps
          if (result.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EducationPanel(steps: result.steps, accentColor: accent),
          ],
          // Evidence Source & Confidence Badge
          if (result.sourceLabel != null || result.confidenceLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (result.confidenceLabel != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: accent, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(result.confidenceLabel!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (result.confidenceLabel != null && result.sourceLabel != null)
                  const SizedBox(width: 8),
                if (result.sourceLabel != null)
                  Expanded(
                    child: Text(result.sourceLabel!,
                        style: TextStyle(
                            color: accent.withOpacity(0.5),
                            fontSize: 10,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ],
          // ── Soft Clinical Interpretation (Attention Lock) ─────────────────
          // Safe wording: context only, NOT clinical instruction or diagnosis.
          if (result.interpretationHint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF006064).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF006064).withOpacity(0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.book_outlined, size: 14, color: Color(0xFF006064)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.interpretationHint!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF004D40),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Disclaimer
          const SizedBox(height: 12),
          Text(
            '⚠️ Hanya alat bantu. Tidak menggantikan keputusan klinis.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationPanel extends StatefulWidget {
  final List<String> steps;
  final Color accentColor;
  const _EducationPanel({required this.steps, required this.accentColor});

  @override
  State<_EducationPanel> createState() => _EducationPanelState();
}

class _EducationPanelState extends State<_EducationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.school_outlined,
                color: widget.accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _expanded ? 'Sembunyikan' : 'Lihat Cara Hitung',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.steps
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key + 1}. ',
                              style: TextStyle(
                                  color: widget.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          Expanded(
                            child: Text(e.value,
                                style: TextStyle(
                                    color: widget.accentColor.withOpacity(0.8),
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
