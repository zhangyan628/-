import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'question_reminder.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 创建问题表
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        category INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deadline_at INTEGER,
        reminder_at INTEGER,
        reminder_repeat TEXT,
        has_voice INTEGER NOT NULL DEFAULT 0,
        voice_duration INTEGER
      )
    ''');

    // 创建标签表
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT '#2196F3'
      )
    ''');

    // 创建问题-标签关联表
    await db.execute('''
      CREATE TABLE question_tags (
        question_id TEXT,
        tag_id INTEGER,
        FOREIGN KEY (question_id) REFERENCES questions(id),
        FOREIGN KEY (tag_id) REFERENCES tags(id),
        PRIMARY KEY (question_id, tag_id)
      )
    ''');

    // 插入默认标签
    await db.insert('tags', {'name': '工作', 'color': '#FF5722'});
    await db.insert('tags', {'name': '生活', 'color': '#4CAF50'});
    await db.insert('tags', {'name': '学习', 'color': '#2196F3'});
    await db.insert('tags', {'name': '健康', 'color': '#E91E63'});
    await db.insert('tags', {'name': '财务', 'color': '#FF9800'});
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
