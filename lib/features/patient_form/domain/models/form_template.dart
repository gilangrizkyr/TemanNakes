import 'dart:convert';
import 'form_field_config.dart';

/// Template form yang dibuat oleh user
class FormTemplate {
  final String id;
  String name;
  String description;
  List<FormFieldConfig> fields;
  final DateTime createdAt;
  DateTime updatedAt;

  FormTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'fields_json': jsonEncode(fields.map((f) => f.toJson()).toList()),
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory FormTemplate.fromMap(Map<String, dynamic> map) {
    final fieldsRaw = jsonDecode(map['fields_json'] as String) as List<dynamic>;
    return FormTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      fields: fieldsRaw
          .map((e) => FormFieldConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
