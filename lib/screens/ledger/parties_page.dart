import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../models/party.dart';
import '../../providers/ledger_provider.dart';
import '../../widgets/data_table_widget.dart';

class PartiesPage extends StatefulWidget {
  const PartiesPage({super.key});

  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  String _filterType = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDialog({Party? existing}) {
    showDialog(context: context, builder: (_) => _PartyDialog(existing: existing));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Parties',
            subtitle: 'Suppliers, customers and workers',
            action: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search parties',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _TypeFilter(
                  value: _filterType,
                  onChanged: (v) => setState(() => _filterType = v),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Party'),
                  onPressed: () => _showDialog(),
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

                final parties = provider.parties.where((p) {
                final matchesType =
                  _filterType == 'all' ? true : p.type == _filterType;
                if (!matchesType) return false;
                if (_searchQuery.isEmpty) return true;

                final name = p.name.toLowerCase();
                final phone = (p.phone ?? '').toLowerCase();
                final address = (p.address ?? '').toLowerCase();
                return name.contains(_searchQuery) ||
                  phone.contains(_searchQuery) ||
                  address.contains(_searchQuery);
                }).toList();

              if (parties.isEmpty) {
                return const EmptyState(
                  message: 'No parties found.',
                  icon: Icons.people,
                  ctaLabel: 'Add your first party',
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(provider.parties, parties),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(parties)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<Party> all, List<Party> filtered) {
    final suppliers = all.where((p) => p.type == 'supplier').length;
    final customers = all.where((p) => p.type == 'customer').length;
    final workers = all.where((p) => p.type == 'worker').length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.groups_outlined,
          label: 'Total Parties',
          value: filtered.length.toString(),
          color: AppTheme.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.local_shipping_outlined,
          label: 'Suppliers',
          value: suppliers.toString(),
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.person_outline,
          label: 'Customers',
          value: customers.toString(),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.engineering_outlined,
          label: 'Workers',
          value: workers.toString(),
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }

  Widget _buildTable(List<Party> parties) {
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
                  _hCell('Name', flex: 3),
                  _hCell('Type', flex: 2),
                  _hCell('Phone', flex: 2),
                  _hCell('Address', flex: 4),
                  _hCell('Actions', flex: 2),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: parties.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final party = parties[i];
                  return Container(
                    height: 52,
                    color: i.isEven ? Colors.white : const Color(0xFFFAFBFD),
                    child: Row(
                      children: [
                        _dCell(
                          flex: 3,
                          child: Text(
                            party.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: PartyTypeBadge(type: party.type),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            party.phone ?? '—',
                            style: GoogleFonts.inter(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 4,
                          child: Text(
                            party.address ?? '—',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _actionBtn(
                                icon: Icons.edit_outlined,
                                color: AppTheme.primary,
                                tooltip: 'Edit party',
                                onTap: () => _showDialog(existing: party),
                              ),
                              _actionBtn(
                                icon: Icons.delete_outline,
                                color: Colors.red.shade600,
                                tooltip: 'Delete party',
                                onTap: () async {
                                  final ok = await showDeleteConfirmDialog(
                                      context, party.name);
                                  if (ok && mounted) {
                                    await context
                                        .read<LedgerProvider>()
                                        .deleteParty(party.id!);
                                    if (mounted) {
                                      showSuccessSnack(context, 'Party deleted');
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

class _TypeFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(color: AppTheme.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (v) => onChanged(v!),
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Types')),
            DropdownMenuItem(value: 'supplier', child: Text('Suppliers')),
            DropdownMenuItem(value: 'customer', child: Text('Customers')),
            DropdownMenuItem(value: 'worker', child: Text('Workers')),
          ],
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

class _PartyDialog extends StatefulWidget {
  final Party? existing;
  const _PartyDialog({this.existing});

  @override
  State<_PartyDialog> createState() => _PartyDialogState();
}

class _PartyDialogState extends State<_PartyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _address;
  String _type = 'supplier';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _type = p?.type ?? 'supplier';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'customer':
        return 'Customer';
      case 'worker':
        return 'Worker';
      default:
        return 'Supplier';
    }
  }

  Future<void> _openTypePicker() async {
    const typeOptions = [
      ('supplier', 'Supplier'),
      ('customer', 'Customer'),
      ('worker', 'Worker'),
    ];

    final selectedType = await showDialog<String>(
      context: context,
      builder: (context) {
        final searchCtrl = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = typeOptions.where((option) {
              return option.$2.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Type'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search type',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No type matches your search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final option = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(option.$2),
                                  trailing: option.$1 == _type
                                      ? const Icon(Icons.check, size: 18)
                                      : null,
                                  onTap: () => Navigator.pop(context, option.$1),
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

    if (!mounted || selectedType == null) return;
    setState(() => _type = selectedType);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    final party = Party(
      id: widget.existing?.id,
      name: _name.text.trim(),
      type: _type,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now().toIso8601String(),
    );
    
    final provider = context.read<LedgerProvider>();
    final ok = widget.existing == null 
        ? await provider.addParty(party) 
        : await provider.updateParty(party);
    
    if (mounted) {
      Navigator.pop(context);
      if (ok) {
        showSuccessSnack(
          context, 
          widget.existing == null ? 'Party added' : 'Party updated'
        );
      } else {
        showErrorSnack(context, provider.error ?? 'Error saving party');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.existing == null ? 'Add Party' : 'Edit Party',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 24),
                AppFormField(
                  label: 'Name',
                  required: true,
                  child: TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(hintText: 'Enter party name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Type',
                  required: true,
                  child: InkWell(
                    onTap: _openTypePicker,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.search),
                      ),
                      child: Text(_typeLabel(_type)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Phone',
                  child: TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(hintText: 'Optional phone number'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Address',
                  child: TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(hintText: 'Optional address details'),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
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
