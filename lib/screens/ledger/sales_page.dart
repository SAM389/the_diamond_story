import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/sales_pdf_service.dart';
import '../../core/utils/file_io.dart';
import '../../core/utils/helpers.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_table_widget.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  ButtonStyle _brightActionButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brightActionYellow,
      foregroundColor: const Color(0xFF1A1A1A),
    );
  }

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
      context.read<InventoryProvider>().loadDiamonds();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Future<void> _exportSalePdf(Sale sale) async {
    if (sale.isDeleted) {
      showErrorSnack(context, 'Deleted sales cannot be exported to PDF.');
      return;
    }

    try {
      final bytes = await SalesPdfService.buildSaleBillPdf(sale);
      final fileName = SalesPdfService.buildFileName(sale);
      final saved = await _saveBytesForUser(
        bytes: bytes,
        fileName: fileName,
        extensions: const ['pdf'],
      );

      if (!mounted) return;

      if (!saved) {
        showErrorSnack(context, 'PDF export cancelled');
        return;
      }

      showSuccessSnack(context, 'PDF bill exported successfully');
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, 'Failed to export PDF bill: $e');
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Sales',
            subtitle: 'Record diamond sales',
            action: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search sales',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sale'),
                  style: _brightActionButtonStyle(),
                  onPressed: () async {
                    await context.read<InventoryProvider>().loadDiamonds();
                    if (!mounted) {
                      return;
                    }
                    final saved = await showDialog<bool>(
                      context: context,
                      builder: (_) => const _SaleDialog(),
                    );
                    if (saved == true && mounted) {
                      await context.read<InventoryProvider>().loadDiamonds();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<LedgerProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: TableSkeleton(rows: 6),
                );
              }

              final sales = provider.sales.where((sale) {
                if (_searchQuery.isEmpty) return true;
                if (sale.isDeleted) return false;

                return (sale.billNo ?? '').toLowerCase().contains(_searchQuery) ||
                    (sale.partyName ?? '').toLowerCase().contains(_searchQuery) ||
                    (sale.diamondCode ?? '').toLowerCase().contains(_searchQuery) ||
                    sale.date.toLowerCase().contains(_searchQuery) ||
                    (sale.notes ?? '').toLowerCase().contains(_searchQuery) ||
                    sale.price.toString().contains(_searchQuery);
              }).toList();

              if (provider.sales.isEmpty) {
                return const EmptyState(
                  message: 'No sales yet.',
                  icon: Icons.sell_outlined,
                  ctaLabel: 'Record your first sale',
                );
              }

              if (sales.isEmpty) {
                return const EmptyState(
                  message: 'No sales match your search.',
                  icon: Icons.search_off_rounded,
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(sales),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(sales)),
                  ],
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildStats(List<Sale> sales) {
    final activeSales = sales.where((sale) => !sale.isDeleted).toList();
    final totalValue = activeSales.fold<double>(0, (sum, s) => sum + s.price);
    final linkedDiamonds = activeSales.fold<int>(0, (sum, sale) {
      if (sale.items.isNotEmpty) return sum + sale.items.length;
      if (sale.diamondCode == null || sale.diamondCode == '-' || sale.diamondCode!.isEmpty) {
        return sum;
      }
      return sum + 1;
    });
    final uniqueCustomers = activeSales
        .map((s) => s.partyName)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.sell_outlined,
          label: 'Total Sales',
          value: activeSales.length.toString(),
          color: AppTheme.accent,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.currency_rupee_outlined,
          label: 'Total Value',
          value: AppHelpers.formatCurrency(totalValue),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.people_outline,
          label: 'Customers',
          value: uniqueCustomers.toString(),
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.diamond_outlined,
          label: 'Linked Diamonds',
          value: linkedDiamonds.toString(),
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }

  Widget _buildTable(List<Sale> sales) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 52,
              color: Colors.black.withValues(alpha: 0.03),
              child: Row(
                children: [
                  _hCell('Bill No', flex: 2),
                  _hCell('Customer', flex: 3),
                  _hCell('Diamond', flex: 2),
                  _hCell('Price (Rs)', flex: 2),
                  _hCell('Date', flex: 2),
                  _hCell('Notes', flex: 3),
                  _hCell('Actions', flex: 1),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (_, index) =>
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                itemBuilder: (_, i) {
                  final s = sales[i];
                  final isDeleted = s.isDeleted;
                  return Container(
                    height: 52,
                    color: i.isEven
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.015),
                    child: Opacity(
                      opacity: isDeleted ? 0.55 : 1,
                      child: Row(
                        children: [
                        _dCell(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.billNo ?? '-',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: isDeleted ? AppTheme.textMuted : AppTheme.accent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDeleted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Deleted',
                                    style: GoogleFonts.inter(
                                      color: Colors.red.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _dCell(
                          flex: 3,
                          child: Text(
                            s.partyName ?? '-',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.diamondCode ?? '-',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF38BDF8),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.formatCurrency(s.price),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.displayDate(s.date),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        _dCell(
                          flex: 3,
                          child: Text(
                            s.notes ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 40,
                              child: PopupMenuButton<String>(
                                tooltip: 'Actions',
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await context.read<InventoryProvider>().loadDiamonds();
                                    if (!mounted) return;
                                    final saved = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => _SaleDialog(existing: s),
                                    );
                                    if (saved == true && mounted) {
                                      await context.read<InventoryProvider>().loadDiamonds();
                                    }
                                    return;
                                  }

                                  if (value == 'export_pdf') {
                                    await _exportSalePdf(s);
                                    return;
                                  }

                                  if (value == 'delete') {
                                    final ok = await showDeleteConfirmDialog(context, 'sale entry');
                                    if (ok && mounted) {
                                      final deleted = await context.read<LedgerProvider>().deleteSale(s.id!);
                                      if (mounted) {
                                        if (deleted) {
                                          await context.read<InventoryProvider>().loadDiamonds();
                                          if (mounted) {
                                            showSuccessSnack(context, 'Sale moved to deleted');
                                          }
                                        } else {
                                          showErrorSnack(
                                            context,
                                            context.read<LedgerProvider>().error ?? 'Failed to delete sale',
                                          );
                                        }
                                      }
                                    }
                                    return;
                                  }

                                  if (value == 'restore') {
                                    final restored = await context.read<LedgerProvider>().restoreSale(s.id!);
                                    if (mounted) {
                                      if (restored) {
                                        await context.read<InventoryProvider>().loadDiamonds();
                                        if (mounted) {
                                          showSuccessSnack(context, 'Sale restored');
                                        }
                                      } else {
                                        showErrorSnack(
                                          context,
                                          context.read<LedgerProvider>().error ?? 'Failed to restore sale',
                                        );
                                      }
                                    }
                                    return;
                                  }

                                  if (value == 'hard_delete') {
                                    final ok = await showDeleteConfirmDialog(
                                      context,
                                      'sale entry permanently',
                                    );
                                    if (ok && mounted) {
                                      final hardDeleted = await context.read<LedgerProvider>().hardDeleteSale(s.id!);
                                      if (mounted) {
                                        if (hardDeleted) {
                                          await context.read<InventoryProvider>().loadDiamonds();
                                          if (mounted) {
                                            showSuccessSnack(context, 'Sale permanently deleted');
                                          }
                                        } else {
                                          showErrorSnack(
                                            context,
                                            context.read<LedgerProvider>().error ??
                                                'Failed to permanently delete sale',
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => isDeleted
                                    ? [
                                        const PopupMenuItem<String>(
                                          value: 'restore',
                                          child: Row(
                                            children: [
                                              Icon(Icons.restore, size: 18),
                                              SizedBox(width: 8),
                                              Text('Restore sale'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'hard_delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text(
                                                'Permanent delete',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]
                                    : [
                                        const PopupMenuItem<String>(
                                          value: 'export_pdf',
                                          child: Row(
                                            children: [
                                              Icon(Icons.picture_as_pdf_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Export PDF'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit sale'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete sale', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hCell(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

  Widget _dCell({required int flex, required Widget child}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      );

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleDialog extends StatefulWidget {
  final Sale? existing;
  const _SaleDialog({this.existing});

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _partyId;
  final Set<int> _selectedDiamondIds = <int>{};
  final Map<int, TextEditingController> _lineAmountCtrls =
      <int, TextEditingController>{};
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = AppHelpers.today();
    final existing = widget.existing;
    if (existing != null) {
      _partyId = existing.partyId;
      _dateCtrl.text = existing.date;
      _notesCtrl.text = existing.notes ?? '';
      for (final item in existing.items) {
        _selectedDiamondIds.add(item.diamondId);
        _lineAmountCtrls[item.diamondId] = TextEditingController(
          text: item.amount.toStringAsFixed(2),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _lineAmountCtrls.values) {
      ctrl.dispose();
    }
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _diamondLabel(dynamic diamond) {
    return '${diamond.diamondCode} (${diamond.weight.toStringAsFixed(3)} ct)';
  }

  dynamic _findDiamondById(List<dynamic> diamonds, int id) {
    for (final diamond in diamonds) {
      if (diamond.id == id) {
        return diamond;
      }
    }
    return null;
  }

  double _lineAmountTotal() {
    var total = 0.0;
    for (final id in _selectedDiamondIds) {
      final value = double.tryParse(_lineAmountCtrls[id]?.text.trim() ?? '');
      if (value != null && value > 0) {
        total += value;
      }
    }
    return total;
  }

  bool _lineAmountsAreValid() {
    if (_selectedDiamondIds.isEmpty) return false;
    for (final id in _selectedDiamondIds) {
      final value = double.tryParse(_lineAmountCtrls[id]?.text.trim() ?? '');
      if (value == null || value <= 0) {
        return false;
      }
    }
    return true;
  }

  Future<void> _openDiamondPicker(List<dynamic> completedDiamonds) async {
    if (completedDiamonds.isEmpty) return;

    final selected = Set<int>.from(_selectedDiamondIds);
    final picked = await showDialog<Set<int>>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = completedDiamonds.where((diamond) {
              final label = _diamondLabel(diamond).toLowerCase();
              return label.contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Diamonds'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search diamond',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No diamond matches your search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final diamond = filtered[index];
                                final id = diamond.id as int;
                                final checked = selected.contains(id);
                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  value: checked,
                                  title: Text(_diamondLabel(diamond)),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      if (v == true) {
                                        selected.add(id);
                                      } else {
                                        selected.remove(id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDiamondIds
        ..clear()
        ..addAll(picked);

      for (final id in _selectedDiamondIds) {
        _lineAmountCtrls.putIfAbsent(id, () => TextEditingController());
      }

      final staleIds = _lineAmountCtrls.keys
          .where((id) => !_selectedDiamondIds.contains(id))
          .toList();
      for (final id in staleIds) {
        _lineAmountCtrls.remove(id)?.dispose();
      }
    });
  }

  String? _selectedCustomerName(List<dynamic> customers) {
    if (_partyId == null) return null;
    for (final customer in customers) {
      if (customer.id == _partyId) return customer.name as String;
    }
    return null;
  }

  Future<void> _openCustomerPicker(List<dynamic> customers) async {
    if (customers.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = customers.where((customer) {
              final name = (customer.name as String).toLowerCase();
              return name.contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Customer'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search customer',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No customer matches your search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final customer = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(customer.name as String),
                                  trailing: customer.id == _partyId
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, customer.id as int?),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selectedId == null) return;
    setState(() => _partyId = selectedId);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: AppHelpers.parseDate(_dateCtrl.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || selected == null) return;
    setState(() => _dateCtrl.text = AppHelpers.formatDate(selected));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _partyId == null) {
      if (_partyId == null) {
        showErrorSnack(context, 'Please select a customer');
      }
      return;
    }

    if (_selectedDiamondIds.isEmpty) {
      showErrorSnack(context, 'Select at least one diamond');
      return;
    }

    if (!_lineAmountsAreValid()) {
      showErrorSnack(context, 'Enter valid amount for each selected diamond');
      return;
    }

    setState(() => _saving = true);

    final items = _selectedDiamondIds
        .map(
          (id) => SaleItem(
            saleId: 0,
            diamondId: id,
            amount: double.tryParse(_lineAmountCtrls[id]?.text.trim() ?? '0') ?? 0,
          ),
        )
        .toList();

    final sale = Sale(
      partyId: _partyId!,
      diamondId: items.first.diamondId,
      price: _lineAmountTotal(),
      date: _dateCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
      items: items,
    );

    final ledgerProvider = context.read<LedgerProvider>();
    final ok = widget.existing == null
      ? await ledgerProvider.addSale(sale)
      : await ledgerProvider.updateSale(sale.copyWith(id: widget.existing!.id));

    if (!mounted) {
      return;
    }

    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      showErrorSnack(
        context,
        context.read<LedgerProvider>().error ?? 'Error saving sale',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.read<LedgerProvider>();
    final inventory = context.read<InventoryProvider>();
    final customers = ledger.parties.where((p) => p.type == 'customer').toList();
    final completedDiamonds = inventory.diamonds
        .where((d) => d.status == 'completed' || _selectedDiamondIds.contains(d.id))
        .toList();
    final selectedCustomerName = _selectedCustomerName(customers);

    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existing == null ? 'Add Sale' : 'Edit Sale',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Bill No',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  widget.existing?.billNo ?? 'Will be assigned on save',
                  style: TextStyle(
                    color: widget.existing?.billNo == null
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: customers.isEmpty ? null : () => _openCustomerPicker(customers),
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Customer *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: Text(
                    selectedCustomerName ??
                        (customers.isEmpty ? 'No customers found' : 'Search and select customer'),
                    style: TextStyle(
                      color: selectedCustomerName == null
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: completedDiamonds.isEmpty
                    ? null
                    : () => _openDiamondPicker(completedDiamonds),
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Diamonds *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: Text(
                    _selectedDiamondIds.isEmpty
                        ? (completedDiamonds.isEmpty
                            ? 'No completed diamonds available'
                            : 'Search and select diamonds')
                        : '${_selectedDiamondIds.length} diamond(s) selected',
                    style: TextStyle(
                      color: _selectedDiamondIds.isEmpty
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              if (_selectedDiamondIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    itemCount: _selectedDiamondIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final id = _selectedDiamondIds.elementAt(index);
                      final diamond = _findDiamondById(completedDiamonds, id);
                      final code = diamond == null ? 'Diamond #$id' : _diamondLabel(diamond);
                      final ctrl = _lineAmountCtrls.putIfAbsent(
                        id,
                        () => TextEditingController(),
                      );
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              code,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${AppHelpers.formatCurrency(_lineAmountTotal())}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(labelText: 'Date (yyyy-MM-dd) *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Date is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 239, 218, 24),
                      foregroundColor: const Color(0xFF1A1A1A),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.existing == null ? 'Save' : 'Update'),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


