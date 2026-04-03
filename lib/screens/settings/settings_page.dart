import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/services/backup_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/process_provider.dart';
import '../../widgets/data_table_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _resetting = false;

  Future<void> _changePassword() async {
    await showDialog(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  Future<void> _resetData() async {
    final confirmed = await showDeleteConfirmDialog(context, 'all data');
    if (!confirmed || !mounted) return;

    setState(() => _resetting = true);
    try {
      await BackupService.resetApplicationData();

      if (!mounted) return;
      await Future.wait([
        context.read<LedgerProvider>().loadAll(),
        context.read<InventoryProvider>().loadAll(),
        context.read<ProcessProvider>().loadAll(),
      ]);

      if (!mounted) return;
      showSuccessSnack(
        context,
        'All data reset successfully. Default categories restored.',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, 'Reset failed: $e');
    } finally {
      if (mounted) {
        setState(() => _resetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Settings Center',
              subtitle: 'Configure display, integrations, and operational defaults',
            ),
            Expanded(
              child: ListView(
                children: [
                  const _Section(
                    label: 'Display',
                    items: [
                      _Item(
                        icon: Icons.palette_outlined,
                        title: 'Theme Identity',
                        subtitle: 'Luxury Light mode and accent behavior',
                        trailing: 'Active',
                      ),
                      _Item(
                        icon: Icons.table_rows_rounded,
                        title: 'Table Density',
                        subtitle: 'Control data table row and column compactness',
                        trailing: 'Standard',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _Section(
                    label: 'Notifications',
                    items: [
                      _Item(
                        icon: Icons.notifications_none_rounded,
                        title: 'Process Alerts',
                        subtitle: 'Overdue and pending process reminders',
                        trailing: 'Enabled',
                      ),
                      _Item(
                        icon: Icons.payments_outlined,
                        title: 'Payment Reminders',
                        subtitle: 'Highlight due and pending settlements',
                        trailing: 'Enabled',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _Section(
                    label: 'Integrations',
                    items: [
                      _Item(
                        icon: Icons.backup_table_rounded,
                        title: 'Data Vault',
                        subtitle: 'Use Backup and Restore to secure ledgers',
                        trailing: 'Ready',
                      ),
                      _Item(
                        icon: Icons.security_rounded,
                        title: 'Security',
                        subtitle: 'Password gate controls app access',
                        trailing: 'Protected',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    label: 'Account Security',
                    items: [
                      _Item(
                        icon: Icons.lock_reset_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your login password',
                        trailing: 'Update',
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    label: 'Data Management',
                    items: [
                      _Item(
                        icon: Icons.delete_forever_rounded,
                        iconColor: Colors.redAccent,
                        title: 'Reset Data',
                        subtitle:
                            'Delete all records and start fresh (cannot be undone)',
                        trailing: _resetting ? 'Resetting...' : 'Danger',
                        trailingColor: Colors.redAccent,
                        onTap: _resetting ? null : _resetData,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ── Change Password Dialog ────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _oldVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (newPass.length < 4) {
      setState(() => _error = 'New password must be at least 4 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('app_settings', limit: 1);
      final storedHash =
          rows.isEmpty ? null : rows.first['app_password_hash'] as String?;

      if (storedHash == null || !AppHelpers.verifyPassword(oldPass, storedHash)) {
        setState(() {
          _error = 'Current password is incorrect.';
          _saving = false;
        });
        return;
      }

      final newHash = AppHelpers.hashPassword(newPass);
      if (rows.isEmpty) {
        await db.insert('app_settings', {'app_password_hash': newHash});
      } else {
        await db.update('app_settings', {'app_password_hash': newHash});
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to update password: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.borderSubtle, width: 1.2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55000000),
                blurRadius: 40,
                offset: Offset(0, 16))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: AppTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Verify your identity to continue',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Current password
              _PasswordField(
                controller: _oldCtrl,
                label: 'Current Password',
                visible: _oldVisible,
                onToggle: () =>
                    setState(() => _oldVisible = !_oldVisible),
              ),
              const SizedBox(height: 14),
              // Section divider
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: AppTheme.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('New credentials',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            letterSpacing: 1)),
                  ),
                  Expanded(
                      child: Divider(
                          color: AppTheme.divider)),
                ],
              ),
              const SizedBox(height: 14),
              // New password
              _PasswordField(
                controller: _newCtrl,
                label: 'New Password',
                visible: _newVisible,
                onToggle: () =>
                    setState(() => _newVisible = !_newVisible),
              ),
              const SizedBox(height: 14),
              // Confirm new password
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                visible: _confirmVisible,
                onToggle: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
              ),
              // Error banner
              if (_error != null) ...[  
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _brightActionYellow,
                      foregroundColor: const Color(0xFF1A1A1A),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A1A1A)))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Update Password'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            visible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 18,
            color: AppTheme.textMuted,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> items;

  const _Section({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppTheme.accent.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? trailingColor;

  const _Item({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.iconColor,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.inter(
              color: trailingColor ?? AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}
