import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

/// Reads the signed-in user's row in `profiles` together with its role.
class ProfileService {
  ProfileService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns null if the profile row does not exist (e.g. the sign-up trigger
  /// has not been installed yet).
  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, email, firstname, lastname, roles(role)')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }
}
