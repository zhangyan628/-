import 'package:sqflite/sqflite.dart';
import '../models/question.dart';
import 'database_service.dart';
import 'notification_service.dart';

class QuestionService {
  static Future<Database> get _db async => await DatabaseService.database;

  // 创建问题
  static Future<Question> createQuestion({
    required String content,
    required QuestionCategory category,
    QuestionPriority priority = QuestionPriority.normal,
    DateTime? deadline,
    DateTime? reminder,
    String? reminderRepeat,
    bool hasVoice = false,
    int? voiceDuration,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    
    final question = Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      category: category,
      priority: priority,
      createdAt: now,
      updatedAt: now,
      deadlineAt: deadline,
      reminderAt: reminder,
      reminderRepeat: reminderRepeat,
      hasVoice: hasVoice,
      voiceDuration: voiceDuration,
    );
    
    await db.insert('questions', question.toMap());
    
    // 如果有提醒，设置本地通知
    if (reminder != null) {
      await NotificationService.scheduleReminder(question);
    }
    
    return question;
  }

  // 获取所有问题
  static Future<List<Question>> getAllQuestions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // 获取待处理问题
  static Future<List<Question>> getPendingQuestions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'status = ?',
      whereArgs: [QuestionStatus.pending.index],
      orderBy: 'priority DESC, created_at DESC',
    );
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // 按时间分组查询
  static Future<Map<String, List<Question>>> getQuestionsGroupedByTime() async {
    final questions = await getPendingQuestions();
    
    final grouped = <String, List<Question>>{};
    for (final q in questions) {
      final group = _getTimeGroup(q.createdAt);
      grouped.putIfAbsent(group, () => []).add(q);
    }
    
    // 确保顺序
    final ordered = <String, List<Question>>{};
    final groups = ['今天', '昨天', '本周', '本月', '更早'];
    for (final group in groups) {
      if (grouped.containsKey(group)) {
        ordered[group] = grouped[group]!;
      }
    }
    
    return ordered;
  }

  // 按类别查询
  static Future<List<Question>> getQuestionsByCategory(QuestionCategory category) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'category = ? AND status = ?',
      whereArgs: [category.index, QuestionStatus.pending.index],
      orderBy: 'priority DESC, created_at DESC',
    );
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // 按状态查询
  static Future<List<Question>> getQuestionsByStatus(QuestionStatus status) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // 获取单个问题
  static Future<Question?> getQuestionById(String id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Question.fromMap(maps.first);
  }

  // 更新问题
  static Future<void> updateQuestion(Question question) async {
    final db = await _db;
    final updated = question.copyWith(updatedAt: DateTime.now());
    
    await db.update(
      'questions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
    
    // 更新提醒
    if (updated.reminderAt != null) {
      await NotificationService.cancelReminder(updated.id);
      await NotificationService.scheduleReminder(updated);
    }
  }

  // 完成问题
  static Future<void> completeQuestion(String id) async {
    final db = await _db;
    final question = await getQuestionById(id);
    if (question == null) return;
    
    final updated = question.copyWith(
      status: QuestionStatus.completed,
      updatedAt: DateTime.now(),
    );
    
    await db.update(
      'questions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 取消提醒
    await NotificationService.cancelReminder(id);
  }

  // 删除问题
  static Future<void> deleteQuestion(String id) async {
    final db = await _db;
    await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 取消提醒
    await NotificationService.cancelReminder(id);
  }

  // 搜索问题
  static Future<List<Question>> searchQuestions(String keyword) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'content LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // 获取统计数据
  static Future<Map<String, int>> getStatistics() async {
    final db = await _db;
    
    // 待处理数量
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE status = ?',
      [QuestionStatus.pending.index],
    );
    
    // 已完成数量
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE status = ?',
      [QuestionStatus.completed.index],
    );
    
    // 今日新增
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE created_at >= ?',
      [todayStart.millisecondsSinceEpoch],
    );
    
    return {
      'pending': pendingResult.first['count'] as int,
      'completed': completedResult.first['count'] as int,
      'today': todayResult.first['count'] as int,
    };
  }

  // 时间分组逻辑
  static String _getTimeGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;
    
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff < 7) return '本周';
    if (diff < 30) return '本月';
    return '更早';
  }
}
