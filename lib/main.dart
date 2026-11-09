import 'package:flutter/material.dart';

import 'home_page.dart';
import 'ledger_controller.dart';
import 'ledger_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = LedgerController(LedgerStore());
  await controller.init();
  runApp(SavingsApp(controller: controller));
}

class SavingsApp extends StatelessWidget {
  const SavingsApp({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Savings',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomePage(controller: controller),
    );
  }
}
