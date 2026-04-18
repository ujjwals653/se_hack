// lib/core/services/auth_service.dart
// Lumina — Manages Google Sign-In and coordinates Hive restore on new login

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'restore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Gets the currently authenticated Firebase user, or null if unauthenticated.
  static User? get currentUser => _auth.currentUser;

  /// Signs the user in with Google. 
  /// On successful login, it instantly restores cloud data into local Hive.
  static Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted the sign-in
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the generated credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        debugPrint('Successfully signed in as: ${user.uid}');
        
        // 5. Restore data from Firebase to local Hive database on login
        // This ensures the local offline cache is populated when switching devices
        try {
          await RestoreService.restoreAllData(user.uid);
          debugPrint('Successfully restored all cloud data to local Hive.');
        } catch (e) {
          debugPrint('Error restoring data during login: $e');
          // Handle specific UI logic here if restore fails
        }
      }

      return user;
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      return null;
    }
  }

  /// Signs the user out of both Firebase and Google.
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('Successfully signed out.');
      // Optional: Clear Hive boxes here if you want to wipe local data on logout
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
