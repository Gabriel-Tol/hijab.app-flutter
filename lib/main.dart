import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';

void main() {
  runApp(const RnzStoreApp());
}

class RnzStoreApp extends StatelessWidget {
  const RnzStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text(
            'RnZ Store',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
