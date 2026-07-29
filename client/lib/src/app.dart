import 'package:flutter/material.dart';

import 'screens/editor_screen.dart';
import 'theme/relay_theme.dart';

class RelayApp extends StatelessWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Relay',
      debugShowCheckedModeBanner: false,
      theme: RelayTheme.dark(),
      home: const EditorScreen(),
    );
  }
}
