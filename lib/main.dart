import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/utils/db_init.dart';
import 'core/utils/app_theme.dart';
import 'providers/inventory_provider.dart';
import 'providers/process_provider.dart';
import 'providers/ledger_provider.dart';
import 'screens/auth/password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabaseFactory();
  await DatabaseHelper.instance.database;
  runApp(const DiamondApp());
}

class DiamondApp extends StatelessWidget {
  const DiamondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ProcessProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
      ],
      child: MaterialApp(
        title: 'Diamond Story ERP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const PasswordScreen(),
      ),
    );
  }
}
