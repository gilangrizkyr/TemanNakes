import 'dart:convert';

/// Satu record data pasien yang diisi berdasarkan sebuah FormTemplate
class PatientRecord {
  final String id;
  final String formId;
  final String formName; // denormalized for display
  Map<String, dynamic> values; // {fieldId: value}
  final DateTime createdAt;
  DateTime updatedAt;

  PatientRecord({
    required this.id,
    required this.formId,
    required this.formName,
    required this.values,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Ambil nilai field tertentu sebagai String untuk tampilan
  String displayValue(String fieldId) {
    final v = values[fieldId];
    if (v == null) return '-';
    if (v is bool) return v ? 'Ya' : 'Tidak';
    if (v is List) return v.join(', ');
    return v.toString();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'form_id': formId,
        'form_name': formName,
        'values_json': jsonEncode(values),
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory PatientRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> decodedValues = {};
    try {
      decodedValues = jsonDecode(map['values_json'] as String) as Map<String, dynamic>;
    } catch (e) {
      // Data corruption fallback: empty values to prevent crashes
      decodedValues = {};
    }
    
    return PatientRecord(
      id: map['id'] as String,
      formId: map['form_id'] as String,
      formName: map['form_name'] as String? ?? '',
      values: decodedValues,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int? ?? 0),
    );
  }

  PatientRecord copyWith({Map<String, dynamic>? values, DateTime? updatedAt}) {
    return PatientRecord(
      id: id,
      formId: formId,
      formName: formName,
      values: values ?? Map.from(this.values),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
