import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../domain/models/form_template.dart';
import '../domain/models/patient_record.dart';

/// Database terpisah dari database obat utama — tidak mengganggu fitur lain
class PatientFormDb {
  PatientFormDb._();
  static final PatientFormDb instance = PatientFormDb._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'patient_forms.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE form_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        fields_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE patient_records (
        id TEXT PRIMARY KEY,
        form_id TEXT NOT NULL,
        form_name TEXT NOT NULL DEFAULT '',
        values_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Indexes for fast filtering
    await db.execute('CREATE INDEX idx_records_form ON patient_records(form_id)');
    await db.execute('CREATE INDEX idx_records_created ON patient_records(created_at DESC)');
  }

  // ─── FORM TEMPLATES ────────────────────────────────────────────────────────

  Future<void> saveTemplate(FormTemplate template) async {
    final db = await database;
    await db.insert('form_templates', template.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FormTemplate>> getAllTemplates() async {
    final db = await database;
    final rows = await db.query('form_templates', orderBy: 'updated_at DESC');
    return rows.map(FormTemplate.fromMap).toList();
  }

  Future<FormTemplate?> getTemplate(String id) async {
    final db = await database;
    final rows = await db.query('form_templates', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return FormTemplate.fromMap(rows.first);
  }

  Future<void> deleteTemplate(String id) async {
    // Audit check: Ensure no records exist before deleting the source template
    final count = await recordCount(id);
    if (count > 0) {
      throw Exception('Gagal menghapus: Masih ada $count data pasien yang menggunakan form ini. Hapus data pasien terlebih dahulu untuk menjaga integritas klinis.');
    }
    
    final db = await database;
    await db.delete('form_templates', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PATIENT RECORDS ───────────────────────────────────────────────────────

  Future<void> saveRecord(PatientRecord record) async {
    final db = await database;
    await db.insert('patient_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PatientRecord>> getRecords({
    String? formId,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;
    String where = '1=1';
    final List<dynamic> args = [];

    if (formId != null && formId.isNotEmpty) {
      where += ' AND form_id = ?';
      args.add(formId);
    }
    if (fromDate != null) {
      where += ' AND created_at >= ?';
      args.add(fromDate.millisecondsSinceEpoch);
    }
    if (toDate != null) {
      where += ' AND created_at <= ?';
      // Include the entire day by adding 1 day (minus 1ms or just use next day 00:00)
      args.add(toDate.add(const Duration(days: 1)).millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'patient_records',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: 500,
    );

    var records = rows.map(PatientRecord.fromMap).toList();

    // In-memory search on values_json and formName (offline friendly)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      records = records.where((r) {
        final inFields = r.values.values.any((v) => v.toString().toLowerCase().contains(q));
        final inFormName = r.formName.toLowerCase().contains(q);
        return inFields || inFormName;
      }).toList();
    }

    return records;
  }

  Future<PatientRecord?> getRecord(String id) async {
    final db = await database;
    final rows = await db.query('patient_records', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return PatientRecord.fromMap(rows.first);
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('patient_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> recordCount(String formId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM patient_records WHERE form_id = ?', [formId]);
    return result.first['c'] as int? ?? 0;
  }
}
