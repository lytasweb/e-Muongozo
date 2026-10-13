import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/topic.dart';

class DbService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'emuongozo.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, v) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS subjects');
        await db.execute('DROP TABLE IF EXISTS topics');
        await db.execute('DROP TABLE IF EXISTS blocks');
        await db.execute('DROP TABLE IF EXISTS bookmarks');
        await db.execute('DROP TABLE IF EXISTS progress');
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        category TEXT,
        icon TEXT,
        color TEXT,
        topic_count INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        term INTEGER NOT NULL,
        title TEXT NOT NULL,
        badge TEXT,
        teaching_schemes TEXT,
        recommended_books TEXT,
        synced_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        ord INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE received_bundles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        topic_count INTEGER NOT NULL,
        received_at INTEGER NOT NULL,
        sender_name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE progress (
        topic_id INTEGER PRIMARY KEY,
        last_position INTEGER,
        updated_at INTEGER
      )
    ''');
  }

  // ---------------- Subjects ----------------

  static Future<void> saveSubjects(List<Subject> subjects) async {
    final db = await database;
    final batch = db.batch();
    for (final s in subjects) {
      batch.insert('subjects', s.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  static Future<List<Map<String, dynamic>>> getSubjects() async {
    final db = await database;
    return db.query('subjects', orderBy: 'name');
  }

  // ---------------- Topics ----------------

  static Future<void> saveTopics(List<Topic> topics) async {
    if (topics.isEmpty) return;

    final db = await database;
    final subjectId = topics.first.subjectId;
    final term = topics.first.term;

    final oldTopics = await db.query(
      'topics',
      columns: ['id'],
      where: 'subject_id = ? AND term = ?',
      whereArgs: [subjectId, term],
    );

    final batch = db.batch();
    for (final o in oldTopics) {
      batch.delete('blocks', where: 'topic_id = ?', whereArgs: [o['id']]);
    }
    batch.delete('topics',
        where: 'subject_id = ? AND term = ?', whereArgs: [subjectId, term]);

    for (final t in topics) {
      batch.insert(
        'topics',
        {
          'id': t.id,
          'subject_id': t.subjectId,
          'term': t.term,
          'title': t.title,
          'badge': t.badge,
          'teaching_schemes': jsonEncode(t.teachingSchemes),
          'recommended_books': jsonEncode(t.recommendedBooks),
          'synced_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final b in t.blocks) {
        batch.insert('blocks', {
          'topic_id': t.id,
          'type': b.type.name,
          'content': b.content,
          'ord': b.order,
        });
      }
    }
    await batch.commit();
  }

  static Future<List<Map<String, dynamic>>> getTopics(
      int subjectId, int term) async {
    final db = await database;
    return db.query(
      'topics',
      where: 'subject_id = ? AND term = ?',
      whereArgs: [subjectId, term],
      orderBy: 'id',
    );
  }

  static Future<List<Map<String, dynamic>>> getBlocks(int topicId) async {
    final db = await database;
    return db.query(
      'blocks',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'ord',
    );
  }

  static Future<bool> isSynced(int subjectId, int term) async {
    final db = await database;
    final r = await db.query(
      'topics',
      where: 'subject_id = ? AND term = ?',
      whereArgs: [subjectId, term],
      limit: 1,
    );
    return r.isNotEmpty;
  }

  // ---------------- Bookmarks ----------------

  static Future<void> toggleBookmark(int topicId) async {
    final db = await database;
    final existing = await db.query(
      'bookmarks',
      where: 'topic_id = ?',
      whereArgs: [topicId],
    );
    if (existing.isEmpty) {
      await db.insert('bookmarks', {
        'topic_id': topicId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.delete('bookmarks',
          where: 'topic_id = ?', whereArgs: [topicId]);
    }
  }

  static Future<List<int>> getBookmarkIds() async {
    final db = await database;
    final r = await db.query('bookmarks');
    return r.map((row) => row['topic_id'] as int).toList();
  }

  static Future<List<Map<String, dynamic>>> getBookmarkedTopics() async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.id AS topic_id, t.title, t.badge, b.created_at
      FROM bookmarks b
      JOIN topics t ON t.id = b.topic_id
      ORDER BY b.created_at DESC
    ''');
  }

  // ---------------- Progress ----------------

  static Future<void> saveProgress(int topicId, int lastPosition) async {
    final db = await database;
    await db.insert(
      'progress',
      {
        'topic_id': topicId,
        'last_position': lastPosition,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int?> getProgress(int topicId) async {
    final db = await database;
    final r = await db.query(
      'progress',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return r.first['last_position'] as int?;
  }

  static Future<List<Map<String, dynamic>>> getRecentlyRead(
      {int limit = 5}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.id AS topic_id, t.title, p.updated_at
      FROM progress p
      JOIN topics t ON t.id = p.topic_id
      ORDER BY p.updated_at DESC
      LIMIT ?
    ''', [limit]);
  }

  // ---------------- Search ----------------

  static Future<List<Map<String, dynamic>>> searchTopics(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final db = await database;
    final like = '%${q.toLowerCase()}%';
    return db.rawQuery(
      '''
      SELECT DISTINCT t.id, t.title, t.subject_id, t.term, t.badge,
             s.name AS subject_name
      FROM topics t
      LEFT JOIN subjects s ON s.id = t.subject_id
      WHERE LOWER(t.title) LIKE ?
         OR EXISTS (
           SELECT 1 FROM blocks b
           WHERE b.topic_id = t.id AND LOWER(b.content) LIKE ?
         )
      ORDER BY t.title
      LIMIT 50
      ''',
      [like, like],
    );
  }


  /// Returns the full topic row (including teacher content) by id.
  /// Used by the reader to fetch teaching_schemes and recommended_books.
  static Future<Map<String, dynamic>?> getTopicMeta(int topicId) async {
    final db = await database;
    final r = await db.query(
      'topics',
      where: 'id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    if (r.isEmpty) return null;
    final row = Map<String, dynamic>.from(r.first);
    for (final k in ['teaching_schemes', 'recommended_books']) {
      final v = row[k];
      if (v is String && v.isNotEmpty) {
        try {
          row[k] = jsonDecode(v);
        } catch (_) {
          row[k] = <String>[];
        }
      } else if (v == null) {
        row[k] = <String>[];
      }
    }
    return row;
  }


  // ---------------- P2P transfer ----------------

  /// Serializes an entire subject (all terms, all topics, all blocks) as
  /// a JSON-encodable map for P2P transfer.
  static Future<Map<String, dynamic>?> exportSubjectBundle(
      int subjectId) async {
    final db = await database;

    // Subject row
    final subjRows = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [subjectId],
      limit: 1,
    );
    if (subjRows.isEmpty) return null;

    // Topics
    final topicRows = await db.query(
      'topics',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'term, id',
    );

    final topics = <Map<String, dynamic>>[];
    for (final t in topicRows) {
      final blocks = await db.query(
        'blocks',
        where: 'topic_id = ?',
        whereArgs: [t['id']],
        orderBy: 'ord',
      );
      topics.add({
        'id': t['id'],
        'subject_id': t['subject_id'],
        'term': t['term'],
        'title': t['title'],
        'badge': t['badge'],
        'blocks': blocks
            .map((b) => {
                  'type': b['type'],
                  'content': b['content'],
                  'ord': b['ord'],
                })
            .toList(),
      });
    }

    return {
      'type': 'subject_share',
      'subject': Map<String, dynamic>.from(subjRows.first),
      'topics': topics,
    };
  }

  /// Imports a subject bundle received over P2P. Merges into local DB.
  /// Returns the number of topics imported.
  static Future<int> importSubjectBundle(Map<String, dynamic> bundle) async {
    final db = await database;

    // 1. Save the subject row
    final subject = bundle['subject'] as Map<String, dynamic>?;
    if (subject != null) {
      await db.insert(
        'subjects',
        Map<String, dynamic>.from(subject),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Save topics + blocks
    final topics = (bundle['topics'] as List?) ?? const [];
    final batch = db.batch();
    for (final raw in topics) {
      final t = Map<String, dynamic>.from(raw as Map);
      final topicId = t['id'];

      // Clear old blocks for this topic
      batch.delete('blocks', where: 'topic_id = ?', whereArgs: [topicId]);

      batch.insert(
        'topics',
        {
          'id': topicId,
          'subject_id': t['subject_id'],
          'term': t['term'],
          'title': t['title'],
          'badge': t['badge'],
          'teaching_schemes': null,
          'recommended_books': null,
          'synced_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final rawBlock in (t['blocks'] as List?) ?? const []) {
        final b = Map<String, dynamic>.from(rawBlock as Map);
        batch.insert('blocks', {
          'topic_id': topicId,
          'type': b['type'],
          'content': b['content'],
          'ord': b['ord'],
        });
      }
    }
    await batch.commit();
    return topics.length;
  }


  // ---------------- Received bundles (P2P history) ----------------

  static Future<void> recordReceivedBundle({
    required int subjectId,
    required String subjectName,
    required int topicCount,
    String? senderName,
  }) async {
    final db = await database;
    await db.insert('received_bundles', {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'topic_count': topicCount,
      'received_at': DateTime.now().millisecondsSinceEpoch,
      'sender_name': senderName,
    });
  }

  static Future<List<Map<String, dynamic>>> getReceivedBundles() async {
    final db = await database;
    return db.query('received_bundles', orderBy: 'received_at DESC');
  }

  // ---------------- Dev reset ----------------

  static Future<void> resetDatabase() async {
    final path = join(await getDatabasesPath(), 'emuongozo.db');
    await deleteDatabase(path);
    _db = null;
  }
}
