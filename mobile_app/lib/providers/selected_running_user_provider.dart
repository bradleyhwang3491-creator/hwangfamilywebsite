import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User whose running records RunningScreen is currently showing.
/// null = the logged-in user (default).
final selectedRunningUserProvider = StateProvider<String?>((ref) => null);
