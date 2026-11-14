import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'screens/recovery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  await _bootstrap();
}

Future<void> _bootstrap() async {
  try {
    final store = await LocalStore.open();
    await store.seedIfNeeded();
    runApp(RnzApp.create(store));
  } on StoreCorruptException {
    runApp(RecoveryScreen(onRecovered: () => _bootstrap()));
  }
}
