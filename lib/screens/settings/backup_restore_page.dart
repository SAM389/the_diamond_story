import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/services/backup_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/file_io.dart';
import '../../core/utils/helpers.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/process_provider.dart';
import '../../widgets/data_table_widget.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  String? _message;
  bool _isError = false;

  static const Color _brightActionYellow = Color(0xFFFFEB3B);

  ButtonStyle _brightActionButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 239, 218, 24),
      foregroundColor: const Color(0xFF1A1A1A),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
    if (!isError) Future.delayed(const Duration(seconds: 3), _clearMessage);
  }

  void _clearMessage() {
    setState(() => _message = null);
  }

  void _exportCsv() async {
    showDialog(
      context: context,
      builder: (_) => _CsvExportDialog(
        onExport: (password) async {
          try {
            if (password.trim().isEmpty) {
              _showMessage('Password is required', isError: true);
              return false;
            }

            final bytes = await BackupService.exportToCsvZip();
            final fileName = BackupService.generateExportFileName();
            final saved = await _saveBytesForUser(
              bytes: bytes,
              fileName: fileName,
              extensions: const ['zip'],
            );
            if (!saved) {
              _showMessage('CSV export cancelled', isError: true);
              return false;
            }

            _showMessage('CSV export downloaded successfully');
            return true;
          } catch (e) {
            _showMessage('CSV export failed: $e', isError: true);
            return false;
          }
        },
      ),
    );
  }

  void _createBackup() async {
    showDialog(
      context: context,
      builder: (_) => _BackupDialog(
        onBackup: (password) async {
          try {
            final csvZipBytes = await BackupService.exportToCsvZip();
            final csvFileName = BackupService.generateExportFileName();
            final csvSaved = await _saveBytesForUser(
              bytes: csvZipBytes,
              fileName: csvFileName,
              extensions: const ['zip'],
            );
            if (!csvSaved) {
              _showMessage('Backup download cancelled', isError: true);
              return false;
            }

            _showMessage('Backup ZIP downloaded successfully');
            return true;
          } catch (e) {
            _showMessage('Backup failed: $e', isError: true);
            return false;
          }
        },
      ),
    );
  }

  void _restoreBackup() async {
    showDialog(
      context: context,
      builder: (_) => _RestoreDialog(
        onRestore: () async {
          try {
            final picked = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['zip'],
              withData: true,
            );

            if (picked == null || picked.files.isEmpty) {
              _showMessage('Restore cancelled', isError: true);
              return false;
            }

            final file = picked.files.first;
            Uint8List? bytes = file.bytes;
            if (bytes == null && file.path != null) {
              bytes = await readBackupFile(file.path!);
            }
            if (bytes == null) {
              _showMessage('Could not read selected backup file', isError: true);
              return false;
            }

            final restoreResult = await BackupService.restoreFromCsvZipBytes(
              bytes,
              merge: true,
            );

            if (!mounted) return false;
            await Future.wait([
              context.read<LedgerProvider>().loadAll(),
              context.read<InventoryProvider>().loadAll(),
              context.read<ProcessProvider>().loadAll(),
            ]);

            _showMessage(
              'Restore complete: ${restoreResult.inserted} inserted, '
              '${restoreResult.overwritten} overwritten, '
              '${restoreResult.skipped} skipped.',
            );
            return true;
          } catch (e) {
            _showMessage('Restore failed: $e', isError: true);
            return false;
          }
        },
      ),
    );
  }

  Future<bool> _saveBytesForUser({
    required Uint8List bytes,
    required String fileName,
    required List<String> extensions,
  }) async {
    if (kIsWeb) {
      triggerDownload(bytes, fileName);
      return true;
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (savePath == null || savePath.isEmpty) {
      return false;
    }

    await saveBackupFile(savePath, bytes);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Data Vault',
              subtitle: 'Manage your data backups',
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isError
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : Colors.tealAccent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: _isError
                        ? Colors.redAccent.withValues(alpha: 0.45)
                        : Colors.tealAccent.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError ? Icons.error_outline : Icons.check_circle_outline,
                      color: _isError ? Colors.redAccent : Colors.tealAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isError ? Colors.redAccent : Colors.tealAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _clearMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            if (_message != null) const SizedBox(height: 20),
            const SectionLabel('ARCHIVAL CONTROLS'),
            const SizedBox(height: 12),
            AppCard(
              accentColor: Colors.teal,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export to CSV',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download all data as CSV files',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                      style: _brightActionButtonStyle(),
                      onPressed: _exportCsv,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('SYSTEM INTEGRITY'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    accentColor: AppTheme.accent,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Backup',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Safe encrypted backup',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Backup Now'),
                            style: _brightActionButtonStyle(),
                            onPressed: _createBackup,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    accentColor: Colors.orange,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore Backup',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Restore from backup file',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore'),
                            style: _brightActionButtonStyle(),
                            onPressed: _restoreBackup,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupDialog extends StatefulWidget {
  final Future<bool> Function(String password) onBackup;
  const _BackupDialog({required this.onBackup});

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  String? _errorMsg;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Password is required.');
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings', limit: 1);
    final storedHash = rows.isEmpty ? null : rows.first['app_password_hash'] as String?;
    if (storedHash == null || !AppHelpers.verifyPassword(password, storedHash)) {
      setState(() => _errorMsg = 'Incorrect password. Please enter your login password.');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    final success = await widget.onBackup(password);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Backup', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Enter your login password to create a backup',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                obscureText: true,
              ),
              if (_errorMsg != null) ...[  
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_errorMsg!, style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 239, 218, 24),
                      foregroundColor: const Color(0xFF1A1A1A),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CsvExportDialog extends StatefulWidget {
  final Future<bool> Function(String password) onExport;
  const _CsvExportDialog({required this.onExport});

  @override
  State<_CsvExportDialog> createState() => _CsvExportDialogState();
}

class _CsvExportDialogState extends State<_CsvExportDialog> {
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  String? _errorMsg;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Password is required.');
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings', limit: 1);
    final storedHash = rows.isEmpty ? null : rows.first['app_password_hash'] as String?;
    if (storedHash == null || !AppHelpers.verifyPassword(password, storedHash)) {
      setState(() => _errorMsg = 'Incorrect password. Please enter your login password.');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    final success = await widget.onExport(password);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Export CSV', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Enter your login password before exporting CSV data',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                obscureText: true,
              ),
              if (_errorMsg != null) ...[  
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_errorMsg!, style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 239, 218, 24),
                      foregroundColor: const Color(0xFF1A1A1A),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Export'),
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

class _RestoreDialog extends StatefulWidget {
  final Future<bool> Function() onRestore;
  const _RestoreDialog({required this.onRestore});

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  String? _errorMsg;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Password is required.');
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings', limit: 1);
    final storedHash = rows.isEmpty ? null : rows.first['app_password_hash'] as String?;
    if (storedHash == null || !AppHelpers.verifyPassword(password, storedHash)) {
      setState(() => _errorMsg = 'Incorrect password. Please enter your login password.');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    final success = await widget.onRestore();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Restore Backup', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Select your backup CSV ZIP file to import data into this system.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Imported records merge with current data, and matching records are overwritten.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                obscureText: true,
              ),
              if (_errorMsg != null) ...[  
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_errorMsg!, style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 239, 218, 24),
                      foregroundColor: const Color(0xFF1A1A1A),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Restore'),
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


