import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/question_service.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Question? _question;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _question = ModalRoute.of(context)?.settings.arguments as Question?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _question;

    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('问题详情')),
        body: const Center(child: Text('问题不存在')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('问题详情'),
        actions: [
          if (question.status == QuestionStatus.pending)
            TextButton(
              onPressed: _isLoading ? null : () => _completeQuestion(question),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('完成'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态标签
            Row(
              children: [
                _buildStatusChip(question.status),
                const SizedBox(width: 8),
                _buildPriorityChip(question.priority),
              ],
            ),
            const SizedBox(height: 16),

            // 内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 信息列表
            _buildInfoSection(theme, question),
            const SizedBox(height: 24),

            // 操作按钮
            if (question.status == QuestionStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _completeQuestion(question),
                      icon: const Icon(Icons.check),
                      label: const Text('标记完成'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteQuestion(question),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('删除', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(QuestionStatus status) {
    final colors = {
      QuestionStatus.pending: Colors.orange,
      QuestionStatus.completed: Colors.green,
      QuestionStatus.archived: Colors.grey,
    };

    final labels = {
      QuestionStatus.pending: '待处理',
      QuestionStatus.completed: '已完成',
      QuestionStatus.archived: '已归档',
    };

    return Chip(
      label: Text(labels[status]!),
      backgroundColor: colors[status]!.withOpacity(0.1),
      labelStyle: TextStyle(
        color: colors[status],
        fontWeight: FontWeight.bold,
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildPriorityChip(QuestionPriority priority) {
    final colors = {
      QuestionPriority.normal: Colors.grey,
      QuestionPriority.important: Colors.orange,
      QuestionPriority.urgent: Colors.red,
    };

    return Chip(
      label: Text(priority.displayName),
      backgroundColor: colors[priority]!.withOpacity(0.1),
      labelStyle: TextStyle(
        color: colors[priority],
        fontWeight: FontWeight.bold,
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoSection(ThemeData theme, Question question) {
    return Column(
      children: [
        _buildInfoTile(
          icon: Icons.category,
          title: '类别',
          value: '${question.category.icon} ${question.category.displayName}',
        ),
        const Divider(),
        _buildInfoTile(
          icon: Icons.access_time,
          title: '创建时间',
          value: _formatDateTime(question.createdAt),
        ),
        const Divider(),
        if (question.reminderAt != null) ...[
          _buildInfoTile(
            icon: Icons.notifications,
            title: '提醒时间',
            value: _formatDateTime(question.reminderAt!),
            valueColor: theme.colorScheme.primary,
          ),
          const Divider(),
        ],
        if (question.deadlineAt != null) ...[
          _buildInfoTile(
            icon: Icons.event,
            title: '截止日期',
            value: _formatDate(question.deadlineAt!),
            valueColor: _isOverdue(question.deadlineAt!) ? Colors.red : null,
          ),
          const Divider(),
        ],
        if (question.reminderRepeat != null) ...[
          _buildInfoTile(
            icon: Icons.repeat,
            title: '重复规则',
            value: _getRepeatLabel(question.reminderRepeat!),
          ),
          const Divider(),
        ],
        if (question.hasVoice) ...[
          _buildInfoTile(
            icon: Icons.mic,
            title: '输入方式',
            value: '语音输入',
          ),
          const Divider(),
        ],
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeQuestion(Question question) async {
    setState(() => _isLoading = true);

    try {
      await QuestionService.completeQuestion(question.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await QuestionService.deleteQuestion(question.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  bool _isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  String _getRepeatLabel(String repeat) {
    switch (repeat) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      default:
        return repeat;
    }
  }
}
