import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:se_hack/core/models/app_user.dart';

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
    return _userFromFirebase(result.user);
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
