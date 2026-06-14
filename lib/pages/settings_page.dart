import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_service.dart';
import '../services/notification_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 数据管理
          _buildSectionHeader(context, '数据管理'),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('已完成的问题'),
            subtitle: const Text('查看已归档的问题记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCompletedQuestions(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('清理已完成'),
            subtitle: const Text('删除所有已完成的问题'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearCompletedDialog(context);
            },
          ),
          const Divider(),

          // 通知设置
          _buildSectionHeader(context, '通知设置'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('通知权限'),
            subtitle: const Text('管理提醒通知权限'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await NotificationService.requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已请求通知权限')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined),
            title: const Text('取消所有提醒'),
            subtitle: const Text('清除所有待发送的提醒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCancelAllRemindersDialog(context);
            },
          ),
          const Divider(),

          // 外观设置
          _buildSectionHeader(context, '外观设置'),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('主题模式'),
            subtitle: const Text('跟随系统'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 主题设置
            },
          ),
          const Divider(),

          // 关于
          _buildSectionHeader(context, '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于应用'),
            subtitle: const Text('版本 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '问题记录',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '个人问题记录与提醒应用',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '支持语音输入、手动输入，按种类和时间分类，提供智能提醒功能。',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showCompletedQuestions(BuildContext context) async {
    final questions = await QuestionService.getQuestionsByStatus(QuestionStatus.completed);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              AppBar(
                title: const Text('已完成的问题'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                automaticallyImplyLeading: false,
              ),
              Expanded(
                child: questions.isEmpty
                    ? const Center(child: Text('暂无已完成的问题'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return ListTile(
                            leading: Text(question.category.icon),
                            title: Text(
                              question.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '完成于 ${_formatDate(question.updatedAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await QuestionService.deleteQuestion(question.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showCompletedQuestions(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showClearCompletedDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清理'),
        content: const Text('将删除所有已完成的问题，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清理'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final questions = await QuestionService.getQuestionsByStatus(QuestionStatus.completed);
      for (final question in questions) {
        await QuestionService.deleteQuestion(question.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清理 ${questions.length} 个问题')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败: $e')),
        );
      }
    }
  }

  Future<void> _showCancelAllRemindersDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消'),
        content: const Text('将取消所有待发送的提醒通知。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await NotificationService.cancelAllReminders();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消所有提醒')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
