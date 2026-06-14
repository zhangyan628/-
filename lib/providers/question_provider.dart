import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/question_service.dart';

// 问题列表状态
final questionsProvider = FutureProvider<Map<String, List<Question>>>((ref) async {
  return await QuestionService.getQuestionsGroupedByTime();
});

// 按类别筛选的问题
final questionsByCategoryProvider = FutureProvider.family<List<Question>, QuestionCategory>((ref, category) async {
  return await QuestionService.getQuestionsByCategory(category);
});

// 搜索关键词
final searchKeywordProvider = StateProvider<String>((ref) => '');

// 搜索结果
final searchResultsProvider = FutureProvider<List<Question>>((ref) async {
  final keyword = ref.watch(searchKeywordProvider);
  if (keyword.isEmpty) return [];
  return await QuestionService.searchQuestions(keyword);
});

// 当前选中的类别筛选
final selectedCategoryProvider = StateProvider<QuestionCategory?>((ref) => null);

// 统计数据
final statisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await QuestionService.getStatistics();
});

// 刷新触发器
final refreshProvider = StateProvider<int>((ref) => 0);

// 带刷新的问题列表
final questionsWithRefreshProvider = FutureProvider<Map<String, List<Question>>>((ref) async {
  ref.watch(refreshProvider);
  return await QuestionService.getQuestionsGroupedByTime();
});
