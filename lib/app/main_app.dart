import 'package:material_ui/material_ui.dart';

import '../ui/core/theme/app_theme.dart';

class const MainApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text('Hello, Leandro!'),
        ),
      ),
    );
  }
}
