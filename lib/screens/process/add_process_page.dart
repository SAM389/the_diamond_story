import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/process.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/process_provider.dart';
import '../../widgets/data_table_widget.dart';

class AddProcessPage extends StatefulWidget {
  final Process? existing;

  const AddProcessPage({super.key, this.existing});

  @override
  State<AddProcessPage> createState() => _AddProcessPageState();
}

class _AddProcessPageState extends State<AddProcessPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedDiamondId;
  int? _selectedProcessTypeId;
  int? _selectedWorkerId;
  final _feeCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  double _selectedProcessFee(ProcessProvider provider) {
    for (final pt in provider.processTypes) {
      if (pt.id == _selectedProcessTypeId) return pt.cost;
    }
    return 0;
  }

  int? _resolvedWorkerId(List workers) {
    if (_selectedWorkerId != null &&
        workers.any((worker) => worker.id == _selectedWorkerId)) {
      return _selectedWorkerId;
    }
    final existingName = widget.existing?.partyName;
    if (existingName == null || existingName.isEmpty) return null;
    for (final worker in workers) {
      if (worker.name == existingName) return worker.id as int?;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _selectedDiamondId = existing?.diamondId;
    _selectedProcessTypeId = existing?.processTypeId;
    _feeCtrl.text = existing != null
        ? (existing.fee == existing.fee.roundToDouble()
            ? existing.fee.toStringAsFixed(0)
            : existing.fee.toStringAsFixed(2))
        : '';
    _fromCtrl.text = existing?.fromDate ?? AppHelpers.today();
    _notesCtrl.text = existing?.notes ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadDiamonds();
      context.read<LedgerProvider>().loadAll();
      context.read<ProcessProvider>().loadProcessTypes();
    });
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _fromCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDiamondId == null || _selectedProcessTypeId == null) {
      setState(() => _error = 'Select a diamond and process type.');
      return;
    }
    final workers = context
        .read<LedgerProvider>()
        .parties
        .where((party) => party.type == 'worker')
        .toList();
    final selectedWorkerId = _resolvedWorkerId(workers);
    dynamic selectedWorker;
    for (final worker in workers) {
      if (worker.id == selectedWorkerId) {
        selectedWorker = worker;
        break;
      }
    }
    if (selectedWorker == null) {
      setState(() => _error = 'Select a worker from parties.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final processProvider = context.read<ProcessProvider>();
      final process = Process(
        id: widget.existing?.id,
        diamondId: _selectedDiamondId!,
        processTypeId: _selectedProcessTypeId!,
        fee: double.tryParse(_feeCtrl.text.trim()) ?? 0,
        partyName: selectedWorker.name,
        fromDate: _fromCtrl.text.trim(),
        toDate: widget.existing?.toDate,
        status: widget.existing?.status ?? 'pending',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now().toIso8601String(),
      );
      final ok = widget.existing == null
          ? await processProvider.addProcess(process)
          : await processProvider.updateProcess(process);

      if (!mounted) {
        return;
      }

      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = processProvider.error ??
              (widget.existing == null
                  ? 'Failed to add process'
                  : 'Failed to update process');
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Process' : 'Edit Process'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Consumer3<InventoryProvider, ProcessProvider, LedgerProvider>(
          builder: (context, invProvider, procProvider, ledgerProvider, child) {
            final availableDiamonds = invProvider.diamonds
                .where((d) => d.status != 'sold')
                .toList();
            final workers = ledgerProvider.parties
                .where((party) => party.type == 'worker')
                .toList();
            final selectedDiamondValue = availableDiamonds.any(
              (d) => d.id == _selectedDiamondId,
            )
                ? _selectedDiamondId
                : null;
            final selectedProcessTypeValue = procProvider.processTypes.any(
              (pt) => pt.id == _selectedProcessTypeId,
            )
                ? _selectedProcessTypeId
                : null;
            final selectedWorkerValue = _resolvedWorkerId(workers);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existing == null ? 'Add New Process' : 'Edit Process',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Diamond', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<int>(
                                value: selectedDiamondValue,
                                isExpanded: true,
                                underline: const SizedBox(),
                                hint: const Text('Select a diamond'),
                                items: availableDiamonds.isEmpty
                                    ? const [DropdownMenuItem(value: -1, child: Text('No available diamonds'))]
                                    : availableDiamonds.map((d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text('${d.diamondCode} (${d.weight} ct)'),
                                        )).toList(),
                                onChanged: availableDiamonds.isEmpty
                                    ? null
                                    : (v) => setState(() => _selectedDiamondId = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Process Type *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<int>(
                                value: selectedProcessTypeValue,
                                isExpanded: true,
                                underline: const SizedBox(),
                                hint: const Text('Select a process type'),
                                items: procProvider.processTypes.isEmpty
                                    ? const [DropdownMenuItem(value: -1, child: Text('No process types'))]
                                    : procProvider.processTypes.map((pt) => DropdownMenuItem(
                                          value: pt.id,
                                          child: Text(pt.name),
                                        )).toList(),
                                onChanged: procProvider.processTypes.isEmpty
                                    ? null
                                    : (v) {
                                        setState(() {
                                          _selectedProcessTypeId = v;
                                          final fee = _selectedProcessFee(procProvider);
                                          _feeCtrl.text = fee == 0
                                              ? ''
                                              : fee.toStringAsFixed(
                                                  fee == fee.roundToDouble() ? 0 : 2,
                                                );
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Process Fee',
                          child: TextFormField(
                            controller: _feeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Enter fee manually, e.g. 0 or 500',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (double.tryParse(v.trim()) == null) {
                                return 'Enter a valid fee';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Worker',
                          required: true,
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedWorkerValue,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            hint: const Text('Select a worker'),
                            items: workers.isEmpty
                                ? const [
                                    DropdownMenuItem(
                                      value: -1,
                                      child: Text('No workers found in parties'),
                                    ),
                                  ]
                                : workers
                                    .map(
                                      (worker) => DropdownMenuItem<int>(
                                        value: worker.id,
                                        child: Text(worker.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: workers.isEmpty
                                ? null
                                : (value) => setState(() => _selectedWorkerId = value),
                            validator: (_) {
                              if (workers.isEmpty) return 'Add a worker in Parties first';
                              if (_resolvedWorkerId(workers) == null) {
                                return 'Worker is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'From Date (yyyy-MM-dd)',
                          required: true,
                          child: TextFormField(
                            controller: _fromCtrl,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'From date is required' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'Notes',
                          child: TextFormField(
                            controller: _notesCtrl,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(widget.existing == null ? 'Add Process' : 'Save Changes'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
