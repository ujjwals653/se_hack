// Pasteboard screen re-export — now embedded as a tab in squad_chat_screen.dart
// This file kept as navigation fallback placeholder.
import 'package:flutter/material.dart';

class PasteboardScreen extends StatelessWidget {
  const PasteboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Pasteboard is embedded in Squad Chat')),
    );
  }
}
