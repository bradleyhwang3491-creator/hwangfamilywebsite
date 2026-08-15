import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/bottom_nav.dart';

/// Ported from src/pages/PlaceholderPage.tsx — used for 러닝/골프/헬스/MY.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String emoji;

  const PlaceholderScreen({super.key, required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('준비 중인 화면이에요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text900)),
              const SizedBox(height: 6),
              Text(
                '다음 단계에서 $title 기능을 만들 예정입니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.text400, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(currentPath: _pathFor(title)),
    );
  }

  String _pathFor(String title) {
    switch (title) {
      case '러닝 기록':
        return '/running';
      case '골프 기록':
        return '/golf';
      case '헬스 기록':
        return '/gym';
      default:
        return '/my';
    }
  }
}
