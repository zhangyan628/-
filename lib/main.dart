import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/notification_service.dart';
import 'pages/home_page.dart';
import 'pages/new_question_page.dart';
import 'pages/detail_page.dart';
import 'pages/category_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化通知服务
  await NotificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: QuestionReminderApp(),
    ),
  );
}

class QuestionReminderApp extends StatelessWidget {
  const QuestionReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '问题记录',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/new': (context) => const NewQuestionPage(),
        '/detail': (context) => const DetailPage(),
        '/category': (context) => const CategoryPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
