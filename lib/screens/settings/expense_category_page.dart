import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/ledger_provider.dart';
import '../../widgets/data_table_widget.dart';

class ExpenseCategoryPage extends StatefulWidget {
  const ExpenseCategoryPage({super.key});

  @override
  State<ExpenseCategoryPage> createState() => _ExpenseCategoryPageState();
}

class _ExpenseCategoryPageState extends State<ExpenseCategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadAll();
    });
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await context.read<LedgerProvider>().addExpenseCategory(ctrl.text.trim());
              if (mounted) showSuccessSnack(context, 'Expense category added');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Expense Categories',
            subtitle: 'Categorize your expenses',
            action: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              onPressed: _showAddDialog,
            ),
          ),
          Expanded(
            child: Consumer<LedgerProvider>(
              builder: (context, provider, _) {
                if (provider.expenseCategories.isEmpty) {
                  return const EmptyState(
                    message: 'No expense categories defined.',
                    icon: Icons.category_outlined,
                    ctaLabel: 'Add your first category',
                  );
                }

                return ListView.separated(
                  itemCount: provider.expenseCategories.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final cat = provider.expenseCategories[i];
                    return AppCard(
                      accentColor: AppTheme.accent,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.label_outline, color: AppTheme.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'For payment categorization',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: 'Delete category',
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.red,
                              onPressed: () async {
                                final ok = await showDeleteConfirmDialog(context, cat.name);
                                if (!context.mounted || !ok) {
                                  return;
                                }
                                await context.read<LedgerProvider>().deleteExpenseCategory(cat.id!);
                                if (context.mounted) showSuccessSnack(context, 'Category deleted');
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
