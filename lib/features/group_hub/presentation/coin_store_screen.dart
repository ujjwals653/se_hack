import 'package:flutter/material.dart';
import '../data/squad_repository.dart';

// CoinStoreScreen – The coin economy has been removed.
// Stub retained to avoid broken imports.
class CoinStoreScreen extends StatelessWidget {
  final String uid;
  final SquadRepository repo;
  const CoinStoreScreen({super.key, required this.uid, required this.repo});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Feature removed')),
    );
  }
}
