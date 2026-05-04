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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.existingRecord != null) {
        final updated = widget.existingRecord!.copyWith(
          values: _values,
          updatedAt: DateTime.now(),
        );
        await ref.read(patientRecordsNotifierProvider.notifier).updateRecord(updated);
      } else {
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
          IconButton(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Color(0xFF00695C)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.template.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF263238)),
                    ),
                  ),
                ],
              ),
            ),
            ...widget.template.fields.map((field) => _buildFieldWidget(field)),
            const SizedBox(height: 100),
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
      padding: const EdgeInsets.only(bottom: 20),
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
        labelText: f.label,
        hintText: f.hint,
        suffixIcon: f.isRequired ? const Icon(Icons.star, size: 8, color: Colors.redAccent) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00695C), width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  String? _requiredValidator(FormFieldConfig f, String? v) {
    if (f.isRequired && (v == null || v.trim().isEmpty)) {
      return 'Mohon isi ${f.label}';
    }
    return null;
  }

  Widget _buildText(FormFieldConfig f) {
    return TextFormField(
      initialValue: _values[f.id]?.toString(),
      decoration: _decoration(f),
      textInputAction: TextInputAction.next,
      validator: (v) => _requiredValidator(f, v),
      onChanged: (v) => _values[f.id] = v,
    );
  }

  Widget _buildNumber(FormFieldConfig f) {
    return TextFormField(
      initialValue: _values[f.id]?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoration(f),
      textInputAction: TextInputAction.next,
      validator: (v) => _requiredValidator(f, v),
      onChanged: (v) => _values[f.id] = v,
    );
  }

  Widget _buildDate(FormFieldConfig f) {
    final dateStr = _values[f.id]?.toString();
    return FormField<String>(
      initialValue: dateStr,
      validator: (v) => f.isRequired && (v == null || v.isEmpty) ? 'Pilih tanggal' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              DateTime? initial;
              if (dateStr != null && dateStr.isNotEmpty) {
                try { initial = DateTime.parse(dateStr); } catch (_) {}
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: initial ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                final formatted = picked.toIso8601String().substring(0, 10);
                setState(() => _values[f.id] = formatted);
                state.didChange(formatted);
              }
            },
            child: InputDecorator(
              decoration: _decoration(f).copyWith(errorText: state.errorText),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateStr != null && dateStr.isNotEmpty ? dateStr : 'Pilih Tanggal',
                      style: TextStyle(color: dateStr != null ? Colors.black87 : Colors.grey.shade400, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(FormFieldConfig f) {
    if (f.options.isEmpty) {
      return InputDecorator(
        decoration: _decoration(f),
        child: const Text('— Tidak ada pilihan —', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
    return DropdownButtonFormField<String>(
      value: _values[f.id]?.toString(),
      decoration: _decoration(f),
      validator: (v) => f.isRequired && v == null ? 'Pilih salah satu' : null,
      items: f.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) => setState(() => _values[f.id] = v),
    );
  }

  Widget _buildCheckbox(FormFieldConfig f) {
    final val = _values[f.id] as bool? ?? false;
    return CheckboxListTile(
      title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: f.hint != null ? Text(f.hint!, style: const TextStyle(fontSize: 12)) : null,
      value: val,
      activeColor: const Color(0xFF00695C),
      onChanged: (v) => setState(() => _values[f.id] = v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildTextarea(FormFieldConfig f) {
    return TextFormField(
      initialValue: _values[f.id]?.toString(),
      maxLines: 4,
      keyboardType: TextInputType.multiline,
      decoration: _decoration(f),
      validator: (v) => _requiredValidator(f, v),
      onChanged: (v) => _values[f.id] = v,
    );
  }
}
