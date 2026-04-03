import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../home/home_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with SingleTickerProviderStateMixin {
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isNewUser = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = true;
  String? _error;

  // Shake animation
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _checkPasswordExists();
  }

  Future<void> _checkPasswordExists() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings', limit: 1);
    if (mounted) {
      setState(() {
        _isNewUser = rows.isEmpty || rows.first['app_password_hash'] == null;
        _loading = false;
      });
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    final password = _pwCtrl.text.trim();
    if (password.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.');
      _shake();
      return;
    }

    final db = await DatabaseHelper.instance.database;

    if (_isNewUser) {
      final confirm = _confirmCtrl.text.trim();
      if (password != confirm) {
        setState(() => _error = 'Passwords do not match.');
        _shake();
        return;
      }
      final hash = AppHelpers.hashPassword(password);
      await db.insert('app_settings', {
        'app_password_hash': hash,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final rows = await db.query('app_settings', limit: 1);
      final storedHash = rows.first['app_password_hash'] as String?;
      if (storedHash == null ||
          !AppHelpers.verifyPassword(password, storedHash)) {
        setState(() => _error = 'Incorrect password. Please try again.');
        _shake();
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF), // Deep Slate Custom
              Color(0xFFF1F5F9),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) {
              final dx = _error != null
                  ? (8 * (0.5 - (_shakeAnim.value % 1).abs()) *
                      ((_shakeAnim.value * 6).floor().isEven ? 1 : -1))
                  : 0.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
                  border: Border.all(
                    color: AppTheme.borderSubtle,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.diamond_rounded,
                          color: AppTheme.accent,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Diamond Story ERP',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isNewUser
                          ? 'Create a password to secure your data'
                          : 'Enter your password to continue',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PASSWORD',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pwCtrl,
                          obscureText: _obscure,
                          onSubmitted: (_) => _isNewUser ? null : _submit(),
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              tooltip:
                                  _obscure ? 'Show password' : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_isNewUser) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONFIRM PASSWORD',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                tooltip: _obscureConfirm
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Error banner
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppTheme.buttonRadius),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 16, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(
                        _isNewUser
                            ? Icons.lock_rounded
                            : Icons.login_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isNewUser ? 'Create Password & Enter' : 'Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


