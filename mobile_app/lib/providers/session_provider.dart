import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_user.dart';
import '../services/session_store.dart';

class SessionNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  SessionNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final user = await SessionStore.get();
    state = AsyncValue.data(user);
  }

  Future<void> login(AuthUser user) async {
    await SessionStore.save(user);
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    await SessionStore.clear();
    state = const AsyncValue.data(null);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, AsyncValue<AuthUser?>>(
  (ref) => SessionNotifier(),
);
