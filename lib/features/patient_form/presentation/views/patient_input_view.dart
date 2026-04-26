import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/form_field_config.dart';
import '../../domain/models/form_template.dart';
import '../../domain/models/patient_record.dart';
import '../providers/patient_form_provider.dart';

/// Layar untuk mengisi data pasien sesuai template form
class PatientInputView extends ConsumerStatefulWidget {
  final FormTemplate template;
  final PatientRecord? existingRecord; // null = create, non-null = edit

  const PatientInputView({super.key, required this.template, this.existingRecord});

  @override
  ConsumerState<PatientInputView> createState() => _PatientInputViewState();
}

class _PatientInputViewState extends ConsumerState<PatientInputView> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _values;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _values = widget.existingRecord != null
        ? Map.from(widget.existingRecord!.values)
        : {
            for (final f in widget.template.fields)
              f.id: f.type == FormFieldType.checkbox ? false : null,
          };
  }

  Future<void> _save() async {
    // Manual validation of required fields
    for (final field in widget.template.fields) {
      if (!field.isRequired) continue;
      final val = _values[field.id];
      if (val == null || val.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ "${field.label}" wajib diisi'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      if (widget.existingRecord != null) {
        // Update existing
        final updated = widget.existingRecord!.copyWith(
          values: _values,
          updatedAt: DateTime.now(),
        );
        await ref.read(patientRecordsNotifierProvider.notifier).updateRecord(updated);
      } else {
        // Create new
        await ref.read(patientRecordsNotifierProvider.notifier).createRecord(
              formId: widget.template.id,
              formName: widget.template.name,
              values: _values,
            );
      }
      ref.invalidate(patientRecordsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Data berhasil disimpan'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingRecord != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Pasien' : 'Input Data Pasien'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Form name header
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00695C).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Color(0xFF00695C)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(widget.template.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14))),
                ],
              ),
            ),
            // Dynamic fields
            ...widget.template.fields
                .map((field) => _buildFieldWidget(field)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        onPressed: _isSaving ? null : _save,
        icon: const Icon(Icons.save),
        label: const Text('Simpan Data'),
      ),
    );
  }

  Widget _buildFieldWidget(FormFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (field.type) {
        FormFieldType.text => _buildText(field),
        FormFieldType.number => _buildNumber(field),
        FormFieldType.date => _buildDate(field),
        FormFieldType.dropdown => _buildDropdown(field),
        FormFieldType.checkbox => _buildCheckbox(field),
        FormFieldType.textarea => _buildTextarea(field),
      },
    );
  }

  InputDecoration _decoration(FormFieldConfig f) => InputDecoration(
        labelText: '${f.label}${f.isRequired ? ' *' : ''}',
        hintText: f.hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      );

  Widget _buildText(FormFieldConfig f) {
    return TextFormField(
      initialValue: _values[f.id]?.toString(),
      decoration: _decoration(f),
      onChanged: (v) => _values[f.id] = v,
    );
  }

  Widget _buildNumber(FormFieldConfig f) {
    return TextFormField(
      initialValue: _values[f.id]?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoration(f),
      onChanged: (v) {
        // V5.4: Store raw literal string instead of parsing to double
        _values[f.id] = v;
      },
    );
  }

  Widget _buildDate(FormFieldConfig f) {
    final dateStr = _values[f.id]?.toString();
    return InkWell(
      onTap: () async {
        DateTime? initial;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            initial = DateTime.parse(dateStr);
          } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _values[f.id] = picked.toIso8601String().substring(0, 10));
        }
      },
      child: InputDecorator(
        decoration: _decoration(f),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateStr != null && dateStr.isNotEmpty ? dateStr : 'Pilih Tanggal',
              style: TextStyle(
                  color: dateStr != null ? Colors.black87 : Colors.grey),
            ),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(FormFieldConfig f) {
    if (f.options.isEmpty) {
      return InputDecorator(
        decoration: _decoration(f),
        child: const Text('— Tidak ada pilihan, edit di Form Builder —',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
    return DropdownButtonFormField<String>(
      value: _values[f.id]?.toString(),
      decoration: _decoration(f),
      items: f.options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) => setState(() => _values[f.id] = v),
    );
  }

  Widget _buildCheckbox(FormFieldConfig f) {
    final val = _values[f.id] as bool? ?? false;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: CheckboxListTile(
        title: Text(f.label),
        subtitle: f.hint != null ? Text(f.hint!, style: const TextStyle(fontSize: 12)) : null,
        value: val,
        activeColor: const Color(0xFF00695C),
        onChanged: (v) => setState(() => _values[f.id] = v ?? false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTextarea(FormFieldConfig f) {
    return TextFormField(
      initialValue: _values[f.id]?.toString(),
      maxLines: 5,
      decoration: _decoration(f),
      onChanged: (v) => _values[f.id] = v,
    );
  }
}
