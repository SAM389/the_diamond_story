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
                  onPressed: () async {
                    await context.read<InventoryProvider>().loadDiamonds();
                    await showDialog<bool>(
                      context: context,
                      builder: (_) => const _SaleDialog(),
                    );
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

                return (sale.partyName ?? '').toLowerCase().contains(_searchQuery) ||
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
    final selectedCustomerName = _selectedCustomerName(customers);

    return AlertDialog(
      title: const Text('Add Sale'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
