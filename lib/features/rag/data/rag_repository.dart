import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:se_hack/features/rag/data/models/rag_chunk.dart';
import 'package:se_hack/features/rag/data/models/rag_document.dart';

class RagRepository {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'lumina_rag_v4.db'),
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rag_chunks (
            doc_id TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            text TEXT NOT NULL,
            source_name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE rag_documents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            chunk_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            local_path TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── Chunks ──────────────────────────────────────────────────────────────

  Future<void> insertChunks(List<RagChunk> chunks) async {
    final database = await db;
    final batch = database.batch();
    for (final chunk in chunks) {
      batch.insert('rag_chunks', chunk.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<RagChunk>> getAllChunks() async {
    final database = await db;
    // Selecting rowid alongside the default columns
    final rows = await database.rawQuery('SELECT rowid, * FROM rag_chunks');
    return rows.map(RagChunk.fromMap).toList();
  }

  Future<List<RagChunk>> searchChunks(String queryText) async {
    final database = await db;
    
    final cleanQuery = queryText.replaceAll('"', ' ').trim();
    if (cleanQuery.isEmpty) return [];
    
    final words = cleanQuery.split(RegExp(r'\s+')).where((e) => e.length > 2).toList();
    if (words.isEmpty) return [];

    // Standard SQLite LIKE query to avoid FTS module errors on Android
    final whereClause = words.map((w) => 'text LIKE ?').join(' OR ');
    final args = words.map((w) => '%$w%').toList();

    final rows = await database.rawQuery('''
      SELECT rowid, * FROM rag_chunks 
      WHERE $whereClause 
      LIMIT 10
    ''', args);
    return rows.map(RagChunk.fromMap).toList();
  }

  Future<void> deleteChunksByDocId(String docId) async {
    final database = await db;
    await database.delete('rag_chunks', where: 'doc_id = ?', whereArgs: [docId]);
  }

  // ── Documents ────────────────────────────────────────────────────────────

  Future<void> insertDocument(RagDocument doc) async {
    final database = await db;
    await database.insert('rag_documents', doc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RagDocument>> getAllDocuments() async {
    final database = await db;
    final rows = await database.query('rag_documents', orderBy: 'created_at DESC');
    return rows.map(RagDocument.fromMap).toList();
  }

  Future<void> deleteDocument(String docId) async {
    final database = await db;
    // Find the doc so we can delete its physical file
    final rows = await database.query('rag_documents', where: 'id = ?', whereArgs: [docId]);
    if (rows.isNotEmpty) {
      final doc = RagDocument.fromMap(rows.first);
      if (doc.localPath.isNotEmpty) {
        try {
          final file = File(doc.localPath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          print('Failed to delete physical file: \$e');
        }
      }
    }

    await database.delete('rag_documents', where: 'id = ?', whereArgs: [docId]);
    await deleteChunksByDocId(docId);
  }

  Future<void> clearAll() async {
    final database = await db;
    await database.delete('rag_chunks');
    await database.delete('rag_documents');
  }
}
