import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/form_field_config.dart';
import '../../domain/models/form_template.dart';
import '../providers/patient_form_provider.dart';
import 'patient_input_view.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────
// LIST OF TEMPLATES
// ─────────────────────────────────────────────────────────────────────────────
class FormBuilderListView extends ConsumerWidget {
  const FormBuilderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(formTemplatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Form Builder'),
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Form Baru'),
        onPressed: () => _createNew(context, ref),
      ),
      body: templatesAsync.when(
        data: (templates) => templates.isEmpty
            ? _buildEmpty(context, ref)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: templates.length,
                itemBuilder: (context, i) =>
                    _buildTemplateCard(context, ref, templates[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dynamic_form_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada form',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Ketuk "Buat Form Baru" untuk memulai',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, WidgetRef ref, FormTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0277BD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.dynamic_form, color: Color(0xFF0277BD)),
        ),
        title: Text(template.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${template.fields.length} field${template.description.isNotEmpty ? ' • ${template.description}' : ''}',
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => FormEditorView(template: template)));
              ref.read(formTemplatesProvider.notifier).load();
            } else if (action == 'input') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PatientInputView(template: template)));
            } else if (action == 'delete') {
              _confirmDelete(context, ref, template);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Form'))),
            PopupMenuItem(value: 'input', child: ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Input Pasien'))),
            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red)))),
          ],
        ),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => FormEditorView(template: template)));
          ref.read(formTemplatesProvider.notifier).load();
        },
      ),
    );
  }

  Future<void> _createNew(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Nama Form *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final template = await ref.read(formTemplatesProvider.notifier).createTemplate(
            name: nameCtrl.text.trim(),
            description: descCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Form "${nameCtrl.text.trim()}" berhasil dibuat'), backgroundColor: Colors.green),
        );
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => FormEditorView(template: template)));
        ref.read(formTemplatesProvider.notifier).load();
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FormTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Form?'),
        content: Text(
            'Menghapus "${template.name}" akan menghapus semua data pasien yang terkait. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(formTemplatesProvider.notifier).deleteTemplate(template.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🗑️ Form "${template.name}" telah dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM EDITOR (with drag & drop field reordering)
// ─────────────────────────────────────────────────────────────────────────────
class FormEditorView extends ConsumerStatefulWidget {
  final FormTemplate template;
  const FormEditorView({super.key, required this.template});

  @override
  ConsumerState<FormEditorView> createState() => _FormEditorState();
}

class _FormEditorState extends ConsumerState<FormEditorView> {
  late FormTemplate _template;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Deep copy fields so changes don't affect the original until saved
    _template = FormTemplate(
      id: widget.template.id,
      name: widget.template.name,
      description: widget.template.description,
      fields: widget.template.fields.map((f) => f.copyWith()).toList(),
      createdAt: widget.template.createdAt,
      updatedAt: widget.template.updatedAt,
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ada perubahan belum disimpan'),
        content: const Text('Simpan perubahan sebelum keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Buang')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (result == true) await _save();
    return true;
  }

  Future<void> _save() async {
    _template.updatedAt = DateTime.now();
    await ref.read(formTemplatesProvider.notifier).updateTemplate(_template);
    if (mounted) setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Form berhasil disimpan'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop) await _onWillPop().then((ok) { if (ok) Navigator.pop(context); });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_template.name),
          backgroundColor: const Color(0xFF0277BD),
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0277BD),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Field'),
          onPressed: _addField,
        ),
        body: _template.fields.isEmpty
            ? _buildEmptyFields()
            : _buildFieldList(),
      ),
    );
  }

  Widget _buildEmptyFields() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.input, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada field',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Ketuk "Tambah Field" untuk menambah field pertama',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFieldList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Tahan & seret untuk ubah urutan',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: _template.fields.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final field = _template.fields.removeAt(oldIndex);
                _template.fields.insert(newIndex, field);
                _hasChanges = true;
              });
            },
            itemBuilder: (context, index) {
              final field = _template.fields[index];
              return _buildFieldCard(field, index, key: ValueKey(field.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCard(FormFieldConfig field, int index, {required Key key}) {
    final labels = _template.fields.map((f) => f.label.trim().toLowerCase()).toList();
    final isDuplicate = labels.where((l) => l == field.label.trim().toLowerCase()).length > 1;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_indicator, color: Colors.grey),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(field.label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isDuplicate)
              const Tooltip(
                message: 'Peringatan: Label duplikat dapat membingungkan di laporan',
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              ),
            if (field.isRequired)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text('WAJIB',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(field.type.label, style: const TextStyle(fontSize: 12)),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') _editField(field, index);
            if (action == 'delete') {
              setState(() {
                _template.fields.removeAt(index);
                _hasChanges = true;
              });
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red)))),
          ],
        ),
        onTap: () => _editField(field, index),
      ),
    );
  }

  Future<void> _addField() async {
    final newField = FormFieldConfig(
      id: _uuid.v4(),
      label: '',
      type: FormFieldType.text,
    );
    await _showFieldEditor(newField, isNew: true);
  }

  Future<void> _editField(FormFieldConfig field, int index) async {
    await _showFieldEditor(field.copyWith(), isNew: false, originalIndex: index);
  }

  Future<void> _showFieldEditor(FormFieldConfig field,
      {required bool isNew, int? originalIndex}) async {
    final result = await showModalBottomSheet<FormFieldConfig>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => FieldEditorSheet(field: field),
    );
    if (result != null) {
      setState(() {
        if (isNew) {
          _template.fields.add(result);
        } else {
          _template.fields[originalIndex!] = result;
        }
        _hasChanges = true;
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD EDITOR BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class FieldEditorSheet extends StatefulWidget {
  final FormFieldConfig field;
  const FieldEditorSheet({super.key, required this.field});

  @override
  State<FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<FieldEditorSheet> {
  late TextEditingController _labelCtrl;
  late TextEditingController _hintCtrl;
  late TextEditingController _optionsCtrl; // comma-separated for dropdown
  late FormFieldType _type;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label);
    _hintCtrl = TextEditingController(text: widget.field.hint ?? '');
    _optionsCtrl = TextEditingController(text: widget.field.options.join(', '));
    _type = widget.field.type;
    _isRequired = widget.field.isRequired;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _hintCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_labelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label field tidak boleh kosong')));
      return;
    }
    final options = _type == FormFieldType.dropdown
        ? _optionsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    final result = widget.field.copyWith(
      label: _labelCtrl.text.trim(),
      type: _type,
      isRequired: _isRequired,
      hint: _hintCtrl.text.trim().isEmpty ? null : _hintCtrl.text.trim(),
      options: options,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Konfigurasi Field',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            // Label
            TextField(
              controller: _labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Label Field *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Tipe
            DropdownButtonFormField<FormFieldType>(
              value: _type,
              decoration: const InputDecoration(
                  labelText: 'Tipe Field', border: OutlineInputBorder()),
              items: FormFieldType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            // Options for dropdown
            if (_type == FormFieldType.dropdown) ...[
              TextField(
                controller: _optionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pilihan (pisahkan dengan koma)',
                  hintText: 'Contoh: Akut, Kronis, Subakut',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Hint
            TextField(
              controller: _hintCtrl,
              decoration: const InputDecoration(
                  labelText: 'Placeholder / Petunjuk (opsional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            // Required toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Field Wajib Diisi'),
              subtitle: const Text('Tidak bisa submit jika kosong',
                  style: TextStyle(fontSize: 11)),
              value: _isRequired,
              activeColor: const Color(0xFF0277BD),
              onChanged: (v) => setState(() => _isRequired = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0277BD),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _save,
                child: const Text('Simpan Field'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
