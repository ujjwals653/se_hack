import 'package:flutter/material.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';

// HeatmapWallScreen – The heatmap / focus-log feature has been removed.
// This file is kept to avoid dead import errors in other files that may still
// reference it, but it is no longer navigated to from the UI.
class HeatmapWallScreen extends StatelessWidget {
  final String squadId;
  final SquadRepository repo;
  const HeatmapWallScreen({super.key, required this.squadId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Feature removed')),
    );
  }
}
