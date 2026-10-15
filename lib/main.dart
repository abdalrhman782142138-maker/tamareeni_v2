import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/programs_page.dart';
import 'pages/progress_page.dart';
import 'pages/settings_page.dart';
import 'services/storage_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService.instance.init();
  } catch (_) {
    // إذا فشل التحميل يعمل التطبيق ببيانات فارغة بدل أن يتوقف.
  }
  runApp(const TamareeniApp());
}

class TamareeniApp extends StatelessWidget {
  const TamareeniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StorageService storage = StorageService.instance;
    return AnimatedBuilder(
      animation: storage,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: 'تماريني',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: storage.themeMode,
          // واجهة عربية من اليمين إلى اليسار.
          builder: (BuildContext context, Widget? child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const MainShell(),
        );
      },
    );
  }
}

/// الهيكل الرئيسي: أربع صفحات مع شريط تنقل سفلي.
/// الفهارس: 0 الرئيسية، 1 البرامج، 2 التطور، 3 الإعدادات.
class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goTo(int index) {
    if (index < 0 || index > 3) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(onGoToTab: _goTo),
      const ProgramsPage(),
      const ProgressPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'البرامج',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up_rounded),
            label: 'التطور',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}