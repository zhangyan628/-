import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../widgets/question_card.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  QuestionCategory? _category;
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _category = ModalRoute.of(context)?.settings.arguments as QuestionCategory?;
    if (_category != null) {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    if (_category == null) return;

    setState(() => _isLoading = true);

    try {
      final questions = await QuestionService.getQuestionsByCategory(_category!);
      setState(() => _questions = questions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = _category;

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('分类')),
        body: const Center(child: Text('无效的类别')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(category.icon),
            const SizedBox(width: 8),
            Text('${category.displayName}问题'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadQuestions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questions.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return QuestionCard(
                        question: question,
                        onComplete: () async {
                          await QuestionService.completeQuestion(question.id);
                          _loadQuestions();
                        },
                        onDelete: () async {
                          await QuestionService.deleteQuestion(question.id);
                          _loadQuestions();
                        },
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/detail',
                            arguments: question,
                          );
                          if (result == true) {
                            _loadQuestions();
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无${_category?.displayName}问题',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加新问题',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
