import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/settings_screen.dart';

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _item(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                _item(Icons.bookmark_border_rounded, Icons.bookmark_rounded,
                    'Saved', 1),
                _item(Icons.settings_outlined, Icons.settings_rounded,
                    'Settings', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _index == index;
    const primary = Color(0xFF1E2050);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? primary : Colors.grey[400],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? primary : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
