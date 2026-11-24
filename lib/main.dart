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
import 'widgets/glass_container.dart';

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

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  const ChiraagApp({super.key, this.home = const AppInitializer()});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'Chiraag e Azaa',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppSettings.instance.themeMode,
        home: home,
      ),
    );
  }
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
      final colors = AppColors.of(context);
      return Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 54),
                const SizedBox(height: 16),
                Text(
                  'Initialization Notice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startInitialization,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      backgroundColor: const Color(0xFF103E1B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF165225), Color(0xFF0A2811)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'چراغ عزا',
                textDirection: TextDirection.rtl,
                style: AppTheme.arabicTextStyle(
                  fontSize: 32,
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
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Duas'),
    (Icons.search_outlined, Icons.search_rounded, 'Search'),
    (Icons.blur_circular_outlined, Icons.blur_circular_rounded, 'Tasbih'),
    (Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Saved'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  // Primary 5 tabs inside the iOS 27 floating capsule; Search (index 2) is detached on the right.
  static const _capsuleTabIndices = [0, 1, 3, 4, 5];

  void _selectTab(int idx) {
    if (_tab == idx) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = idx);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    final bodyStack = IndexedStack(
      index: _tab,
      children: [
        HomeScreen(onSelectTab: _selectTab),
        const DuaHubScreen(),
        const SearchScreen(),
        const TasbihScreen(),
        const SavedScreen(),
        const SettingsScreen(),
      ],
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(right: BorderSide(color: colors.separator)),
              ),
              child: SafeArea(
                right: false,
                child: NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: _selectTab,
                  backgroundColor: Colors.transparent,
                  indicatorColor: colors.accentSoft,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: colors.accent),
                  unselectedIconTheme: IconThemeData(color: colors.textTertiary),
                  selectedLabelTextStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  destinations: _tabs
                      .map((t) => NavigationRailDestination(
                            icon: Icon(t.$1),
                            selectedIcon: Icon(t.$2),
                            label: Text(t.$3),
                          ))
                      .toList(),
                ),
              ),
            ),
            Expanded(child: bodyStack),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      extendBody: true,
      body: bodyStack,
      bottomNavigationBar: _buildFloatingGlassTabBar(context, colors),
    );
  }

  Widget _buildFloatingGlassTabBar(BuildContext context, AppColors colors) {
    final isSearchActive = _tab == 2;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _capsuleTabIndices.map((idx) {
                    final t = _tabs[idx];
                    final selected = _tab == idx;
                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _selectTab(idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            decoration: BoxDecoration(
                              color: selected ? colors.accentSoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selected ? t.$2 : t.$1,
                                  size: 21,
                                  color: selected ? colors.accent : colors.textSecondary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected ? colors.accent : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GlassContainer(
              borderRadius: BorderRadius.circular(28),
              tintColor: isSearchActive ? colors.accent : null,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => _selectTab(2),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      isSearchActive ? Icons.search_rounded : Icons.search_outlined,
                      size: 24,
                      color: isSearchActive ? Colors.white : colors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
