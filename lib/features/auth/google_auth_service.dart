import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:se_hack/core/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of auth state changes — emits AppUser or null
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map(_userFromFirebase);
  }

  /// Current logged-in user (or null)
  AppUser? get currentUser => _userFromFirebase(_auth.currentUser);

  AppUser? _userFromFirebase(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await _auth.signInWithCredential(credential);
    final user = result.user;
    
    if (user != null) {
      // Sync user profile to Firestore
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
        'photoUrl': user.photoURL,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return _userFromFirebase(user);
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
