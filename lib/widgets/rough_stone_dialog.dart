import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/party.dart';
import '../models/rough_stone.dart';
import '../providers/inventory_provider.dart';
import '../providers/ledger_provider.dart';
import 'data_table_widget.dart';

class RoughStoneDialog extends StatefulWidget {
  final RoughStone? existing;

  const RoughStoneDialog({super.key, this.existing});

  @override
  State<RoughStoneDialog> createState() => _RoughStoneDialogState();
}

class _RoughStoneDialogState extends State<RoughStoneDialog> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lotNo;
  late TextEditingController _title;
  late TextEditingController _weight;
  late TextEditingController _quality;
  late TextEditingController _price;
  late TextEditingController _date;
  late TextEditingController _notes;
  int? _supplierId;
  bool _saving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final stone = widget.existing;
    _lotNo = TextEditingController(text: stone?.lotNo ?? '');
    _title = TextEditingController(text: stone?.title ?? '');
    _weight = TextEditingController(text: stone != null ? stone.weight.toString() : '');
    _quality = TextEditingController(text: stone?.quality ?? '');
    _price = TextEditingController(text: stone != null ? stone.purchasePrice.toString() : '');
    _date = TextEditingController(text: stone?.purchaseDate ?? AppHelpers.today());
    _notes = TextEditingController(text: stone?.notes ?? '');
    _supplierId = stone?.supplierId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ledger = context.read<LedgerProvider>();
      if (ledger.parties.isEmpty) {
        ledger.loadAll();
      }
    });

    if (stone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final nextLot = await context.read<InventoryProvider>().getNextLotNo();
        if (mounted) {
          _lotNo.text = nextLot;
        }
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

  Future<bool> _confirmEditSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Changes',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Do you want to make the changes?',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes, Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed ?? false;
  }

  String? _selectedSupplierName(List<Party> suppliers) {
    if (_supplierId == null) return null;
    for (final supplier in suppliers) {
      if (supplier.id == _supplierId) return supplier.name;
    }
    return 'Unknown supplier (#$_supplierId)';
  }

  Future<void> _openSupplierPicker(List<Party> suppliers) async {
    if (suppliers.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = suppliers.where((supplier) {
              return supplier.name.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Supplier'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search supplier',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No supplier matches your search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final supplier = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(supplier.name),
                                  trailing: supplier.id == _supplierId
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, supplier.id),
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
    setState(() => _supplierId = selectedId);
  }

  Future<void> _pickPurchaseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: AppHelpers.parseDate(_date.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || selected == null) return;
    setState(() => _date.text = AppHelpers.formatDate(selected));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) {
      setState(() => _errorMsg = 'Supplier is required.');
      return;
    }

    if (widget.existing != null) {
      final confirmed = await _confirmEditSave();
      if (!confirmed) return;
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

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      showSuccessSnack(
        context,
        widget.existing == null ? 'Rough stone added.' : 'Rough stone updated.',
      );
    } else {
      setState(() {
        _saving = false;
        _errorMsg = provider.error ?? 'Error saving.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context
        .watch<LedgerProvider>()
        .parties
        .where((p) => p.type == 'supplier')
        .toList();
    final selectedSupplierName = _selectedSupplierName(suppliers);

    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x4A000000), blurRadius: 40, offset: Offset(0, 18)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existing == null ? 'Add Rough Stone' : 'Edit Rough Stone',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AppFormField(
                            label: 'Lot Number',
                            required: true,
                            child: TextFormField(
                              controller: _lotNo,
                              decoration: const InputDecoration(hintText: 'LOT-001'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppFormField(
                            label: 'Title',
                            required: true,
                            child: TextFormField(
                              controller: _title,
                              decoration: const InputDecoration(hintText: 'Stone name'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppFormField(
                            label: 'Weight (ct)',
                            required: true,
                            child: TextFormField(
                              controller: _weight,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: '0.000'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppFormField(
                            label: 'Quality',
                            required: true,
                            child: TextFormField(
                              controller: _quality,
                              decoration: const InputDecoration(hintText: 'A / B / C'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppFormField(
                            label: 'Purchase Price (Rs)',
                            required: true,
                            child: TextFormField(
                              controller: _price,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: '0.00'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppFormField(
                            label: 'Purchase Date',
                            required: true,
                            child: TextFormField(
                              controller: _date,
                              readOnly: true,
                              onTap: _pickPurchaseDate,
                              decoration: const InputDecoration(
                                hintText: 'yyyy-MM-dd',
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Supplier',
                      required: true,
                      child: InkWell(
                        onTap: suppliers.isEmpty ? null : () => _openSupplierPicker(suppliers),
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            suffixIcon: Icon(Icons.search),
                          ),
                          child: Text(
                            selectedSupplierName ??
                                (suppliers.isEmpty
                                    ? 'No suppliers available'
                                    : 'Search and select supplier'),
                            style: TextStyle(
                              color: selectedSupplierName == null
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (suppliers.isEmpty) ...[
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
                    AppFormField(
                      label: 'Notes',
                      child: TextFormField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Optional notes'),
                      ),
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _brightActionYellow,
                            foregroundColor: const Color(0xFF1A1A1A),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ],
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


