import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const QuestionCard({
    super.key,
    required this.question,
    this.onComplete,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.4,
          children: [
            if (onComplete != null)
              SlidableAction(
                onPressed: (_) => onComplete!(),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.check,
                label: '完成',
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            if (onDelete != null)
              SlidableAction(
                onPressed: (_) => _showDeleteConfirm(context),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: '删除',
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
          ],
        ),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 类别图标
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getCategoryColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            question.category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // 内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.content,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // 标签行
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // 类别标签
                                _buildChip(
                                  question.category.displayName,
                                  _getCategoryColor(),
                                ),
                                
                                // 优先级标签
                                if (question.priority != QuestionPriority.normal)
                                  _buildChip(
                                    question.priority.displayName,
                                    _getPriorityColor(),
                                  ),
                                
                                // 语音标签
                                if (question.hasVoice)
                                  _buildChip(
                                    '🎤 语音',
                                    Colors.purple,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 底部信息
                  if (question.reminderAt != null || question.deadlineAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          if (question.reminderAt != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(question.reminderAt!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                          
                          if (question.deadlineAt != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.event,
                              size: 14,
                              color: _isOverdue(question.deadlineAt!) 
                                  ? Colors.red 
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '截止: ${_formatDate(question.deadlineAt!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isOverdue(question.deadlineAt!)
                                    ? Colors.red
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (question.category) {
      case QuestionCategory.work:
        return Colors.orange;
      case QuestionCategory.life:
        return Colors.green;
      case QuestionCategory.study:
        return Colors.blue;
      case QuestionCategory.health:
        return Colors.pink;
      case QuestionCategory.finance:
        return Colors.amber;
    }
  }

  Color _getPriorityColor() {
    switch (question.priority) {
      case QuestionPriority.normal:
        return Colors.grey;
      case QuestionPriority.important:
        return Colors.orange;
      case QuestionPriority.urgent:
        return Colors.red;
    }
  }

  bool _isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (date == today) {
      dateStr = '今天';
    } else if (date == today.subtract(const Duration(days: 1))) {
      dateStr = '昨天';
    } else {
      dateStr = '${dateTime.month}月${dateTime.day}日';
    }
    
    return '$dateStr ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
