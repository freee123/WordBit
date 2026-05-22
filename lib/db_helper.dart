import 'package:sqflite/sqflite.dart';
import 'models.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/memory_words.db';
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_info (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words (
        id            TEXT PRIMARY KEY,
        word          TEXT NOT NULL,
        translation   TEXT NOT NULL,
        pronunciation TEXT,
        part_of_speech TEXT,
        example_sent  TEXT,
        tags          TEXT,
        mastery_level INTEGER DEFAULT 0,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL,
        deleted       INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE review_records (
        id          TEXT PRIMARY KEY,
        word_id     TEXT NOT NULL,
        reviewed_at INTEGER NOT NULL,
        result      INTEGER NOT NULL,
        next_review INTEGER NOT NULL,
        repetition  INTEGER DEFAULT 0,
        efactor     REAL DEFAULT 2.5,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_info (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_words_updated ON words(updated_at)');
    await db.execute(
        'CREATE INDEX idx_review_word ON review_records(word_id)');
    await db.execute(
        'CREATE INDEX idx_review_next ON review_records(next_review)');
  }

  // ---- 单词 CRUD ----

  static Future<void> insertWord(Word word) async {
    final db = await database;
    await db.insert('words', word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Word>> getWords({bool includeDeleted = false}) async {
    final db = await database;
    String where = includeDeleted ? '' : 'WHERE deleted = 0';
    final maps = await db.rawQuery(
        'SELECT * FROM words $where ORDER BY updated_at DESC');
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  static Future<Word?> getWordById(String id) async {
    final db = await database;
    final maps = await db.query('words', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Word.fromMap(maps.first);
  }

  static Future<Word?> getWordByText(String text) async {
    final db = await database;
    final maps = await db.query('words',
        where: 'word = ? AND deleted = 0', whereArgs: [text.toLowerCase().trim()]);
    if (maps.isEmpty) return null;
    return Word.fromMap(maps.first);
  }

  static Future<void> updateWord(Word word) async {
    final db = await database;
    await db.update('words', word.toMap(),
        where: 'id = ?', whereArgs: [word.id]);
  }

  static Future<void> softDeleteWord(String id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE words SET deleted = 1, updated_at = ? WHERE id = ?',
        [DateTime.now().millisecondsSinceEpoch, id]);
  }

  // ---- 复习记录 CRUD ----

  static Future<void> insertReviewRecord(ReviewRecord record) async {
    final db = await database;
    await db.insert('review_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ReviewRecord>> getReviewRecordsByWordId(
      String wordId) async {
    final db = await database;
    final maps = await db.query('review_records',
        where: 'word_id = ?',
        whereArgs: [wordId],
        orderBy: 'reviewed_at DESC');
    return maps.map((m) => ReviewRecord.fromMap(m)).toList();
  }

  static Future<ReviewRecord?> getLatestReviewForWord(String wordId) async {
    final db = await database;
    final maps = await db.query('review_records',
        where: 'word_id = ?',
        whereArgs: [wordId],
        orderBy: 'reviewed_at DESC',
        limit: 1);
    if (maps.isEmpty) return null;
    return ReviewRecord.fromMap(maps.first);
  }

  // ---- 同步用：获取变更的单词 ----

  static Future<List<Word>> getWordsSince(int timestamp) async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT * FROM words WHERE updated_at > ? ORDER BY updated_at',
        [timestamp]);
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  // ---- 同步信息存取 ----

  static Future<String?> getSyncInfo(String key) async {
    final db = await database;
    final maps = await db.query('sync_info',
        where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  static Future<void> setSyncInfo(String key, String value) async {
    final db = await database;
    await db.insert('sync_info', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
