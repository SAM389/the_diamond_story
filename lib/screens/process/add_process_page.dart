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
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  final _formKey = GlobalKey<FormState>();
  int? _selectedDiamondId;
  int? _selectedProcessTypeId;
  int? _selectedWorkerId;
  final _feeCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  double _selectedProcessFee(ProcessProvider provider) {
    for (final pt in provider.processTypes) {
      if (pt.id == _selectedProcessTypeId) return pt.cost;
    }
    return 0;
  }

  String? _selectedDiamondLabel(List availableDiamonds) {
    if (_selectedDiamondId == null) return null;
    for (final diamond in availableDiamonds) {
      if (diamond.id == _selectedDiamondId) {
        return '${diamond.diamondCode} (${diamond.weight} ct)';
      }
    }
    return null;
  }

  String? _selectedProcessTypeLabel(ProcessProvider provider) {
    if (_selectedProcessTypeId == null) return null;
    for (final processType in provider.processTypes) {
      if (processType.id == _selectedProcessTypeId) return processType.name;
    }
    return null;
  }

  String? _selectedWorkerLabel(List workers) {
    final selectedWorkerId = _resolvedWorkerId(workers);
    if (selectedWorkerId == null) return null;
    for (final worker in workers) {
      if (worker.id == selectedWorkerId) return worker.name as String;
    }
    return widget.existing?.partyName;
  }

  Future<void> _openDiamondPicker(List availableDiamonds) async {
    if (availableDiamonds.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = availableDiamonds.where((diamond) {
              final label = '${diamond.diamondCode} (${diamond.weight} ct)'.toLowerCase();
              return label.contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Diamond'),
              content: SizedBox(
                width: 420,
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
                                final label = '${diamond.diamondCode} (${diamond.weight} ct)';
                                return ListTile(
                                  dense: true,
                                  title: Text(label),
                                  trailing: diamond.id == _selectedDiamondId
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, diamond.id as int?),
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
    setState(() => _selectedDiamondId = selectedId);
  }

  Future<void> _openProcessTypePicker(ProcessProvider procProvider) async {
    if (procProvider.processTypes.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = procProvider.processTypes.where((processType) {
              return processType.name.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Process Type'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search process type',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No process type matches your search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final processType = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(processType.name),
                                  trailing: processType.id == _selectedProcessTypeId
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, processType.id),
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
    setState(() {
      _selectedProcessTypeId = selectedId;
      final fee = _selectedProcessFee(procProvider);
      _feeCtrl.text = fee == 0
          ? ''
          : fee.toStringAsFixed(fee == fee.roundToDouble() ? 0 : 2);
    });
  }

  Future<void> _openWorkerPicker(List workers) async {
    if (workers.isEmpty) return;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = workers.where((worker) {
              return (worker.name as String).toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Worker'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search worker',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No worker matches your search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final worker = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(worker.name as String),
                                  trailing: worker.id == _resolvedWorkerId(workers)
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, worker.id as int?),
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
    setState(() => _selectedWorkerId = selectedId);
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

  Future<void> _pickFromDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: AppHelpers.parseDate(_fromCtrl.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || selected == null) return;
    setState(() => _fromCtrl.text = AppHelpers.formatDate(selected));
  }

  Future<void> _pickToDate() async {
    final fromDate = AppHelpers.parseDate(_fromCtrl.text);
    final initialDate = _toCtrl.text.isEmpty
        ? fromDate
        : AppHelpers.parseDate(_toCtrl.text, fallback: fromDate);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || selected == null) return;
    setState(() => _toCtrl.text = AppHelpers.formatDate(selected));
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
    _toCtrl.text = (existing?.status != 'completed' ? existing?.toDate : null) ?? '';
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
    _toCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_toCtrl.text.trim().isNotEmpty) {
      final from = AppHelpers.parseDate(_fromCtrl.text.trim());
      final to = AppHelpers.parseDate(_toCtrl.text.trim());
      if (to.isBefore(from)) {
        setState(() => _error = 'To date cannot be before from date.');
        return;
      }
    }
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
        toDate: _toCtrl.text.trim().isEmpty ? null : _toCtrl.text.trim(),
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
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: AppTheme.accent,
      ),
      body: Container(
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
          padding: const EdgeInsets.all(28),
          child: Consumer3<InventoryProvider, ProcessProvider, LedgerProvider>(
            builder: (context, invProvider, procProvider, ledgerProvider, child) {
              final availableDiamonds = invProvider.diamonds
                  .where((d) => d.status != 'sold')
                  .toList();
              final workers = ledgerProvider.parties
                  .where((party) => party.type == 'worker')
                  .toList();
              final selectedDiamondLabel = _selectedDiamondLabel(availableDiamonds);
              final selectedProcessTypeLabel = _selectedProcessTypeLabel(procProvider);
              final selectedWorkerLabel = _selectedWorkerLabel(workers);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border:
                        Border.all(color: AppTheme.borderSubtle, width: 1.2),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existing == null ? 'Add New Process' : 'Edit Process',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Diamond', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: availableDiamonds.isEmpty
                                  ? null
                                  : () => _openDiamondPicker(availableDiamonds),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                                child: Text(
                                  selectedDiamondLabel ??
                                      (availableDiamonds.isEmpty
                                          ? 'No available diamonds'
                                          : 'Search and select diamond'),
                                  style: TextStyle(
                                    color: selectedDiamondLabel == null
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
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
                            InkWell(
                              onTap: procProvider.processTypes.isEmpty
                                  ? null
                                  : () => _openProcessTypePicker(procProvider),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                                child: Text(
                                  selectedProcessTypeLabel ??
                                      (procProvider.processTypes.isEmpty
                                          ? 'No process types'
                                          : 'Search and select process type'),
                                  style: TextStyle(
                                    color: selectedProcessTypeLabel == null
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
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
                          child: InkWell(
                            onTap: workers.isEmpty ? null : () => _openWorkerPicker(workers),
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                suffixIcon: const Icon(Icons.search),
                              ),
                              child: Text(
                                selectedWorkerLabel ??
                                    (workers.isEmpty
                                        ? 'No workers found in parties'
                                        : 'Search and select worker'),
                                style: TextStyle(
                                  color: selectedWorkerLabel == null
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'From Date (yyyy-MM-dd)',
                          required: true,
                          child: TextFormField(
                            controller: _fromCtrl,
                            readOnly: true,
                            onTap: _pickFromDate,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'From date is required' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'To Date / Deadline (Optional)',
                          child: TextFormField(
                            controller: _toCtrl,
                            readOnly: true,
                            onTap: _pickToDate,
                            decoration: InputDecoration(
                              hintText: 'Select expected completion date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
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
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                              style: FilledButton.styleFrom(
                                backgroundColor: _brightActionYellow,
                                foregroundColor: const Color(0xFF1A1A1A),
                              ),
                              child: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


