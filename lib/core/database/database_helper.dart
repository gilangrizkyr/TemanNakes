import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/medicine/domain/models/medicine.dart';
import '../utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

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

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      AppLogger.info("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets/database", filePath));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      AppLogger.info("Opening existing database");
    }

    return await openDatabase(
      path,
      version: 1,
      onUpgrade: (db, oldVersion, newVersion) {
        // Implement migrations here if needed
        AppLogger.info("Upgrading DB from $oldVersion to $newVersion");
      },
    );
  }

  // --- QUERY METHODS ---

  // Search Medicines (FTS5 - ultra fast & typo-tolerant searching)
  Future<List<MedicineSimple>> searchMedicines(String query, {String? category, String? form}) async {
    final db = await instance.database;
    
    // FTS queries usually use MATCH
    // If query is empty, fall back to basic select
    if (query.trim().isEmpty && (category == null || category == 'Semua') && (form == null || form == 'Semua')) {
      final result = await db.query('obat', limit: 50, orderBy: 'nama_generik ASC');
      return result.map((json) => MedicineSimple.fromMap(json)).toList();
    }

    String sql = '''
      SELECT o.* FROM obat o
      JOIN obat_fts f ON o.id = f.id
      WHERE f.obat_fts MATCH ?
    ''';
    
    // FTS MATCH query format (prefix search for every word)
    String ftsQuery = query.trim().split(' ').map((e) => '$e*').join(' ');
    List<dynamic> args = [ftsQuery];

    if (category != null && category != 'Semua') {
      sql += ' AND o.golongan = ?';
      args.add(category);
    }
    
    if (form != null && form != 'Semua') {
      sql += ' AND o.bentuk LIKE ?';
      args.add('%$form%');
    }

    // SUPREME RANKING: bm25 ensures the most relevant result (exact name match) is at the top
    sql += ' ORDER BY f.rank LIMIT 50';

    try {
      final result = await db.rawQuery(sql, args);
      return result.map((json) => MedicineSimple.fromMap(json)).toList();
    } catch (e) {
      // Fallback to LIKE if FTS fails for some reason
      AppLogger.warning("FTS search failed, falling back to LIKE: $e");
      return _searchMedicinesLike(query, category: category, form: form);
    }
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

    final result = await db.query('obat', where: whereClause, whereArgs: whereArgs, limit: 50, orderBy: 'nama_generik ASC');
    return result.map((json) => MedicineSimple.fromMap(json)).toList();
  }

  // Get Detailed Info for a specific medicine (On-demand/Lazy load)
  Future<MedicineDetail?> getMedicineDetail(int id) async {
    final db = await instance.database;

    final maps = await db.rawQuery('''
      SELECT o.*, d.* FROM obat o
      JOIN obat_detail d ON o.id = d.id_obat
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

  // --- FAVORITES (SQLite Persistent) ---
  Future<bool> isFavorite(int id) async {
    final db = await instance.database;
    final maps = await db.query('favorit', where: 'id_obat = ?', whereArgs: [id]);
    return maps.isNotEmpty;
  }

  Future<void> toggleFavorite(int id) async {
    final db = await instance.database;
    final exists = await isFavorite(id);
    if (exists) {
      await db.delete('favorit', where: 'id_obat = ?', whereArgs: [id]);
    } else {
      await db.insert('favorit', {'id_obat': id});
    }
  }

  Future<List<MedicineSimple>> getFavorites() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT obat.* FROM obat 
      JOIN favorit ON obat.id = favorit.id_obat
    ''');
    return result.map((json) => MedicineSimple.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
