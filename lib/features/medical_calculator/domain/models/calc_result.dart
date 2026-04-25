/// Universal model for all medical calculator results.
enum CalcSeverity { normal, warning, danger }

class CalculationResult {
  final String moduleName;
  final String label;
  final String value;
  final String unit;
  final String interpretation;
  final CalcSeverity severity;
  final List<String> steps; // For education mode
  final Map<String, String>? extras; // Additional key-value results
  final DateTime timestamp;

  CalculationResult({
    required this.moduleName,
    required this.label,
    required this.value,
    required this.unit,
    required this.interpretation,
    required this.severity,
    this.steps = const [],
    this.extras,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Human-readable summary
  String get summary => '$label: $value $unit ($interpretation)';
}
