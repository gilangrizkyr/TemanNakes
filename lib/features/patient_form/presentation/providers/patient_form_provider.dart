import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/patient_form_db.dart';
import '../../domain/models/form_field_config.dart';
import '../../domain/models/form_template.dart';
import '../../domain/models/patient_record.dart';

const _uuid = Uuid();

// ─── TEMPLATE PROVIDERS ─────────────────────────────────────────────────────

class FormTemplatesNotifier extends StateNotifier<AsyncValue<List<FormTemplate>>> {
  FormTemplatesNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final templates = await PatientFormDb.instance.getAllTemplates();
      state = AsyncValue.data(templates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FormTemplate> createTemplate({
    required String name,
    String description = '',
    List<FormFieldConfig>? fields,
  }) async {
    final now = DateTime.now();
    final template = FormTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      fields: fields ?? [],
      createdAt: now,
      updatedAt: now,
    );
    await PatientFormDb.instance.saveTemplate(template);
    await load();
    return template;
  }

  Future<void> updateTemplate(FormTemplate template) async {
    template.updatedAt = DateTime.now();
    await PatientFormDb.instance.saveTemplate(template);
    await load();
  }

  Future<void> deleteTemplate(String id) async {
    await PatientFormDb.instance.deleteTemplate(id);
    await load();
  }
}

final formTemplatesProvider =
    StateNotifierProvider<FormTemplatesNotifier, AsyncValue<List<FormTemplate>>>(
  (ref) => FormTemplatesNotifier(),
);

// ─── RECORD PROVIDERS ────────────────────────────────────────────────────────

// Filter state
final recordFormFilterProvider = StateProvider<String>((ref) => ''); // formId
final recordSearchProvider = StateProvider<String>((ref) => '');
final recordFromDateProvider = StateProvider<DateTime?>((ref) => null);
final recordToDateProvider = StateProvider<DateTime?>((ref) => null);

final patientRecordsProvider = FutureProvider<List<PatientRecord>>((ref) async {
  final formId = ref.watch(recordFormFilterProvider);
  final search = ref.watch(recordSearchProvider);
  final from = ref.watch(recordFromDateProvider);
  final to = ref.watch(recordToDateProvider);
  return PatientFormDb.instance.getRecords(
    formId: formId.isEmpty ? null : formId,
    searchQuery: search.isEmpty ? null : search,
    fromDate: from,
    toDate: to,
  );
});

class PatientRecordsNotifier extends StateNotifier<void> {
  final Ref ref;
  PatientRecordsNotifier(this.ref) : super(null);

  Future<PatientRecord> createRecord({
    required String formId,
    required String formName,
    required Map<String, dynamic> values,
  }) async {
    final now = DateTime.now();
    final record = PatientRecord(
      id: _uuid.v4(),
      formId: formId,
      formName: formName,
      values: values,
      createdAt: now,
      updatedAt: now,
    );
    await PatientFormDb.instance.saveRecord(record);
    _invalidate();
    return record;
  }

  Future<void> updateRecord(PatientRecord record) async {
    final updated = record.copyWith(updatedAt: DateTime.now());
    await PatientFormDb.instance.saveRecord(updated);
    _invalidate();
  }

  Future<void> deleteRecord(String id) async {
    await PatientFormDb.instance.deleteRecord(id);
    _invalidate();
  }

  void _invalidate() {
    ref.invalidate(patientRecordsProvider);
    // Also invalidate detail if specific
    ref.invalidate(patientRecordDetailProvider);
  }
}

final patientRecordsNotifierProvider =
    StateNotifierProvider<PatientRecordsNotifier, void>(
  (ref) => PatientRecordsNotifier(ref),
);

// Detail provider for a single record
final patientRecordDetailProvider =
    FutureProvider.family<PatientRecord?, String>((ref, id) async {
  return PatientFormDb.instance.getRecord(id);
});
