import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/purchase.dart';
import '../../models/rough_stone.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/rough_stone_dialog.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  ButtonStyle _brightActionButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brightActionYellow,
      foregroundColor: const Color(0xFF1A1A1A),
    );
  }

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Future<void> _openAddRoughStoneDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const RoughStoneDialog(),
    );
    if (added == true && mounted) {
      await context.read<InventoryProvider>().loadRoughStones();
      if (!mounted) return;
      await context.read<LedgerProvider>().loadAll();
    }
  }

  Future<void> _openEditRoughStoneDialog(RoughStone stone) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => RoughStoneDialog(existing: stone),
    );
    if (updated == true && mounted) {
      await context.read<InventoryProvider>().loadRoughStones();
      if (!mounted) return;
      await context.read<LedgerProvider>().loadAll();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
      context.read<InventoryProvider>().loadRoughStones();
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
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Purchases',
            subtitle: 'Linked purchases from rough stone entries',
            action: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search purchases',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Rough Stone'),
                  style: _brightActionButtonStyle(),
                  onPressed: _openAddRoughStoneDialog,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer2<LedgerProvider, InventoryProvider>(
            builder: (context, provider, inventoryProvider, _) {
              if (provider.loading || inventoryProvider.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: TableSkeleton(rows: 6),
                );
              }

              final titleByLotNo = <String, String>{
                for (final stone in inventoryProvider.roughStones)
                  stone.lotNo: stone.title,
              };

              final purchases = provider.purchases.where((purchase) {
                if (_searchQuery.isEmpty) return true;

                final lotNo = purchase.lotNo ?? '';
                final title = lotNo.isEmpty ? '' : (titleByLotNo[lotNo] ?? '');
                return (purchase.partyName ?? '').toLowerCase().contains(_searchQuery) ||
                    lotNo.toLowerCase().contains(_searchQuery) ||
                    title.toLowerCase().contains(_searchQuery) ||
                    purchase.date.toLowerCase().contains(_searchQuery) ||
                    (purchase.notes ?? '').toLowerCase().contains(_searchQuery) ||
                    purchase.amount.toString().contains(_searchQuery);
              }).toList();

              if (provider.purchases.isEmpty) {
                return EmptyState(
                  message: 'No purchases yet.',
                  icon: Icons.shopping_bag_outlined,
                  ctaLabel: 'Add Rough Stone',
                  onCta: _openAddRoughStoneDialog,
                );
              }

              if (purchases.isEmpty) {
                return const EmptyState(
                  message: 'No purchases match your search.',
                  icon: Icons.search_off_rounded,
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(purchases),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildTable(
                        purchases,
                        inventoryProvider.roughStones,
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
    );
  }

  Widget _buildStats(List<Purchase> purchases) {
    final totalAmount = purchases.fold<double>(0, (sum, p) => sum + p.amount);
    final linkedLots = purchases.where((p) => p.lotNo != null && p.lotNo!.isNotEmpty).length;
    final uniqueSuppliers = purchases
        .map((p) => p.partyName)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.shopping_bag_outlined,
          label: 'Total Purchases',
          value: purchases.length.toString(),
          color: AppTheme.accent,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.currency_rupee_outlined,
          label: 'Total Amount',
          value: AppHelpers.formatCurrency(totalAmount),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.local_shipping_outlined,
          label: 'Suppliers',
          value: uniqueSuppliers.toString(),
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.inventory_2_outlined,
          label: 'Linked Lots',
          value: linkedLots.toString(),
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }

  Widget _buildTable(List<Purchase> purchases, List<RoughStone> roughStones) {
    final titleByLotNo = <String, String>{};
    for (final stone in roughStones) {
      titleByLotNo[stone.lotNo] = stone.title;
    }

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
            Container(
              height: 52,
              color: Colors.black.withValues(alpha: 0.03),
              child: Row(
                children: [
                  _hCell('Party', flex: 3),
                  _hCell('Lot No', flex: 2),
                  _hCell('Title', flex: 3),
                  _hCell('Amount (Rs)', flex: 2),
                  _hCell('Date', flex: 2),
                  _hCell('Notes', flex: 3),
                  _hCell('Action', flex: 2),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: purchases.length,
                separatorBuilder: (_, index) =>
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                itemBuilder: (_, i) {
                  final p = purchases[i];
                  RoughStone? linkedStone;
                  if (p.lotNo != null && p.lotNo!.isNotEmpty) {
                    for (final stone in roughStones) {
                      if (stone.lotNo == p.lotNo) {
                        linkedStone = stone;
                        break;
                      }
                    }
                  }
                  final lotTitle = (p.lotNo == null || p.lotNo!.isEmpty)
                      ? '-'
                      : (titleByLotNo[p.lotNo!] ?? '-');
                  return Container(
                    height: 52,
                    color: i.isEven
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.015),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.lotNo ?? '-',
                              style: GoogleFonts.inter(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 3,
                          child: Text(
                            lotTitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
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
                          child: Text(
                            AppHelpers.displayDate(p.date),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        _dCell(
                          flex: 3,
                          child: Text(
                            p.notes ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Tooltip(
                            message: linkedStone == null
                                ? 'No linked rough stone to edit'
                                : 'Edit rough stone',
                            child: InkWell(
                              onTap: linkedStone == null
                                  ? null
                                  : () => _openEditRoughStoneDialog(linkedStone!),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: linkedStone == null
                                      ? AppTheme.textMuted
                                      : AppTheme.accent,
                                ),
                              ),
                            ),
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
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
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


