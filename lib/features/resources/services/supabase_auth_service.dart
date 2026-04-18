import 'package:cloud_functions/cloud_functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static Future<void> signInWithFirebase() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('mintSupabaseToken')
          .call();

      final supabaseToken = result.data['token'] as String;

      await Supabase.instance.client.auth.signInWithPassword(
        email: '', password: '',
      ).catchError((_) {});

      await Supabase.instance.client.auth.setSession(supabaseToken);
    } catch (e) {
      print('SupabaseAuthService Error: $e');
    }
  }
}
