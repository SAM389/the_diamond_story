import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/sidebar.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/rough_stone_page.dart';
import '../inventory/diamonds_page.dart';
import '../process/process_list_page.dart';
import '../ledger/parties_page.dart';
import '../ledger/purchase_page.dart';
import 'package:the_diamond_story/screens/ledger/sales_page.dart';
import '../ledger/payments_page.dart';
import '../settings/process_types_page.dart';
import '../settings/expense_category_page.dart';
import '../settings/backup_restore_page.dart';
import '../settings/settings_page.dart';
import '../settings/about_us_page.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/process_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavSection _currentSection = NavSection.dashboard;
  final TextEditingController _globalSearchCtrl = TextEditingController();
  String _globalQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadAll();
      context.read<LedgerProvider>().loadAll();
      context.read<ProcessProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _globalSearchCtrl.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    switch (_currentSection) {
      case NavSection.dashboard:
        return DashboardScreen(
          onNavigateToSettings: () => setState(() => _currentSection = NavSection.settings),
        );
      case NavSection.roughStones:
        return const RoughStonePage();
      case NavSection.diamonds:
        return const DiamondsPage();
      case NavSection.processes:
        return const ProcessListPage();
      case NavSection.parties:
        return const PartiesPage();
      case NavSection.purchases:
        return const PurchasePage();
      case NavSection.sales:
        return const SalesPage();
      case NavSection.payments:
        return const PaymentsPage();
      case NavSection.settings:
        return const SettingsPage();
      case NavSection.processTypes:
        return const ProcessTypesPage();
      case NavSection.expenseCategories:
        return const ExpenseCategoryPage();
      case NavSection.backupRestore:
        return const BackupRestorePage();
      case NavSection.about:
        return const AboutUsPage();
    }
  }

  List<_GlobalSearchHit> _buildGlobalHits({
    required InventoryProvider inventory,
    required LedgerProvider ledger,
    required ProcessProvider process,
  }) {
    final q = _globalQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];

    bool matches(String value) => value.toLowerCase().contains(q);
    final hits = <_GlobalSearchHit>[];

    for (final stone in inventory.roughStones) {
      final searchable = [
        stone.lotNo,
        stone.title,
        stone.quality,
        stone.purchaseDate,
        stone.purchasePrice.toString(),
      ];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.roughStones,
            icon: Icons.circle_outlined,
            type: 'Rough Stone',
            title: stone.lotNo,
            subtitle: '${stone.title} � ${stone.quality} � ${stone.purchaseDate}',
          ),
        );
      }
    }

    for (final diamond in inventory.diamonds) {
      final searchable = [
        diamond.diamondCode,
        diamond.parentLot,
        diamond.status,
        diamond.weight.toString(),
      ];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.diamonds,
            icon: Icons.diamond_outlined,
            type: 'Diamond',
            title: diamond.diamondCode,
            subtitle: '${diamond.parentLot} � ${diamond.status} � ${diamond.weight} ct',
          ),
        );
      }
    }

    for (final party in ledger.parties) {
      final searchable = [party.name, party.type, party.phone ?? '', party.address ?? ''];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.parties,
            icon: Icons.people_alt_outlined,
            type: 'Party',
            title: party.name,
            subtitle: '${party.type} � ${party.phone ?? 'No phone'}',
          ),
        );
      }
    }

    for (final row in ledger.purchases) {
      final searchable = [
        row.partyName ?? '',
        row.lotNo ?? '',
        row.date,
        row.notes ?? '',
        row.amount.toString(),
      ];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.purchases,
            icon: Icons.shopping_bag_outlined,
            type: 'Purchase',
            title: row.partyName ?? 'Unknown party',
            subtitle: '${row.lotNo ?? '-'} � ${row.date} � Rs ${row.amount.toStringAsFixed(2)}',
          ),
        );
      }
    }

    for (final row in ledger.sales) {
      final searchable = [
        row.partyName ?? '',
        row.diamondCode ?? '',
        row.date,
        row.notes ?? '',
        row.price.toString(),
      ];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.sales,
            icon: Icons.sell_outlined,
            type: 'Sale',
            title: row.partyName ?? 'Unknown customer',
            subtitle: '${row.diamondCode ?? 'No diamond'} � ${row.date} � Rs ${row.price.toStringAsFixed(2)}',
          ),
        );
      }
    }

    for (final row in ledger.payments) {
      final searchable = [
        row.partyName ?? '',
        row.type,
        row.status,
        row.category ?? '',
        row.date,
        row.notes ?? '',
        row.amount.toString(),
      ];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.payments,
            icon: Icons.account_balance_wallet_outlined,
            type: 'Payment',
            title: row.partyName ?? 'Unknown party',
            subtitle:
                '${row.type} � ${row.status} � ${row.date} � Rs ${row.amount.toStringAsFixed(2)}',
          ),
        );
      }
    }

    for (final row in process.processes) {
      final searchable = [
        row.diamondCode ?? '',
        row.processTypeName ?? '',
        row.partyName,
        row.status,
        row.fromDate,
        row.toDate ?? '',
        row.fee.toString(),
      ];
      if (searchable.any(matches)) {
        hits.add(
          _GlobalSearchHit(
            section: NavSection.processes,
            icon: Icons.precision_manufacturing_rounded,
            type: 'Process',
            title: '${row.processTypeName ?? 'Process'} � ${row.diamondCode ?? '-'}',
            subtitle: '${row.partyName} � ${row.status} � ${row.fromDate}',
          ),
        );
      }
    }

    return hits.take(60).toList();
  }

  void _selectGlobalHit(_GlobalSearchHit hit) {
    setState(() {
      _currentSection = hit.section;
      _globalQuery = '';
      _globalSearchCtrl.clear();
    });
  }

  Widget _buildGlobalSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: TextField(
        controller: _globalSearchCtrl,
        onChanged: (value) => setState(() => _globalQuery = value),
        decoration: InputDecoration(
          hintText: 'Search all modules: lots, diamonds, parties, processes, sales, payments...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _globalQuery.trim().isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _globalQuery = '';
                      _globalSearchCtrl.clear();
                    });
                  },
                ),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildGlobalSearchResults(List<_GlobalSearchHit> hits) {
    if (_globalQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
      ),
      child: hits.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'No results found across modules.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: hits.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppTheme.borderSubtle,
                ),
                itemBuilder: (_, index) {
                  final hit = hits[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(hit.icon, size: 18, color: AppTheme.accent),
                    title: Text(
                      hit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${hit.type} � ${hit.subtitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    onTap: () => _selectGlobalHit(hit),
                  );
                },
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final collapsed = width < 1024;
    final inventory = context.watch<InventoryProvider>();
    final ledger = context.watch<LedgerProvider>();
    final process = context.watch<ProcessProvider>();
    final hits = _buildGlobalHits(
      inventory: inventory,
      ledger: ledger,
      process: process,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          AppSidebar(
            selected: _currentSection,
            onSelect: (section) => setState(() => _currentSection = section),
            collapsed: collapsed,
          ),
          Expanded(
            child: Column(
              children: [
                _buildGlobalSearchBar(),
                _buildGlobalSearchResults(hits),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_currentSection),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSearchHit {
  final NavSection section;
  final IconData icon;
  final String type;
  final String title;
  final String subtitle;

  const _GlobalSearchHit({
    required this.section,
    required this.icon,
    required this.type,
    required this.title,
    required this.subtitle,
  });
}


