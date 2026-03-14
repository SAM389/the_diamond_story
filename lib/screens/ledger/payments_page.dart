import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/party.dart';
import '../../models/payment.dart';
import '../../providers/ledger_provider.dart';
import '../../widgets/data_table_widget.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
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
            title: 'Payments',
            subtitle: 'Track all payments and receipts',
            action: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Payment'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _PaymentDialog(),
              ),
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

              if (provider.payments.isEmpty) {
                return const EmptyState(
                  message: 'No payments yet.',
                  icon: Icons.account_balance_wallet_outlined,
                  ctaLabel: 'Record your first payment',
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(provider.payments),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(provider.payments)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<Payment> payments) {
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final paidAmount = payments
        .where((p) => p.type == 'paid')
        .fold<double>(0, (sum, p) => sum + p.amount);
    final receivedAmount = payments
        .where((p) => p.type == 'received')
        .fold<double>(0, (sum, p) => sum + p.amount);
    final pending = payments.where((p) => p.status == 'pending').length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Total Entries',
          value: payments.length.toString(),
          color: AppTheme.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.call_made_outlined,
          label: 'Paid',
          value: AppHelpers.formatCurrency(paidAmount),
          color: const Color(0xFFE65100),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.call_received_outlined,
          label: 'Received',
          value: AppHelpers.formatCurrency(receivedAmount),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.pending_actions_outlined,
          label: 'Pending / Total',
          value: '$pending / ${AppHelpers.formatCurrency(totalAmount)}',
          color: const Color(0xFF1565C0),
        ),
      ],
    );
  }

  Widget _buildTable(List<Payment> payments) {
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
                  _hCell('Amount (Rs)', flex: 2),
                  _hCell('Type', flex: 2),
                  _hCell('Category', flex: 2),
                  _hCell('Date', flex: 2),
                  _hCell('Status', flex: 2),
                  _hCell('Actions', flex: 2),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final p = payments[i];
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
                          child: StatusChip(status: p.type),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            p.category ?? '-',
                            style: GoogleFonts.inter(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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
                          flex: 2,
                          child: StatusChip(status: p.status),
                        ),
                        _dCell(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.status == 'pending')
                                _actionBtn(
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green.shade700,
                                  tooltip: 'Mark completed',
                                  onTap: () async {
                                    await context
                                        .read<LedgerProvider>()
                                        .updatePayment(
                                          p.copyWith(status: 'completed'),
                                        );
                                    if (mounted) {
                                      showSuccessSnack(
                                        context,
                                        'Payment marked completed',
                                      );
                                    }
                                  },
                                ),
                              _actionBtn(
                                icon: Icons.delete_outline,
                                color: Colors.red.shade600,
                                tooltip: 'Delete payment',
                                onTap: () async {
                                  final ok = await showDeleteConfirmDialog(
                                    context,
                                    'payment entry',
                                  );
                                  if (ok && mounted) {
                                    await context
                                        .read<LedgerProvider>()
                                        .deletePayment(p.id!);
                                    if (mounted) {
                                      showSuccessSnack(context, 'Payment deleted');
                                    }
                                  }
                                },
                              ),
                            ],
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

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog();

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _partyId;
  final _amountCtrl = TextEditingController();
  String _type = 'paid';
  String? _category;
  final _dateCtrl = TextEditingController();
  String _status = 'pending';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  String? _selectedPartyName(List<Party> parties) {
    if (_partyId == null) return null;
    for (final party in parties) {
      if (party.id == _partyId) return party.name;
    }
    return null;
  }

  Future<void> _openPartyPicker(List<Party> parties) async {
    if (parties.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final q = query.trim().toLowerCase();
            final filtered = parties
                .where((p) => p.name.toLowerCase().contains(q))
                .toList();

            return AlertDialog(
              title: const Text('Select Party'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search party',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() => query = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No party matches your search.'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final party = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(party.name),
                                  trailing: party.id == _partyId
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, party.id),
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
        showErrorSnack(context, 'Please select a party');
      }
      return;
    }

    setState(() => _saving = true);

    final payment = Payment(
      partyId: _partyId!,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      type: _type,
      category: _category,
      date: _dateCtrl.text.trim(),
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final ok = await context.read<LedgerProvider>().addPayment(payment);
    
    if (mounted) {
      Navigator.pop(context);
      if (ok) {
        showSuccessSnack(context, 'Payment recorded');
      } else {
        showErrorSnack(context, 'Error saving payment');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final selectedPartyName = _selectedPartyName(ledger.parties);

    return AlertDialog(
      title: const Text('Add Payment'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: ledger.parties.isEmpty
                      ? null
                      : () => _openPartyPicker(ledger.parties),
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Party *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    child: Text(
                      selectedPartyName ??
                          (ledger.parties.isEmpty
                              ? 'No parties found'
                              : 'Search and select party'),
                      style: TextStyle(
                        color: selectedPartyName == null
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount (?) *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Amount is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid (Outgoing)')),
                    DropdownMenuItem(value: 'received', child: Text('Received (Incoming)')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category (optional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('� None �')),
                    ...ledger.expenseCategories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date (yyyy-MM-dd) *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Date is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
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
