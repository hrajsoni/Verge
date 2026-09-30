import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/glass_theme.dart';
import 'core/widgets/liquid_glass_nav_bar.dart';
import 'core/widgets/liquid_mesh_background.dart';
import 'features/camera/camera_screen.dart';
import 'features/chat/conversations_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const BeSnapApp());
}

class BeSnapApp extends StatefulWidget {
  const BeSnapApp({super.key});

  @override
  State<BeSnapApp> createState() => _BeSnapAppState();
}

class _BeSnapAppState extends State<BeSnapApp> {
  bool _isOnboardingDone = true; // Default to main shell, toggleable in Profile

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be-Snap',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        cupertinoOverrideTheme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: GlassTheme.iosBlue,
        ),
      ),
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        cupertinoOverrideTheme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: GlassTheme.iosBlue,
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isOnboardingDone
            ? MainNavigationShell(
                onRestartOnboarding: () {
                  setState(() => _isOnboardingDone = false);
                },
              )
            : OnboardingScreen(
                onOnboardingCompleted: () {
                  setState(() => _isOnboardingDone = true);
                },
              ),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final VoidCallback? onRestartOnboarding;

  const MainNavigationShell({super.key, this.onRestartOnboarding});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const DiscoveryScreen(),
      CameraScreen(
        onSnapCaptured: () {
          setState(() => _currentIndex = 2); // Switch to Chat/Messages tab
        },
      ),
      const ConversationsScreen(),
      ProfileScreen(
        onRestartOnboarding: widget.onRestartOnboarding,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: LiquidMeshBackground(
        isDark: isDark,
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: _currentIndex,
        unreadChatCount: 1,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
