import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const _createTransactionsTable = '''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_name TEXT NOT NULL,
    user_id INTEGER,
    amount REAL,
    status TEXT NOT NULL,
    hand TEXT,
    match_score REAL,
    created_at TEXT NOT NULL
  )
''';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'palmpay.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            embedding TEXT NOT NULL,
            flipped_embedding TEXT,
            hand TEXT NOT NULL DEFAULT 'sağ',
            pin_hash TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            embedding TEXT NOT NULL,
            flipped_embedding TEXT,
            image_path TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');
        await db.execute(_createTransactionsTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS samples (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              embedding TEXT NOT NULL,
              flipped_embedding TEXT,
              image_path TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }
        if (oldVersion < 3) {
          try { await db.execute('ALTER TABLE users ADD COLUMN flipped_embedding TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE users ADD COLUMN hand TEXT NOT NULL DEFAULT "sağ"'); } catch (_) {}
          try { await db.execute('ALTER TABLE samples ADD COLUMN flipped_embedding TEXT'); } catch (_) {}
        }
        if (oldVersion < 4) {
          await db.execute(_createTransactionsTable);
        }
        if (oldVersion < 5) {
          try { await db.execute('ALTER TABLE users ADD COLUMN pin_hash TEXT'); } catch (_) {}
        }
      },
    );
  }

  Future<int> saveUser(
    String name,
    List<List<double>> embeddings,
    List<List<double>> flippedEmbeddings,
    List<String> imagePaths,
    String hand,
  ) async {
    final db = await database;
    final avg = _computeAverage(embeddings);
    final flippedAvg = flippedEmbeddings.isNotEmpty
        ? _computeAverage(flippedEmbeddings) : null;

    final userId = await db.insert('users', {
      'name': name,
      'embedding': jsonEncode(avg),
      'flipped_embedding': flippedAvg != null ? jsonEncode(flippedAvg) : null,
      'hand': hand,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (int i = 0; i < embeddings.length; i++) {
      await db.insert('samples', {
        'user_id': userId,
        'embedding': jsonEncode(embeddings[i]),
        'flipped_embedding': i < flippedEmbeddings.length
            ? jsonEncode(flippedEmbeddings[i]) : null,
        'image_path': i < imagePaths.length ? imagePaths[i] : null,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return userId;
  }

  Future<void> addSample(
    int userId,
    List<double> embedding,
    List<double> flippedEmbedding,
    String imagePath,
  ) async {
    final db = await database;
    await db.insert('samples', {
      'user_id': userId,
      'embedding': jsonEncode(embedding),
      'flipped_embedding': jsonEncode(flippedEmbedding),
      'image_path': imagePath,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _updateAverageEmbedding(db, userId);
  }

  Future<void> deleteSample(int sampleId, int userId) async {
    final db = await database;
    await db.delete('samples', where: 'id = ?', whereArgs: [sampleId]);
    await _updateAverageEmbedding(db, userId);
  }

  Future<void> _updateAverageEmbedding(Database db, int userId) async {
    final samples = await db.query('samples',
        where: 'user_id = ?', whereArgs: [userId]);
    if (samples.isEmpty) return;

    final embeddings = samples
        .map((s) => List<double>.from(jsonDecode(s['embedding'] as String)))
        .toList();
    final avg = _computeAverage(embeddings);

    final flippedList = samples
        .where((s) => s['flipped_embedding'] != null)
        .map((s) => List<double>.from(
            jsonDecode(s['flipped_embedding'] as String)))
        .toList();
    final flippedAvg =
        flippedList.isNotEmpty ? _computeAverage(flippedList) : null;

    await db.update(
      'users',
      {
        'embedding': jsonEncode(avg),
        if (flippedAvg != null) 'flipped_embedding': jsonEncode(flippedAvg),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getUserSamples(int userId) async {
    final db = await database;
    return db.query('samples',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at ASC');
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users', orderBy: 'created_at DESC');
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('samples', where: 'user_id = ?', whereArgs: [id]);
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllData() async {
    final db = await database;
    final samples = await db.query('samples', columns: ['image_path']);
    for (final sample in samples) {
      final path = sample['image_path'] as String?;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    await db.delete('samples');
    await db.delete('users');
    await db.delete('transactions');
  }

  // ── İşlem geçmişi ──────────────────────────────────────────────────

  Future<void> saveTransaction({
    required String userName,
    int? userId,
    double? amount,
    required bool isSuccess,
    String? hand,
    double? matchScore,
  }) async {
    final db = await database;
    await db.insert('transactions', {
      'user_name': userName,
      'user_id': userId,
      'amount': amount,
      'status': isSuccess ? 'success' : 'failed',
      'hand': hand,
      'match_score': matchScore,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return db.query('transactions', orderBy: 'created_at DESC');
  }

  Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  // Eşleşme bul — sadece seçilen elle kayıtlı kullanıcılarla karşılaştır
  Future<Map<String, dynamic>?> findBestMatch(
    List<double> embedding,
    String selectedHand,
  ) async {
    final db = await database;
    // Sadece seçilen elle kayıtlı kullanıcıları getir
    final users = await db.query(
      'users',
      where: 'hand = ?',
      whereArgs: [selectedHand],
    );
    if (users.isEmpty) return null;

    double bestScore = -1;
    Map<String, dynamic>? bestUser;

    for (final user in users) {
      final stored =
          List<double>.from(jsonDecode(user['embedding'] as String));
      final score = _cosineSimilarity(embedding, stored);
      if (score > bestScore) {
        bestScore = score;
        bestUser = user;
      }
    }

    if (bestUser == null || bestScore < 0.6) return null;

    return {
      'name': bestUser['name'],
      'score': bestScore,
      'id': bestUser['id'],
      'hand': bestUser['hand'],
    };
  }

  List<double> _computeAverage(List<List<double>> embeddings) {
    final avg = List<double>.filled(512, 0.0);
    for (final e in embeddings) {
      for (int i = 0; i < 512; i++) avg[i] += e[i];
    }
    final n = embeddings.length.toDouble();
    return avg.map((v) => v / n).toList();
  }

  // ── PIN yönetimi ────────────────────────────────────────────────────

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> savePin(int userId, String pin) async {
    final db = await database;
    await db.update(
      'users',
      {'pin_hash': _hashPin(pin)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> verifyUserPin(int userId, String pin) async {
    final db = await database;
    final rows = await db.query(
      'users',
      columns: ['pin_hash'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return false;
    final stored = rows.first['pin_hash'] as String?;
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}