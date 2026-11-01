import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/pantry/presentation/pantry_screen.dart';
import 'features/preferences/presentation/saved_and_preferences_screen.dart';
import 'features/recommendation/presentation/recommendation_screen.dart';
import 'features/scanner/presentation/scan_and_review_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FridgeChefApp(),
    ),
  );
}

class FridgeChefApp extends StatelessWidget {
  const FridgeChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '냉장고 셰프 AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShellScreen(),
    );
  }
}

/// 하단 3탭 내비게이션 셸 (홈/내 냉장고 · 맞춤 요리 추천 · 저장 및 설정)
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  Future<void> _openScannerFlow() async {
    final savedAndConfirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ScanAndReviewScreen(),
      ),
    );
    // 스캔 결과를 확정하고 돌아오면 자동으로 '맞춤 요리 추천' 탭으로 이동
    if (savedAndConfirmed == true && mounted) {
      setState(() => _selectedIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PantryScreen(
        onStartScan: _openScannerFlow,
        onGoToRecommendations: () => setState(() => _selectedIndex = 1),
      ),
      RecommendationScreen(
        onOpenScanner: _openScannerFlow,
      ),
      const SavedAndPreferencesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              key: const Key('fab_scan_fridge'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              onPressed: _openScannerFlow,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text(
                '냉장고 스캔',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            key: Key('nav_pantry'),
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen, color: AppTheme.primaryGreenDark),
            label: '내 냉장고',
          ),
          NavigationDestination(
            key: Key('nav_recommendations'),
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(
              Icons.restaurant_menu,
              color: AppTheme.primaryGreenDark,
            ),
            label: '맞춤 요리 추천',
          ),
          NavigationDestination(
            key: Key('nav_saved_prefs'),
            icon: Icon(Icons.bookmark_outline),
            selectedIcon:
                Icon(Icons.bookmark, color: AppTheme.primaryGreenDark),
            label: '저장 & 설정',
          ),
        ],
      ),
    );
  }
}
