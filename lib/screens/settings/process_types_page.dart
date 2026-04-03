import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/process_provider.dart';
import '../../widgets/data_table_widget.dart';

class ProcessTypesPage extends StatefulWidget {
  const ProcessTypesPage({super.key});

  @override
  State<ProcessTypesPage> createState() => _ProcessTypesPageState();
}

class _ProcessTypesPageState extends State<ProcessTypesPage> {
  static const Color _brightActionYellow = Color.fromARGB(255, 239, 218, 24);

  ButtonStyle _brightActionButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brightActionYellow,
      foregroundColor: const Color(0xFF1A1A1A),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcessProvider>().loadProcessTypes();
    });
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Process Type'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Process Name *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: _brightActionButtonStyle(),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await context.read<ProcessProvider>().addProcessType(ctrl.text.trim());
              if (mounted) showSuccessSnack(context, 'Process type added');
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
            title: 'Process Types',
            subtitle: 'Define manufacturing process types',
            action: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Type'),
              style: _brightActionButtonStyle(),
              onPressed: _showAddDialog,
            ),
          ),
          Expanded(
            child: Consumer<ProcessProvider>(
              builder: (context, provider, _) {
                if (provider.processTypes.isEmpty) {
                  return const EmptyState(
                    message: 'No process types defined.',
                    icon: Icons.settings_applications,
                    ctaLabel: 'Add your first process type',
                  );
                }

                return ListView.separated(
                  itemCount: provider.processTypes.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final type = provider.processTypes[i];
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
                            child: const Icon(Icons.precision_manufacturing, color: AppTheme.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: 'Delete process type',
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.red,
                              onPressed: () async {
                                final ok = await showDeleteConfirmDialog(context, type.name);
                                if (!context.mounted || !ok) {
                                  return;
                                }
                                await context.read<ProcessProvider>().deleteProcessType(type.id!);
                                if (context.mounted) showSuccessSnack(context, 'Process type deleted');
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

