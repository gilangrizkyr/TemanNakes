import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/medicine/domain/models/medicine.dart';
import '../../features/patient_form/data/patient_form_db.dart';
import '../utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // Update this constant whenever the asset DB structure or content significantly changes
  static const int _currentAppVersion = 4; // Pinnacle V4.0 Certification

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('temannakes.db');
    await _checkIntegrity(_database!);
    return _database!;
  }

  Future<void> _checkIntegrity(Database db) async {
    final result = await db.rawQuery('PRAGMA integrity_check');
    AppLogger.info("DB Integrity: ${result.first['integrity_check']}");
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final userDb = PatientFormDb.instance;
    final lastMigrated = int.tryParse(await userDb.getSetting('last_migrated_version') ?? '0') ?? 0;
    final exists = await databaseExists(path);

    bool shouldCopy = !exists || (lastMigrated < _currentAppVersion);

    if (shouldCopy) {
      AppLogger.info("Syncing medicine database from assets (Version: $_currentAppVersion)");
      
      // PERFECTION AUDIT: Before overwriting, perform ONE-TIME migration of legacy favorites
      if (exists && lastMigrated < 4) {
        await _surgicalMigration(path);
      }

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets/database", filePath));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      
      // Update migration flag
      await userDb.saveSetting('last_migrated_version', _currentAppVersion.toString());
    } else {
      AppLogger.info("Opening production-hardened medicine database");
    }

    return await openDatabase(
      path,
      version: 1,
    );
  }

  /// One-time migration of favorites from legacy database to the new secure vault
  Future<void> _surgicalMigration(String legacyPath) async {
    AppLogger.info("Executing surgical migration of legacy favorites...");
    try {
      final legacyDb = await openDatabase(legacyPath, readOnly: true);
      final maps = await legacyDb.query('favorit');
      final ids = maps.map((m) => m['id_obat'] as int).toList();
      
      if (ids.isNotEmpty) {
        await PatientFormDb.instance.importFavorites(ids);
        AppLogger.info("Successfully migrated ${ids.length} favorites to the secure vault.");
      }
      await legacyDb.close();
    } catch (e) {
      AppLogger.warning("Surgical migration failed or table doesn't exist: $e");
    }
  }

  // --- QUERY METHODS ---

  // Search Medicines (FTS5 - ultra fast & typo-tolerant searching)
  Future<List<MedicineSimple>> searchMedicines(String query, {String? category, String? form}) async {
    final db = await instance.database;
    final hasCategory = category != null && category != 'Semua';
    final hasForm = form != null && form != 'Semua';

    // Empty query with no filters → show top 50 alphabetically
    if (query.trim().isEmpty && !hasCategory && !hasForm) {
      final result = await db.query('obat', limit: 50, orderBy: 'nama_generik ASC');
      return result.map((json) => MedicineSimple.fromMap(json)).toList();
    }

    // Filter-only (empty query but filters are active) → direct WHERE query
    if (query.trim().isEmpty && (hasCategory || hasForm)) {
      String whereClause = '1=1';
      final List<dynamic> args = [];
      // Use LIKE so 'Antibiotik' matches 'Antibiotik Kuat', 'Antibiotik Carbapenem' etc.
      if (hasCategory) { whereClause += ' AND golongan LIKE ?'; args.add('%$category%'); }
      if (hasForm) { whereClause += ' AND bentuk LIKE ?'; args.add('%$form%'); }
      final result = await db.query('obat', where: whereClause, whereArgs: args, limit: 50, orderBy: 'nama_generik ASC');
      return result.map((json) => MedicineSimple.fromMap(json)).toList();
    }

    // Full FTS search — prioritize exact starts-with on nama_generik
    String sql = '''
      SELECT o.* FROM obat o
      JOIN obat_fts f ON o.id = f.id
      WHERE f.obat_fts MATCH ?
    ''';
    String ftsQuery = query.trim().split(' ').map((e) => '$e*').join(' ');
    List<dynamic> args = [ftsQuery];

    if (hasCategory) {
      sql += ' AND o.golongan LIKE ?';
      // Use LIKE so partial matches work (e.g. 'Antibiotik' matches all sub-classes)
      args.add('%$category%');
    }
    if (hasForm) {
      sql += ' AND o.bentuk LIKE ?';
      args.add('%$form%');
    }
    // Order: exact prefix match on nama_generik first, then BM25 rank
    sql += ' ORDER BY CASE WHEN LOWER(o.nama_generik) LIKE LOWER(?) THEN 0 ELSE 1 END, f.rank LIMIT 50';
    args.add('${query.trim()}%');

    try {
      final result = await db.rawQuery(sql, args);
      return result.map((json) => MedicineSimple.fromMap(json)).toList();
    } catch (e) {
      AppLogger.warning('FTS search failed, falling back to LIKE: $e');
      return _searchMedicinesLike(query, category: category, form: form);
    }
  }

  // [PERF FIX] Get Trending Medicines — single batch query, replaces 5 sequential queries
  Future<List<MedicineSimple>> getTrendingMedicines() async {
    final db = await instance.database;
    const topDrugs = ['Amoxicillin', 'Paracetamol', 'Amlodipine', 'Metformin', 'Omeprazole'];
    // CASE WHEN untuk menjaga urutan yang diinginkan
    final orderCase = topDrugs.asMap().entries
        .map((e) => "WHEN LOWER(nama_generik) LIKE LOWER('${e.value}%') THEN ${e.key}")
        .join(' ');
    final result = await db.rawQuery('''
      SELECT * FROM obat
      WHERE ${topDrugs.map((_) => 'nama_generik LIKE ?').join(' OR ')}
      ORDER BY CASE $orderCase ELSE ${topDrugs.length} END
      LIMIT 5
    ''', topDrugs.map((d) => '$d%').toList());
    // Ambil satu per nama generik yang matching
    final seen = <String>{};
    final medicines = <MedicineSimple>[];
    for (final row in result) {
      final nama = (row['nama_generik'] as String).toLowerCase();
      final matchedDrug = topDrugs.firstWhere(
        (d) => nama.startsWith(d.toLowerCase()),
        orElse: () => '',
      );
      if (matchedDrug.isNotEmpty && !seen.contains(matchedDrug)) {
        seen.add(matchedDrug);
        medicines.add(MedicineSimple.fromMap(row));
      }
    }
    return medicines;
  }

  // Fallback LIKE search
  Future<List<MedicineSimple>> _searchMedicinesLike(String query, {String? category, String? form}) async {
    final db = await instance.database;
    String whereClause = '(nama_generik LIKE ? OR nama_dagang LIKE ? OR kode LIKE ? OR sinonim LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%', '%$query%'];

    if (category != null && category != 'Semua') {
      whereClause += ' AND golongan = ?';
      whereArgs.add(category);
    }
    if (form != null && form != 'Semua') {
      whereClause += ' AND bentuk LIKE ?';
      whereArgs.add('%$form%');
    }
    
    // Add golongan and kelas_terapi to search scope in fallback
    if (query.isNotEmpty) {
       whereClause += ' OR golongan LIKE ? OR kelas_terapi LIKE ?';
       whereArgs.addAll(['%$query%', '%$query%']);
    }

    final result = await db.query('obat', where: whereClause, whereArgs: whereArgs, limit: 50, orderBy: 'nama_generik ASC');
    return result.map((json) => MedicineSimple.fromMap(json)).toList();
  }

  // Get Detailed Info for a specific medicine (On-demand/Lazy load)
  Future<MedicineDetail?> getMedicineDetail(int id) async {
    final db = await instance.database;

    final maps = await db.rawQuery('''
      SELECT o.*, d.* FROM obat o
      LEFT JOIN obat_detail d ON o.id = d.id_obat
      WHERE o.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return MedicineDetail.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Get All Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('kategori');
  }

  // Get Medicines by Category
  Future<List<MedicineSimple>> getMedicinesByCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT obat.* FROM obat 
      JOIN obat_kategori ON obat.id = obat_kategori.id_obat
      WHERE obat_kategori.id_kategori = ?
    ''', [categoryId]);
    return result.map((json) => MedicineSimple.fromMap(json)).toList();
  }

  // --- FAVORITES (Redirected to Secure User Vault) ---
  Future<bool> isFavorite(int id) async {
    return await PatientFormDb.instance.isFavorite(id);
  }

  Future<void> toggleFavorite(int id) async {
    await PatientFormDb.instance.toggleFavorite(id);
  }

  Future<List<MedicineSimple>> getFavorites() async {
    final db = await instance.database;
    final ids = await PatientFormDb.instance.getFavoriteIds();
    if (ids.isEmpty) return [];

    final result = await db.query(
      'obat',
      where: 'id IN (${ids.join(',')})',
    );
    return result.map((json) => MedicineSimple.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
