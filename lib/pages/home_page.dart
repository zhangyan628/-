import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/question.dart';
import '../providers/question_provider.dart';
import '../services/question_service.dart';
import '../widgets/question_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _CategoryTab(),
          _SettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/new');
          if (result == true) {
            ref.read(refreshProvider.notifier).state++;
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('新建'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: '分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

// 首页标签
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsWithRefreshProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // 顶部应用栏
        SliverAppBar(
          floating: true,
          title: const Text('我的问题记录'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: QuestionSearchDelegate(ref),
                );
              },
            ),
          ],
        ),

        // 统计数据卡片
        SliverToBoxAdapter(
          child: _buildStatisticsCards(ref, theme),
        ),

        // 问题列表
        questionsAsync.when(
          data: (grouped) => _buildGroupedList(grouped, ref, theme),
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SliverFillRemaining(
            child: Center(child: Text('加载失败: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(WidgetRef ref, ThemeData theme) {
    final statsAsync = ref.watch(statisticsProvider);

    return statsAsync.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatCard(
              title: '待处理',
              value: stats['pending'] ?? 0,
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: '已完成',
              value: stats['completed'] ?? 0,
              color: Colors.green,
              icon: Icons.check_circle,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: '今日新增',
              value: stats['today'] ?? 0,
              color: Colors.blue,
              icon: Icons.today,
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGroupedList(
    Map<String, List<Question>> grouped,
    WidgetRef ref,
    ThemeData theme,
  ) {
    if (grouped.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
                '暂无问题记录',
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
        ),
      );
    }

    final groups = ['今天', '昨天', '本周', '本月', '更早'];
    final slivers = <Widget>[];

    for (final group in groups) {
      final questions = grouped[group];
      if (questions == null || questions.isEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    group,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${questions.length}项',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final question = questions[index];
              return QuestionCard(
                question: question,
                onComplete: () async {
                  await QuestionService.completeQuestion(question.id);
                  ref.read(refreshProvider.notifier).state++;
                },
                onDelete: () async {
                  await QuestionService.deleteQuestion(question.id);
                  ref.read(refreshProvider.notifier).state++;
                },
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: question,
                  );
                  if (result == true) {
                    ref.read(refreshProvider.notifier).state++;
                  }
                },
              );
            },
            childCount: questions.length,
          ),
        ),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }
}

// 统计卡片
class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 分类标签
class _CategoryTab extends ConsumerWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = QuestionCategory.values;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('分类浏览'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                return _CategoryCard(category: category);
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final QuestionCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questionsAsync = ref.watch(questionsByCategoryProvider(category));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/category', arguments: category);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              questionsAsync.when(
                data: (questions) => Text(
                  '${questions.length} 个待处理问题',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('加载失败'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 设置标签
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('设置'),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('已完成的问题'),
              subtitle: const Text('查看已归档的问题记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 导航到已完成列表
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('通知设置'),
              subtitle: const Text('管理提醒通知权限'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 通知设置页面
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('主题设置'),
              subtitle: const Text('切换浅色/深色模式'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 主题设置
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于'),
              subtitle: const Text('版本 1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: '问题记录',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.check_circle, size: 48),
                  children: [
                    const Text('个人问题记录与提醒应用'),
                  ],
                );
              },
            ),
          ]),
        ),
      ],
    );
  }
}

// 搜索委托
class QuestionSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  QuestionSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResults(query: query, ref: ref);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键词搜索问题'),
      );
    }
    return _SearchResults(query: query, ref: ref);
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final WidgetRef ref;

  const _SearchResults({required this.query, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这里简化处理，直接搜索
    return FutureBuilder<List<Question>>(
      future: QuestionService.searchQuestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('搜索失败: ${snapshot.error}'));
        }

        final questions = snapshot.data ?? [];

        if (questions.isEmpty) {
          return const Center(
            child: Text('未找到匹配的问题'),
          );
        }

        return ListView.builder(
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return QuestionCard(
              question: question,
              onComplete: () async {
                await QuestionService.completeQuestion(question.id);
                Navigator.pop(context);
              },
              onDelete: () async {
                await QuestionService.deleteQuestion(question.id);
                Navigator.pop(context);
              },
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: question,
                );
              },
            );
          },
        );
      },
    );
  }
}
