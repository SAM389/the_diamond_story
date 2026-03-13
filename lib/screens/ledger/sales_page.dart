import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/sale.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_table_widget.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
      context.read<InventoryProvider>().loadDiamonds();
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
            title: 'Sales',
            subtitle: 'Record diamond sales',
            action: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Sale'),
              onPressed: () async {
                await context.read<InventoryProvider>().loadDiamonds();
                await showDialog<bool>(
                  context: context,
                  builder: (_) => const _SaleDialog(),
                );
              },
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

              if (provider.sales.isEmpty) {
                return const EmptyState(
                  message: 'No sales yet.',
                  icon: Icons.sell_outlined,
                  ctaLabel: 'Record your first sale',
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(provider.sales),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(provider.sales)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<Sale> sales) {
    final totalValue = sales.fold<double>(0, (sum, s) => sum + s.price);
    final linkedDiamonds =
        sales.where((s) => s.diamondCode != null && s.diamondCode!.isNotEmpty).length;
    final uniqueCustomers = sales
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
          value: sales.length.toString(),
          color: AppTheme.primary,
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
                  _hCell('Customer', flex: 3),
                  _hCell('Diamond', flex: 2),
                  _hCell('Price (Rs)', flex: 2),
                  _hCell('Date', flex: 2),
                  _hCell('Notes', flex: 4),
                  _hCell('Actions', flex: 1),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final s = sales[i];
                  return Container(
                    height: 52,
                    color: i.isEven ? Colors.white : const Color(0xFFFAFBFD),
                    child: Row(
                      children: [
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
                              color: AppTheme.primary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.diamondCode ?? '-',
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
                          flex: 4,
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
                          child: _actionBtn(
                            icon: Icons.delete_outline,
                            color: Colors.red.shade600,
                            tooltip: 'Delete sale',
                            onTap: () async {
                              final ok = await showDeleteConfirmDialog(context, 'sale entry');
                              if (ok && mounted) {
                                final deleted = await context.read<LedgerProvider>().deleteSale(s.id!);
                                if (mounted) {
                                  if (deleted) {
                                    await context.read<InventoryProvider>().loadDiamonds();
                                    if (mounted) {
                                      showSuccessSnack(context, 'Sale deleted');
                                    }
                                  } else {
                                    showErrorSnack(
                                      context,
                                      context.read<LedgerProvider>().error ?? 'Failed to delete sale',
                                    );
                                  }
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

class _SaleDialog extends StatefulWidget {
  const _SaleDialog();

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _partyId;
  int? _diamondId;
  final _priceCtrl = TextEditingController();
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
    _priceCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _partyId == null) {
      if (_partyId == null) {
        showErrorSnack(context, 'Please select a customer');
      }
      return;
    }

    setState(() => _saving = true);

    final sale = Sale(
      partyId: _partyId!,
      diamondId: _diamondId,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      date: _dateCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    final ok = await context.read<LedgerProvider>().addSale(sale);

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
    final completedDiamonds = inventory.diamonds.where((d) => d.status == 'completed').toList();

    return AlertDialog(
      title: const Text('Add Sale'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _partyId,
                decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder()),
                items: customers.isEmpty
                    ? const [DropdownMenuItem(value: -1, child: Text('No customers found'))]
                    : customers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: customers.isEmpty ? null : (v) => setState(() => _partyId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _diamondId,
                decoration: const InputDecoration(labelText: 'Diamond (optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('� None �')),
                  ...completedDiamonds.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.diamondCode} (${d.weight} ct)'))),
                ],
                onChanged: (v) => setState(() => _diamondId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price (?) *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Price is required' : null,
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
