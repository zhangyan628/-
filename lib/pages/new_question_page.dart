import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/speech_service.dart';
import '../providers/question_provider.dart';

class NewQuestionPage extends ConsumerStatefulWidget {
  const NewQuestionPage({super.key});

  @override
  ConsumerState<NewQuestionPage> createState() => _NewQuestionPageState();
}

class _NewQuestionPageState extends ConsumerState<NewQuestionPage> {
  final _contentController = TextEditingController();
  QuestionCategory _selectedCategory = QuestionCategory.work;
  QuestionPriority _selectedPriority = QuestionPriority.normal;
  DateTime? _reminderTime;
  DateTime? _deadline;
  String? _reminderRepeat;
  bool _isRecording = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': QuestionCategory.work, 'label': '工作', 'icon': '💼', 'color': Colors.orange},
    {'value': QuestionCategory.life, 'label': '生活', 'icon': '🏠', 'color': Colors.green},
    {'value': QuestionCategory.study, 'label': '学习', 'icon': '📚', 'color': Colors.blue},
    {'value': QuestionCategory.health, 'label': '健康', 'icon': '❤️', 'color': Colors.pink},
    {'value': QuestionCategory.finance, 'label': '财务', 'icon': '💰', 'color': Colors.amber},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': QuestionPriority.normal, 'label': '普通', 'color': Colors.grey},
    {'value': QuestionPriority.important, 'label': '重要', 'color': Colors.orange},
    {'value': QuestionPriority.urgent, 'label': '紧急', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _repeatOptions = [
    {'value': null, 'label': '不重复'},
    {'value': 'daily', 'label': '每天'},
    {'value': 'weekly', 'label': '每周'},
    {'value': 'monthly', 'label': '每月'},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新建问题'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveQuestion,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 语音输入按钮
            Center(
              child: GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 100 : 80,
                  height: _isRecording ? 100 : 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : theme.colorScheme.primary)
                            .withOpacity(0.3),
                        blurRadius: _isRecording ? 20 : 10,
                        spreadRadius: _isRecording ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isRecording ? '正在录音...' : '长按说话',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 内容输入
            TextField(
              controller: _contentController,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                hintText: '请输入问题内容...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // 类别选择
            Text(
              '类别',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['value'];
                return ChoiceChip(
                  avatar: Text(cat['icon']),
                  label: Text(cat['label']),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat['value']);
                  },
                  selectedColor: cat['color'].withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? cat['color'] : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 优先级选择
            Text(
              '优先级',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: _priorities.map((pri) {
                final isSelected = _selectedPriority == pri['value'];
                return ChoiceChip(
                  label: Text(pri['label']),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedPriority = pri['value']);
                  },
                  selectedColor: pri['color'].withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? pri['color'] : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 提醒设置
            Text(
              '提醒设置',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 提醒时间
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('提醒时间'),
              subtitle: Text(
                _reminderTime != null
                    ? '${_reminderTime!.month}月${_reminderTime!.day}日 ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                    : '未设置',
              ),
              trailing: _reminderTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _reminderTime = null),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pickReminderTime,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            const SizedBox(height: 12),

            // 重复规则
            if (_reminderTime != null)
              ListTile(
                leading: const Icon(Icons.repeat),
                title: const Text('重复'),
                trailing: DropdownButton<String?>(
                  value: _reminderRepeat,
                  underline: const SizedBox(),
                  items: _repeatOptions.map((opt) {
                    return DropdownMenuItem<String?>(
                      value: opt['value'],
                      child: Text(opt['label']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _reminderRepeat = value);
                  },
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            const SizedBox(height: 12),

            // 截止日期
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('截止日期'),
              subtitle: Text(
                _deadline != null
                    ? '${_deadline!.year}年${_deadline!.month}月${_deadline!.day}日'
                    : '未设置',
              ),
              trailing: _deadline != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pickDeadline,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final available = await SpeechService.isAvailable;
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音识别不可用')),
        );
      }
      return;
    }

    setState(() => _isRecording = true);

    await SpeechService.startListening(
      onResult: (text) {
        setState(() {
          _contentController.text = text;
        });
      },
      onDone: () {
        setState(() => _isRecording = false);
      },
    );
  }

  Future<void> _stopRecording() async {
    await SpeechService.stopListening();
    setState(() => _isRecording = false);
  }

  Future<void> _pickReminderTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  Future<void> _saveQuestion() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入问题内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await QuestionService.createQuestion(
        content: content,
        category: _selectedCategory,
        priority: _selectedPriority,
        reminder: _reminderTime,
        reminderRepeat: _reminderRepeat,
        deadline: _deadline,
        hasVoice: false,
      );

      if (mounted) {
        ref.read(refreshProvider.notifier).state++;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
