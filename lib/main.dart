import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

import 'theme.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'services/push_service.dart';
import 'screens/home_screen.dart';
import 'screens/dua_hub_screen.dart';
import 'screens/search_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow portrait and landscape so iPad and tablets never crash in orientation lock
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ChiraagApp());
}

class ChiraagApp extends StatelessWidget {
  final Widget home;

  const ChiraagApp({super.key, this.home = const AppInitializer()});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chiraag e Azaa',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: home,
  );
}

/// Responsive startup initializer that displays an immediate spiritual splash
/// screen while loading the local database, preventing any launch timeouts or watchdog kills.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // 1. Initialize local SQLite database
      await DatabaseService.instance.db;

      // 2. Load bookmarks cache
      await DatabaseService.instance.loadBookmarkIds();

      // 3. Load user settings
      await AppSettings.instance.load();

      // 4. Initialize notifications (non-blocking)
      if (!kIsWeb) {
        PushNotificationService.instance.init().catchError((error) {
          debugPrint('Notification init error: $error');
        });
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Startup error: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const MainShell();
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 54),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Notice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startInitialization,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Immediate Splash Screen with brand identity while loading
    return Scaffold(
      backgroundColor: const Color(0xFF165225),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'چراغ عزا',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chiraag e Azaa',
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 0.8,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            ),
          ],
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
    (Icons.home_outlined,         Icons.home,         'Home'),
    (Icons.menu_book_outlined,    Icons.menu_book,    'Duas'),
    (Icons.search_outlined,       Icons.search,       'Search'),
    (Icons.blur_circular_outlined,Icons.blur_circular,'Tasbih'),
    (Icons.bookmark_outline,      Icons.bookmark,     'Saved'),
    (Icons.settings_outlined,     Icons.settings,     'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onSelectTab: (i) => setState(() => _tab = i)),
          const DuaHubScreen(),
          const SearchScreen(),
          const TasbihScreen(),
          const SavedScreen(),
          const SettingsScreen(),
        ],
      ),
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
