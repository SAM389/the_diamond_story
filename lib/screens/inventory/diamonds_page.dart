import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../models/diamond.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_table_widget.dart';

class DiamondsPage extends StatefulWidget {
  const DiamondsPage({super.key});

  @override
  State<DiamondsPage> createState() => _DiamondsPageState();
}

class _DiamondsPageState extends State<DiamondsPage> {
  String _filterStatus = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  void _showEditCodeDialog(Diamond diamond) {
    showDialog(
      context: context,
      builder: (_) => _EditDiamondCodeDialog(diamond: diamond),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        // ── Page Header ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Diamonds',
            subtitle: 'Inventory \u203a Diamonds',
            action: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search diamonds',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusFilter(
                  value: _filterStatus,
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
              ],
            ),
          ),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Consumer<InventoryProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: TableSkeleton(rows: 6),
                );
              }

              final diamonds = provider.diamonds.where((d) {
                final matchesStatus =
                    _filterStatus == 'all' ? true : d.status == _filterStatus;
                if (!matchesStatus) return false;
                if (_searchQuery.isEmpty) return true;

                return d.diamondCode.toLowerCase().contains(_searchQuery) ||
                    d.parentLot.toLowerCase().contains(_searchQuery) ||
                    d.status.toLowerCase().contains(_searchQuery) ||
                  (d.createdAt ?? '').toLowerCase().contains(_searchQuery) ||
                    d.weight.toString().contains(_searchQuery);
              }).toList();

              if (diamonds.isEmpty) {
                return const EmptyState(
                  message:
                      'No diamonds found.\nSplit a rough stone lot to create diamonds.',
                  icon: Icons.diamond_outlined,
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(provider.diamonds, diamonds),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(diamonds)),
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

  // ── Summary stat cards ────────────────────────────────────────────────────
  Widget _buildStats(List<Diamond> all, List<Diamond> filtered) {
    final totalWeight = filtered.fold<double>(0, (s, d) => s + d.weight);
    final rawCount = all.where((d) => d.status == 'raw').length;
    final inProcessCount = all.where((d) => d.status == 'in_process').length;
    final soldCount = all.where((d) => d.status == 'sold').length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.diamond_outlined,
          label: 'Total Diamonds',
          value: filtered.length.toString(),
          color: AppTheme.accent,
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
          icon: Icons.pending_outlined,
          label: 'Raw / In Process',
          value: '$rawCount / $inProcessCount',
          color: const Color(0xFFE65100),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.sell_outlined,
          label: 'Sold',
          value: soldCount.toString(),
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  // ── Full-width table ───────────────────────────────────────────────────────
  Widget _buildTable(List<Diamond> diamonds) {
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
            // Header row
            Container(
              height: 52,
              color: Colors.black.withValues(alpha: 0.03),
              child: Row(children: [
                _hCell('Diamond Code', flex: 3),
                _hCell('Parent Lot', flex: 2),
                _hCell('Weight (ct)', flex: 2),
                _hCell('Status', flex: 2),
                _hCell('Created', flex: 2),
                _hCell('Actions', flex: 2),
              ]),
            ),
            // Data rows
            Expanded(
              child: ListView.separated(
                itemCount: diamonds.length,
                separatorBuilder: (_, index) =>
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                itemBuilder: (_, i) {
                  final d = diamonds[i];
                  return Container(
                    height: 52,
                    color: i.isEven
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.015),
                    child: Row(children: [
                      _dCell(
                        flex: 3,
                        child: Row(children: [
                          const Icon(Icons.diamond,
                              size: 14, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          Text(d.diamondCode,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                  fontSize: 13)),
                        ]),
                      ),
                      _dCell(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(d.parentLot,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent)),
                        ),
                      ),
                      _dCell(
                        flex: 2,
                        child: Text(d.weight.toStringAsFixed(3),
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                      _dCell(
                        flex: 2,
                        child: _diamondStatusChip(d.status),
                      ),
                      _dCell(
                        flex: 2,
                        child: Text(
                            AppHelpers.displayDate(d.createdAt),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                      ),
                      _dCell(
                        flex: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Edit code',
                              child: InkWell(
                                onTap: () => _showEditCodeDialog(d),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Delete',
                              child: InkWell(
                                onTap: () async {
                                  final ok = await showDeleteConfirmDialog(
                                      context, d.diamondCode);
                                  if (ok && mounted) {
                                    final success = await context
                                        .read<InventoryProvider>()
                                        .deleteDiamond(d.id!);
                                    if (mounted) {
                                      if (success) {
                                        showSuccessSnack(
                                            context, 'Diamond deleted.');
                                      } else {
                                        showErrorSnack(context,
                                            'Failed to delete diamond.');
                                      }
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red.shade600),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _diamondStatusChip(String status) {
    final normalized = status.toLowerCase();
    final (bg, fg) = switch (normalized) {
      'raw' => (const Color(0xFFE2E8F0), const Color(0xFF475569)),
      'in_process' => (const Color(0xFFFFF4D6), const Color(0xFFB45309)),
      'completed' => (const Color(0xFFDDF8E8), const Color(0xFF166534)),
      'sold' => (const Color(0xFFDCEAFE), const Color(0xFF1D4ED8)),
      'pending' => (const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
      _ => (const Color(0xFFE2E8F0), const Color(0xFF475569)),
    };

    return StatusChip(
      status: normalized,
      backgroundColor: bg,
      textColor: fg,
    );
  }

  Widget _hCell(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text,
              style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
        ),
      );

  Widget _dCell({required int flex, required Widget child}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      );
}

// ── Status filter dropdown ────────────────────────────────────────────────────
class _StatusFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (v) => onChanged(v!),
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'raw', child: Text('Raw')),
            DropdownMenuItem(value: 'in_process', child: Text('In Process')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'sold', child: Text('Sold')),
          ],
        ),
      ),
    );
  }
}

// ── Stat card widget ──────────────────────────────────────────────────────────
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _EditDiamondCodeDialog extends StatefulWidget {
  final Diamond diamond;

  const _EditDiamondCodeDialog({required this.diamond});

  @override
  State<_EditDiamondCodeDialog> createState() => _EditDiamondCodeDialogState();
}

class _EditDiamondCodeDialogState extends State<_EditDiamondCodeDialog> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _suffixCtrl;
  bool _saving = false;

  String get _prefix => widget.diamond.parentLot;

  @override
  void initState() {
    super.initState();
    final currentCode = widget.diamond.diamondCode;
    final suffix = currentCode.startsWith(_prefix)
        ? currentCode.substring(_prefix.length)
        : currentCode;
    _suffixCtrl = TextEditingController(text: suffix);
  }

  @override
  void dispose() {
    _suffixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final suffix = _suffixCtrl.text.trim();
    final newCode = '$_prefix$suffix';

    setState(() => _saving = true);
    final provider = context.read<InventoryProvider>();
    final success = await provider.updateDiamond(
      widget.diamond.copyWith(diamondCode: newCode),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pop(context);
      showSuccessSnack(context, 'Diamond code updated to $newCode');
      return;
    }

    setState(() => _saving = false);
    showErrorSnack(context, provider.error ?? 'Failed to update code.');
  }

  @override
  Widget build(BuildContext context) {
    final preview = '$_prefix${_suffixCtrl.text.trim()}';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Diamond Code',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Prefix (locked): $_prefix',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _suffixCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Code suffix',
                    hintText: 'A or Name',
                    helperText: 'Final code example: LOT-001A or LOT-001Name',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return 'Suffix is required';
                    }
                    final ok = RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text);
                    if (!ok) {
                      return 'Use only letters, numbers, _ or -';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Preview: $preview',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A1A1A),
                              ),
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
    );
  }
}


