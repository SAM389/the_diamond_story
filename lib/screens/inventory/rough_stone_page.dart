import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../models/rough_stone.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/rough_stone_dialog.dart';

class RoughStonePage extends StatefulWidget {
  const RoughStonePage({super.key});

  @override
  State<RoughStonePage> createState() => _RoughStonePageState();
}

class _RoughStonePageState extends State<RoughStonePage> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  ButtonStyle _brightActionButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brightActionYellow,
      foregroundColor: const Color(0xFF1A1A1A),
    );
  }

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadRoughStones();
      context.read<InventoryProvider>().loadDiamonds();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog({RoughStone? existing}) {
    showDialog<bool>(
      context: context,
      builder: (_) => RoughStoneDialog(existing: existing),
    );
  }

  void _showSplitDialog(RoughStone stone) {
    showDialog(context: context, builder: (_) => _SplitLotDialog(stone: stone));
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
        // -- Page Header ---------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Rough Stones',
            subtitle: 'Inventory \u203a Rough Stones',
            action: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search rough stones',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rough Stone'),
                  style: _brightActionButtonStyle(),
                  onPressed: () => _showAddDialog(),
                ),
              ],
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

              final filteredStones = provider.roughStones.where((stone) {
                if (_searchQuery.isEmpty) return true;

                return stone.lotNo.toLowerCase().contains(_searchQuery) ||
                    stone.title.toLowerCase().contains(_searchQuery) ||
                    stone.quality.toLowerCase().contains(_searchQuery) ||
                    stone.purchaseDate.toLowerCase().contains(_searchQuery) ||
                    stone.weight.toString().contains(_searchQuery) ||
                    stone.purchasePrice.toString().contains(_searchQuery);
              }).toList();

              if (provider.roughStones.isEmpty) {
                return EmptyState(
                  message: 'No rough stones yet.\nClick "Add Rough Stone" to get started.',
                  icon: Icons.circle_outlined,
                  ctaLabel: 'Add Rough Stone',
                  onCta: () => _showAddDialog(),
                );
              }

              if (filteredStones.isEmpty) {
                return const EmptyState(
                  message: 'No rough stones match your search.',
                  icon: Icons.search_off_rounded,
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(filteredStones),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(filteredStones)),
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
                    Divider(height: 1, color: AppTheme.borderSubtle),
                itemBuilder: (_, i) {
                  final s = stones[i];
                  final alreadySplit = splitLots.contains(s.lotNo);
                  return Container(
                    height: 52,
                    color: i.isEven
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.015),
                    child: Row(children: [
                      _dCell(
                        flex: 2,
                        child: Text(s.lotNo,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
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
                            color: AppTheme.accent,
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
                color: AppTheme.accent)),
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

class _SplitLotDialog extends StatefulWidget {
  final RoughStone stone;
  const _SplitLotDialog({required this.stone});

  @override
  State<_SplitLotDialog> createState() => _SplitLotDialogState();
}

class _SplitLotDialogState extends State<_SplitLotDialog> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

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
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('Will create: ${codes.join(', ')}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accent)));
                },
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _splitting ? null : _split,
                  style: FilledButton.styleFrom(
                    backgroundColor: _brightActionYellow,
                    foregroundColor: const Color(0xFF1A1A1A),
                  ),
                  child: _splitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        )
                      : const Text('Split Lot'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}


