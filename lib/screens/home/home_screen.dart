import 'package:flutter/material.dart';
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
import '../../core/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavSection _currentSection = NavSection.dashboard;

  Widget _buildContent() {
    switch (_currentSection) {
      case NavSection.dashboard:
        return const DashboardScreen();
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
      case NavSection.processTypes:
        return const ProcessTypesPage();
      case NavSection.expenseCategories:
        return const ExpenseCategoryPage();
      case NavSection.backupRestore:
        return const BackupRestorePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final collapsed = width < 1024;

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
    );
  }
}
