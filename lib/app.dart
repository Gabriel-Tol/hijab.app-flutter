import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'routing/app_router.dart';
import 'state/auth_controller.dart';

class RnzApp extends StatelessWidget {
  const RnzApp({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RnZ Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: buildRouter(auth),
    );
  }
}
