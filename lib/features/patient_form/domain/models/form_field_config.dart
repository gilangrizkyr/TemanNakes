// Tipe field yang tersedia di form builder
enum FormFieldType { text, number, date, dropdown, checkbox, textarea }

extension FormFieldTypeExt on FormFieldType {
  String get label => switch (this) {
        FormFieldType.text => 'Teks',
        FormFieldType.number => 'Angka',
        FormFieldType.date => 'Tanggal',
        FormFieldType.dropdown => 'Pilihan (Dropdown)',
        FormFieldType.checkbox => 'Centang (Checkbox)',
        FormFieldType.textarea => 'Catatan Panjang',
      };

  String get icon => switch (this) {
        FormFieldType.text => 'text_fields',
        FormFieldType.number => 'numbers',
        FormFieldType.date => 'calendar_today',
        FormFieldType.dropdown => 'arrow_drop_down_circle',
        FormFieldType.checkbox => 'check_box',
        FormFieldType.textarea => 'notes',
      };

  String get rawName => switch (this) {
        FormFieldType.text => 'text',
        FormFieldType.number => 'number',
        FormFieldType.date => 'date',
        FormFieldType.dropdown => 'dropdown',
        FormFieldType.checkbox => 'checkbox',
        FormFieldType.textarea => 'textarea',
      };

  static FormFieldType fromRaw(String raw) => FormFieldType.values.firstWhere(
        (e) => e.rawName == raw,
        orElse: () => FormFieldType.text,
      );
}

/// Konfigurasi satu field dalam form
class FormFieldConfig {
  final String id;
  String label;
  FormFieldType type;
  bool isRequired;
  String? hint;
  List<String> options; // untuk dropdown

  FormFieldConfig({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.hint,
    List<String>? options,
  }) : options = options ?? [];

  FormFieldConfig copyWith({
    String? label,
    FormFieldType? type,
    bool? isRequired,
    String? hint,
    List<String>? options,
  }) {
    return FormFieldConfig(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      hint: hint ?? this.hint,
      options: options ?? List.from(this.options),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.rawName,
        'isRequired': isRequired,
        'hint': hint,
        'options': options,
      };

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      type: FormFieldTypeExt.fromRaw(json['type'] as String? ?? 'text'),
      isRequired: json['isRequired'] as bool? ?? false,
      hint: json['hint'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
