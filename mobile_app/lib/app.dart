import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/running_record_detail_screen.dart';
import 'screens/running_screen.dart';
import 'screens/running_tracker_screen.dart';
import 'screens/travel_record_detail_screen.dart';
import 'screens/travel_record_form_screen.dart';
import 'screens/travel_screen.dart';

/// Ported from src/App.tsx — same path structure, no route guards (the web
/// app doesn't gate routes on a session either; only saving a travel record
/// checks for one).
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    const knownPaths = {
      '/login',
      '/home',
      '/travel',
      '/travel/new',
      '/running',
      '/running/new',
      '/golf',
      '/gym',
      '/my',
    };
    final path = state.matchedLocation;
    if (path == '/') return '/login';
    if (path.startsWith('/travel/record/')) return null;
    if (path.startsWith('/running/record/')) return null;
    if (!knownPaths.contains(path)) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/login', pageBuilder: (context, state) => _fadePage(const LoginScreen(), state)),
    GoRoute(path: '/home', pageBuilder: (context, state) => _fadePage(const HomeScreen(), state)),
    GoRoute(path: '/travel', pageBuilder: (context, state) => _fadePage(const TravelScreen(), state)),
    GoRoute(
      path: '/travel/new',
      pageBuilder: (context, state) => _fadePage(const TravelRecordFormScreen(), state),
    ),
    GoRoute(
      path: '/travel/record/:id',
      pageBuilder: (context, state) =>
          _fadePage(TravelRecordDetailScreen(recordId: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: '/running',
      pageBuilder: (context, state) => _fadePage(const RunningScreen(), state),
    ),
    GoRoute(
      path: '/running/new',
      pageBuilder: (context, state) => _fadePage(const RunningTrackerScreen(), state),
    ),
    GoRoute(
      path: '/running/record/:id',
      pageBuilder: (context, state) =>
          _fadePage(RunningRecordDetailScreen(recordId: state.pathParameters['id']!), state),
    ),
    GoRoute(
      path: '/golf',
      pageBuilder: (context, state) => _fadePage(const PlaceholderScreen(title: '골프 기록', emoji: '⛳'), state),
    ),
    GoRoute(
      path: '/gym',
      pageBuilder: (context, state) => _fadePage(const PlaceholderScreen(title: '헬스 기록', emoji: '💪'), state),
    ),
    GoRoute(
      path: '/my',
      pageBuilder: (context, state) => _fadePage(const MyPageScreen(), state),
    ),
  ],
);

CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class HwangFamilyApp extends StatelessWidget {
  const HwangFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '황이서네 가족 라이프로그',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        // Mirrors .app-frame: mobile-first, centered with a max width on
        // wide viewports (desktop Chrome window) instead of stretching full width.
        return Container(
          color: const Color(0xFFEDEFF2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(color: AppColors.white, child: child),
            ),
          ),
        );
      },
    );
  }
}
