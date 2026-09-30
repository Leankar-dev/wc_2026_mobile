import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/routing/router.dart';

import '../ui/core/theme/app_theme.dart';

class const MainApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        return MaterialUiCompatibilityBridge(child: child!);
      },
      routerConfig: router(),
    );
  }
}
