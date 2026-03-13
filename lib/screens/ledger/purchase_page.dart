import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/purchase.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_table_widget.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
      context.read<InventoryProvider>().loadRoughStones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Purchases',
            subtitle: 'Record rough stone purchases',
            action: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Purchase'),
              onPressed: () =>
                  showDialog(context: context, builder: (_) => const _PurchaseDialog()),
            ),
          ),
        ),
        Expanded(
          child: Consumer2<LedgerProvider, InventoryProvider>(
            builder: (context, provider, inventoryProvider, _) {
              if (provider.loading || inventoryProvider.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: TableSkeleton(rows: 6),
                );
              }

              if (provider.purchases.isEmpty) {
                return const EmptyState(
                  message: 'No purchases yet.',
                  icon: Icons.shopping_bag_outlined,
                  ctaLabel: 'Record your first purchase',
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(provider.purchases),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildTable(
                        provider.purchases,
                        inventoryProvider.roughStones,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<Purchase> purchases) {
    final totalAmount = purchases.fold<double>(0, (sum, p) => sum + p.amount);
    final linkedLots = purchases.where((p) => p.lotNo != null && p.lotNo!.isNotEmpty).length;
    final uniqueSuppliers = purchases
        .map((p) => p.partyName)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.shopping_bag_outlined,
          label: 'Total Purchases',
          value: purchases.length.toString(),
          color: AppTheme.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.currency_rupee_outlined,
          label: 'Total Amount',
          value: AppHelpers.formatCurrency(totalAmount),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.local_shipping_outlined,
          label: 'Suppliers',
          value: uniqueSuppliers.toString(),
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.inventory_2_outlined,
          label: 'Linked Lots',
          value: linkedLots.toString(),
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }

  Widget _buildTable(List<Purchase> purchases, List<dynamic> roughStones) {
    final titleByLotNo = <String, String>{};
    for (final stone in roughStones) {
      titleByLotNo[stone.lotNo as String] = stone.title as String;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 48,
              color: AppTheme.primary,
              child: Row(
                children: [
                  _hCell('Party', flex: 3),
                  _hCell('Lot No', flex: 2),
                  _hCell('Title', flex: 3),
                  _hCell('Amount (Rs)', flex: 2),
                  _hCell('Date', flex: 2),
                  _hCell('Notes', flex: 3),
                  _hCell('Actions', flex: 1),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: purchases.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final p = purchases[i];
                  final lotTitle = (p.lotNo == null || p.lotNo!.isEmpty)
                      ? '-'
                      : (titleByLotNo[p.lotNo!] ?? '-');
                  return Container(
                    height: 52,
                    color: i.isEven ? Colors.white : const Color(0xFFFAFBFD),
                    child: Row(
                      children: [
                        _dCell(
                          flex: 3,
                          child: Text(
                            p.partyName ?? '-',
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
                              color: AppTheme.primary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.lotNo ?? '-',
                              style: GoogleFonts.inter(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 3,
                          child: Text(
                            lotTitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.formatCurrency(p.amount),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.displayDate(p.date),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        _dCell(
                          flex: 3,
                          child: Text(
                            p.notes ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 1,
                          child: _actionBtn(
                            icon: Icons.delete_outline,
                            color: Colors.red.shade600,
                            tooltip: 'Delete purchase',
                            onTap: () async {
                              final ok = await showDeleteConfirmDialog(
                                  context, 'purchase entry');
                              if (ok && mounted) {
                                await context.read<LedgerProvider>().deletePurchase(p.id!);
                                if (mounted) {
                                  showSuccessSnack(context, 'Purchase deleted');
                                }
                              }
                            },
                          ),
                        ),
                      ],
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
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppTheme.divider),
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

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog();

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _partyId;
  int? _lotId;
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = AppHelpers.today();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _partyId == null) {
      if (_partyId == null) {
        showErrorSnack(context, 'Please select a supplier');
      }
      return;
    }

    setState(() => _saving = true);

    final purchase = Purchase(
      partyId: _partyId!,
      lotId: _lotId,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      date: _dateCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    final ok = await context.read<LedgerProvider>().addPurchase(purchase);
    
    if (mounted) {
      Navigator.pop(context);
      if (ok) {
        showSuccessSnack(context, 'Purchase recorded');
      } else {
        showErrorSnack(context, 'Error saving purchase');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final inventory = context.watch<InventoryProvider>();
    final suppliers = ledger.parties.where((p) => p.type == 'supplier').toList();

    return AlertDialog(
      title: const Text('Add Purchase'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _partyId,
                decoration: const InputDecoration(labelText: 'Supplier *', border: OutlineInputBorder()),
                items: suppliers.isEmpty
                    ? const [DropdownMenuItem(value: -1, child: Text('No suppliers found'))]
                    : suppliers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: suppliers.isEmpty ? null : (v) => setState(() => _partyId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _lotId,
                decoration: const InputDecoration(labelText: 'Rough Stone Lot (optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('� None �')),
                  ...inventory.roughStones.map((s) => DropdownMenuItem(value: s.id, child: Text(s.lotNo))),
                ],
                onChanged: (v) => setState(() => _lotId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (?) *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Amount is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(labelText: 'Date (yyyy-MM-dd) *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Date is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
