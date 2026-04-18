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
      join(dbPath, 'lumina_rag.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rag_chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doc_id TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            text TEXT NOT NULL,
            embedding TEXT NOT NULL,
            source_name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE rag_documents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            chunk_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL
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
    final rows = await database.query('rag_chunks');
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
    await database.delete('rag_documents', where: 'id = ?', whereArgs: [docId]);
    await deleteChunksByDocId(docId);
  }

  Future<void> clearAll() async {
    final database = await db;
    await database.delete('rag_chunks');
    await database.delete('rag_documents');
  }
}
