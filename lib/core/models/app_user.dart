import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  String get firstName => displayName.split(' ').first;

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl];
}
