import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'services/push_service.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  try {
    // Copy DB from assets to device on first launch
    await DatabaseService.instance.db;

    // Load bookmarks into in-memory cache
    await DatabaseService.instance.loadBookmarkIds();

    // Load settings from DB
    await AppSettings.instance.load();
  } catch (error, stackTrace) {
    debugPrint('Startup failed: $error\n$stackTrace');
    runApp(ChiraagApp(home: StartupErrorScreen(message: error.toString())));
    return;
  }

  if (!kIsWeb) {
    try {
      // Firebase + Push. Keep this optional so missing Firebase config does not
      // leave simulator builds stuck on the launch screen.
      await Firebase.initializeApp();
      await PushNotificationService.instance.init();
    } catch (error, stackTrace) {
      debugPrint('Push initialization skipped: $error\n$stackTrace');
    }
  }

  runApp(const ChiraagApp());
}

class ChiraagApp extends StatelessWidget {
  final Widget home;

  const ChiraagApp({super.key, this.home = const MainShell()});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chiraag e Azaa',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: home,
  );
}

class StartupErrorScreen extends StatelessWidget {
  final String message;

  const StartupErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chiraag e Azaa')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
              const SizedBox(height: 16),
              const Text(
                'App startup failed',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _tabs = [
    (Icons.home_outlined,     Icons.home,     'Home'),
    (Icons.search_outlined,   Icons.search,   'Search'),
    (Icons.blur_circular_outlined, Icons.blur_circular, 'Tasbih'),
    (Icons.bookmark_outline,  Icons.bookmark, 'Saved'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    TasbihScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.1)))),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: _tabs.asMap().entries.map((e) => BottomNavigationBarItem(
            icon: Icon(_tab == e.key ? e.value.$2 : e.value.$1),
            label: e.value.$3,
          )).toList(),
        ),
      ),
    );
  }
}
