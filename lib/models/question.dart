import 'package:uuid/uuid.dart';

enum QuestionCategory { work, life, study, health, finance }

enum QuestionPriority { normal, important, urgent }

enum QuestionStatus { pending, completed, archived }

class Question {
  final String id;
  final String content;
  final QuestionCategory category;
  final QuestionPriority priority;
  final QuestionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deadlineAt;
  final DateTime? reminderAt;
  final String? reminderRepeat;
  final bool hasVoice;
  final int? voiceDuration;

  Question({
    required this.id,
    required this.content,
    required this.category,
    this.priority = QuestionPriority.normal,
    this.status = QuestionStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.deadlineAt,
    this.reminderAt,
    this.reminderRepeat,
    this.hasVoice = false,
    this.voiceDuration,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      content: map['content'],
      category: QuestionCategory.values[map['category']],
      priority: QuestionPriority.values[map['priority']],
      status: QuestionStatus.values[map['status']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      deadlineAt: map['deadline_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline_at']) 
          : null,
      reminderAt: map['reminder_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['reminder_at']) 
          : null,
      reminderRepeat: map['reminder_repeat'],
      hasVoice: map['has_voice'] == 1,
      voiceDuration: map['voice_duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category.index,
      'priority': priority.index,
      'status': status.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deadline_at': deadlineAt?.millisecondsSinceEpoch,
      'reminder_at': reminderAt?.millisecondsSinceEpoch,
      'reminder_repeat': reminderRepeat,
      'has_voice': hasVoice ? 1 : 0,
      'voice_duration': voiceDuration,
    };
  }

  Question copyWith({
    String? id,
    String? content,
    QuestionCategory? category,
    QuestionPriority? priority,
    QuestionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadlineAt,
    DateTime? reminderAt,
    String? reminderRepeat,
    bool? hasVoice,
    int? voiceDuration,
  }) {
    return Question(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderRepeat: reminderRepeat ?? this.reminderRepeat,
      hasVoice: hasVoice ?? this.hasVoice,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }
}

extension QuestionCategoryExtension on QuestionCategory {
  String get displayName {
    switch (this) {
      case QuestionCategory.work:
        return '工作';
      case QuestionCategory.life:
        return '生活';
      case QuestionCategory.study:
        return '学习';
      case QuestionCategory.health:
        return '健康';
      case QuestionCategory.finance:
        return '财务';
    }
  }

  String get icon {
    switch (this) {
      case QuestionCategory.work:
        return '💼';
      case QuestionCategory.life:
        return '🏠';
      case QuestionCategory.study:
        return '📚';
      case QuestionCategory.health:
        return '❤️';
      case QuestionCategory.finance:
        return '💰';
    }
  }
}

extension QuestionPriorityExtension on QuestionPriority {
  String get displayName {
    switch (this) {
      case QuestionPriority.normal:
        return '普通';
      case QuestionPriority.important:
        return '重要';
      case QuestionPriority.urgent:
        return '紧急';
    }
  }

  int get value {
    switch (this) {
      case QuestionPriority.normal:
        return 0;
      case QuestionPriority.important:
        return 1;
      case QuestionPriority.urgent:
        return 2;
    }
  }
}
