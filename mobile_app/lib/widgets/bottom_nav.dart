import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isEmoji;
  final String? emoji;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isEmoji = false,
    this.emoji,
  });
}

const _navItems = <_NavItem>[
  _NavItem(path: '/home', label: '홈', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
  _NavItem(path: '/travel', label: '여행', icon: Icons.flight_outlined, activeIcon: Icons.flight, isEmoji: true, emoji: '✈️'),
  _NavItem(path: '/running', label: '러닝', icon: Icons.directions_run, activeIcon: Icons.directions_run, isEmoji: true, emoji: '🏃'),
  _NavItem(path: '/golf', label: '골프', icon: Icons.sports_golf, activeIcon: Icons.sports_golf, isEmoji: true, emoji: '⛳'),
  _NavItem(path: '/gym', label: '헬스', icon: Icons.fitness_center, activeIcon: Icons.fitness_center, isEmoji: true, emoji: '💪'),
];

/// Ported from src/components/BottomNav.tsx — 5-tab fixed bottom bar.
class BottomNav extends StatelessWidget {
  final String currentPath;

  const BottomNav({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    // Mirrors the web app's `.safe-bottom` class (padding-bottom: env(safe-area-inset-bottom))
    // so the bar doesn't sit under Android's gesture/button navigation area.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.grayBorder)),
        boxShadow: AppColors.shadowFloat,
      ),
      child: SizedBox(
        height: 64,
        child: Row(
        children: _navItems.map((item) {
          final active = currentPath == item.path;
          return Expanded(
            child: InkWell(
              onTap: () => context.go(item.path),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  item.isEmoji
                      ? Text(item.emoji!, style: const TextStyle(fontSize: 19, height: 1))
                      : Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active ? AppColors.text900 : AppColors.text400,
                        ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: active ? AppColors.text900 : AppColors.text400,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }
}
