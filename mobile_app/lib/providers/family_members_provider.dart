import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public_user.dart';
import '../services/supabase_service.dart';

/// Ported from HomePage.tsx's supabase.rpc('list_family_members') call.
final familyMembersProvider = FutureProvider<List<PublicUser>>((ref) async {
  final data = await SupabaseService.client.rpc('list_family_members');
  return (data as List<dynamic>)
      .map((row) => PublicUser.fromJson(row as Map<String, dynamic>))
      .toList();
});
