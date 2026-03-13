import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../models/rough_stone.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../widgets/data_table_widget.dart';

class RoughStonePage extends StatefulWidget {
  const RoughStonePage({super.key});

  @override
  State<RoughStonePage> createState() => _RoughStonePageState();
}

class _RoughStonePageState extends State<RoughStonePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadRoughStones();
      context.read<InventoryProvider>().loadDiamonds();
    });
  }

  void _showAddDialog({RoughStone? existing}) {
    showDialog(context: context, builder: (_) => _RoughStoneDialog(existing: existing));
  }

  void _showSplitDialog(RoughStone stone) {
    showDialog(context: context, builder: (_) => _SplitLotDialog(stone: stone));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -- Page Header ---------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Rough Stones',
            subtitle: 'Inventory \u203a Rough Stones',
            action: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Rough Stone'),
              onPressed: () => _showAddDialog(),
            ),
          ),
        ),
        // -- Body ----------------------------------------------------------
        Expanded(
          child: Consumer<InventoryProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: TableSkeleton(rows: 6),
                );
              }
              if (provider.roughStones.isEmpty) {
                return EmptyState(
                  message: 'No rough stones yet.\nClick "Add Rough Stone" to get started.',
                  icon: Icons.circle_outlined,
                  ctaLabel: 'Add Rough Stone',
                  onCta: () => _showAddDialog(),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(provider.roughStones),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(provider.roughStones)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -- Summary stat cards ----------------------------------------------------
  Widget _buildStats(List<RoughStone> stones) {
    final totalWeight = stones.fold<double>(0, (s, r) => s + r.weight);
    final totalValue = stones.fold<double>(0, (s, r) => s + r.purchasePrice);
    return Row(
      children: [
        _StatCard(
          icon: Icons.inventory_2_outlined,
          label: 'Total Lots',
          value: stones.length.toString(),
          color: AppTheme.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.scale_outlined,
          label: 'Total Weight',
          value: '${totalWeight.toStringAsFixed(3)} ct',
          color: const Color(0xFF0277BD),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.currency_rupee_outlined,
          label: 'Total Value',
          value: AppHelpers.formatCurrency(totalValue),
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  // -- Full-width table -------------------------------------------------------
  Widget _buildTable(List<RoughStone> stones) {
    final splitLots = context
        .watch<InventoryProvider>()
        .diamonds
        .map((d) => d.parentLot)
        .toSet();

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
            // Header row
            Container(
              height: 48,
              color: AppTheme.primary,
              child: Row(children: [
                _hCell('Lot No', flex: 2),
                _hCell('Title', flex: 3),
                _hCell('Weight (ct)', flex: 2),
                _hCell('Quality', flex: 2),
                _hCell('Price (\u20b9)', flex: 3),
                _hCell('Date', flex: 2),
                _hCell('Actions', flex: 2),
              ]),
            ),
            // Data rows
            Expanded(
              child: ListView.separated(
                itemCount: stones.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final s = stones[i];
                  final alreadySplit = splitLots.contains(s.lotNo);
                  return Container(
                    height: 52,
                    color: i.isEven ? Colors.white : const Color(0xFFFAFBFD),
                    child: Row(children: [
                      _dCell(
                        flex: 2,
                        child: Text(s.lotNo,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                                fontSize: 13)),
                      ),
                      _dCell(
                          flex: 3,
                          child: Text(s.title,
                              style: GoogleFonts.inter(fontSize: 13))),
                      _dCell(
                          flex: 2,
                          child: Text(s.weight.toStringAsFixed(3),
                              style: GoogleFonts.inter(fontSize: 13))),
                      _dCell(flex: 2, child: _qualityBadge(s.quality)),
                      _dCell(
                        flex: 3,
                        child: Text(
                            AppHelpers.formatCurrency(s.purchasePrice),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      _dCell(
                        flex: 2,
                        child: Text(
                            AppHelpers.displayDate(s.purchaseDate),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                      ),
                      _dCell(
                        flex: 2,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _actionBtn(
                            icon: Icons.call_split_rounded,
                            color: alreadySplit
                                ? AppTheme.textMuted
                                : const Color(0xFF43A047),
                            tooltip: alreadySplit
                                ? 'Already split into diamonds'
                                : 'Split into Diamonds',
                            onTap: alreadySplit ? null : () => _showSplitDialog(s),
                          ),
                          _actionBtn(
                            icon: Icons.edit_outlined,
                            color: AppTheme.primary,
                            tooltip: 'Edit',
                            onTap: () => _showAddDialog(existing: s),
                          ),
                          _actionBtn(
                            icon: Icons.delete_outline,
                            color: Colors.red.shade600,
                            tooltip: 'Delete',
                            onTap: () async {
                              final ok = await showDeleteConfirmDialog(
                                  context, s.lotNo);
                              if (ok && mounted) {
                                final success = await context
                                    .read<InventoryProvider>()
                                    .deleteRoughStone(s.id!);
                                if (mounted) {
                                  if (success) {
                                    showSuccessSnack(
                                        context, 'Rough stone deleted.');
                                  } else {
                                    showErrorSnack(context,
                                        'Failed to delete rough stone.');
                                  }
                                }
                              }
                            },
                          ),
                        ]),
                      ),
                    ]),
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
          child: Text(text,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
        ),
      );

  Widget _dCell({required int flex, required Widget child}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      );

  Widget _qualityBadge(String quality) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(quality,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7A5C00))),
      );

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) =>
      Tooltip(
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

// -- Stat card widget ----------------------------------------------------------
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
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoughStoneDialog extends StatefulWidget {
  final RoughStone? existing;
  const _RoughStoneDialog({this.existing});

  @override
  State<_RoughStoneDialog> createState() => _RoughStoneDialogState();
}

class _RoughStoneDialogState extends State<_RoughStoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lotNo, _title, _weight, _quality, _price, _date, _notes;
  int? _supplierId;
  bool _saving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _lotNo = TextEditingController(text: s?.lotNo ?? '');
    _title = TextEditingController(text: s?.title ?? '');
    _weight = TextEditingController(text: s != null ? s.weight.toString() : '');
    _quality = TextEditingController(text: s?.quality ?? '');
    _price = TextEditingController(text: s != null ? s.purchasePrice.toString() : '');
    _date = TextEditingController(text: s?.purchaseDate ?? AppHelpers.today());
    _notes = TextEditingController(text: s?.notes ?? '');
    _supplierId = s?.supplierId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ledger = context.read<LedgerProvider>();
      if (ledger.parties.isEmpty) {
        ledger.loadAll();
      }
    });

    if (s == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final nextLot = await context.read<InventoryProvider>().getNextLotNo();
        if (mounted) _lotNo.text = nextLot;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_lotNo, _title, _weight, _quality, _price, _date, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) {
      setState(() => _errorMsg = 'Supplier is required.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    final stone = RoughStone(
      id: widget.existing?.id,
      lotNo: _lotNo.text.trim(),
      title: _title.text.trim(),
      weight: double.tryParse(_weight.text) ?? 0,
      quality: _quality.text.trim(),
      purchasePrice: double.tryParse(_price.text) ?? 0,
      purchaseDate: _date.text.trim(),
      supplierId: _supplierId,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final provider = context.read<InventoryProvider>();
    final success = widget.existing == null
        ? await provider.addRoughStone(stone)
        : await provider.updateRoughStone(stone);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        showSuccessSnack(context, widget.existing == null ? 'Rough stone added.' : 'Rough stone updated.');
      } else {
        setState(() {
          _saving = false;
          _errorMsg = provider.error ?? 'Error saving.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context
        .watch<LedgerProvider>()
        .parties
        .where((p) => p.type == 'supplier')
        .toList();
    final supplierItems = suppliers
        .where((p) => p.id != null)
        .map((p) => DropdownMenuItem<int>(value: p.id!, child: Text(p.name)))
        .toList();

    if (_supplierId != null && !supplierItems.any((item) => item.value == _supplierId)) {
      supplierItems.insert(
        0,
        DropdownMenuItem<int>(
          value: _supplierId,
          child: Text('Unknown supplier (#$_supplierId)'),
        ),
      );
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.existing == null ? 'Add Rough Stone' : 'Edit Rough Stone',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: AppFormField(label: 'Lot Number', required: true, child: TextFormField(controller: _lotNo, decoration: const InputDecoration(hintText: 'LOT-001'), validator: (v) => v!.isEmpty ? 'Required' : null))),
                    const SizedBox(width: 16),
                    Expanded(child: AppFormField(label: 'Title', required: true, child: TextFormField(controller: _title, decoration: const InputDecoration(hintText: 'Stone name'), validator: (v) => v!.isEmpty ? 'Required' : null))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: AppFormField(label: 'Weight (ct)', required: true, child: TextFormField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0.000'), validator: (v) => v!.isEmpty ? 'Required' : null))),
                    const SizedBox(width: 16),
                    Expanded(child: AppFormField(label: 'Quality', required: true, child: TextFormField(controller: _quality, decoration: const InputDecoration(hintText: 'A / B / C'), validator: (v) => v!.isEmpty ? 'Required' : null))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: AppFormField(label: 'Purchase Price (\u20b9)', required: true, child: TextFormField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0.00'), validator: (v) => v!.isEmpty ? 'Required' : null))),
                    const SizedBox(width: 16),
                    Expanded(child: AppFormField(label: 'Purchase Date', required: true, child: TextFormField(controller: _date, decoration: const InputDecoration(hintText: 'yyyy-MM-dd'), validator: (v) => v!.isEmpty ? 'Required' : null))),
                  ]),
                  const SizedBox(height: 16),
                  AppFormField(
                    label: 'Supplier',
                    required: true,
                    child: DropdownButtonFormField<int>(
                      initialValue: _supplierId,
                      decoration: InputDecoration(
                        hintText: supplierItems.isEmpty ? 'No suppliers available' : 'Select supplier',
                      ),
                      items: supplierItems,
                      onChanged: supplierItems.isEmpty ? null : (value) => setState(() => _supplierId = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                  if (supplierItems.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add a supplier first in Ledger > Parties.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppFormField(label: 'Notes', child: TextFormField(controller: _notes, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional notes'))),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)), child: Text(_errorMsg!, style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade700))),
                  ],
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitLotDialog extends StatefulWidget {
  final RoughStone stone;
  const _SplitLotDialog({required this.stone});

  @override
  State<_SplitLotDialog> createState() => _SplitLotDialogState();
}

class _SplitLotDialogState extends State<_SplitLotDialog> {
  final _countCtrl = TextEditingController(text: '2');
  bool _splitting = false;

  @override
  void dispose() { _countCtrl.dispose(); super.dispose(); }

  Future<void> _split() async {
    final count = int.tryParse(_countCtrl.text.trim()) ?? 0;
    if (count < 1 || count > 26) {
      showErrorSnack(context, 'Enter a number between 1 and 26.');
      return;
    }

    setState(() => _splitting = true);
    final provider = context.read<InventoryProvider>();
    final ok = await provider.splitLot(widget.stone.lotNo, count, widget.stone.weight);

    if (mounted) {
      Navigator.pop(context);
      if (ok) {
        showSuccessSnack(context, 'Split ${widget.stone.lotNo} into $count diamonds.');
      } else {
        showErrorSnack(context, provider.error ?? 'Failed to split lot.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Split ${widget.stone.lotNo}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('Total weight: ${widget.stone.weight.toStringAsFixed(3)} ct', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              AppFormField(label: 'Number of Diamonds', required: true, child: TextField(controller: _countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '1 \u2014 26'), onChanged: (_) => setState(() {}))),
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: _countCtrl,
                builder: (context, value, child) {
                  final n = int.tryParse(_countCtrl.text) ?? 0;
                  if (n < 1 || n > 26) return const SizedBox();
                  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                  final codes = List.generate(n, (i) => '${widget.stone.lotNo}${letters[i]}');
                  return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)), child: Text('Will create: ${codes.join(', ')}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary)));
                },
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _splitting ? null : _split, child: _splitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Split Lot')),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
