import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/utils/db_init.dart';
import 'core/utils/app_theme.dart';
import 'providers/inventory_provider.dart';
import 'providers/process_provider.dart';
import 'providers/ledger_provider.dart';
import 'screens/auth/password_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: const _StartupGate(),
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await initDatabaseFactory();
    await DatabaseHelper.instance.database;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to initialize local database.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _startupFuture = _initializeApp();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const PasswordScreen();
      },
    );
  }
}
