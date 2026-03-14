import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/process.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/process_provider.dart';
import '../../widgets/data_table_widget.dart';
import 'add_process_page.dart';

class ProcessListPage extends StatefulWidget {
  const ProcessListPage({super.key});

  @override
  State<ProcessListPage> createState() => _ProcessListPageState();
}

class _ProcessListPageState extends State<ProcessListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcessProvider>().loadAll();
      context.read<InventoryProvider>().loadDiamonds();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCompleteDialog(Process process) async {
    final processProvider = context.read<ProcessProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final dateCtrl = TextEditingController(text: AppHelpers.today());
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Process'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mark "${process.processTypeName}" for ${process.diamondCode} as completed?',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final selected = await showDatePicker(
                    context: ctx,
                    initialDate: AppHelpers.parseDate(dateCtrl.text),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null) {
                    dateCtrl.text = AppHelpers.formatDate(selected);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Completion Date (yyyy-MM-dd)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      await processProvider.completeProcess(process.id!, dateCtrl.text.trim());
      if (!mounted) {
        dateCtrl.dispose();
        return;
      }
      inventoryProvider.loadDiamonds();
      showSuccessSnack(context, 'Process completed');
    }
    dateCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Processes',
            subtitle: 'Track diamond manufacturing processes',
            action: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search processes',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Process'),
                  onPressed: () async {
                    final added = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const AddProcessPage()),
                    );
                    if (!mounted) {
                      return;
                    }
                    this.context.read<ProcessProvider>().loadAll();
                    if (added == true) {
                      showSuccessSnack(this.context, 'Process added');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<ProcessProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: TableSkeleton(rows: 6),
                );
              }

              final processes = provider.processes.where((process) {
                if (_searchQuery.isEmpty) return true;

                return (process.diamondCode ?? '').toLowerCase().contains(_searchQuery) ||
                    (process.processTypeName ?? '').toLowerCase().contains(_searchQuery) ||
                    process.partyName.toLowerCase().contains(_searchQuery) ||
                    process.status.toLowerCase().contains(_searchQuery) ||
                    process.fromDate.toLowerCase().contains(_searchQuery) ||
                    (process.toDate ?? '').toLowerCase().contains(_searchQuery) ||
                    process.fee.toString().contains(_searchQuery);
              }).toList();

              if (provider.processes.isEmpty) {
                return const EmptyState(
                  message:
                      'No processes yet.\nAdd a process to start tracking diamond work.',
                  icon: Icons.precision_manufacturing,
                  ctaLabel: 'Start your first process',
                );
              }

              if (processes.isEmpty) {
                return const EmptyState(
                  message: 'No processes match your search.',
                  icon: Icons.search_off_rounded,
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStats(processes),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTable(processes)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<Process> processes) {
    final pending = processes.where((p) => p.status == 'pending').length;
    final completed = processes.where((p) => p.status == 'completed').length;
    final totalFees = processes.fold<double>(0, (sum, p) => sum + p.fee);

    return Row(
      children: [
        _StatCard(
          icon: Icons.precision_manufacturing_outlined,
          label: 'Total Processes',
          value: processes.length.toString(),
          color: AppTheme.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.timelapse_outlined,
          label: 'Pending',
          value: pending.toString(),
          color: const Color(0xFFE65100),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: completed.toString(),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.currency_rupee_outlined,
          label: 'Process Cost',
          value: AppHelpers.formatCurrency(totalFees),
          color: const Color(0xFF5E35B1),
        ),
      ],
    );
  }

  Widget _buildTable(List<Process> processes) {
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
                  _hCell('Diamond', flex: 2),
                  _hCell('Process', flex: 2),
                  _hCell('Worker', flex: 2),
                  _hCell('Fee', flex: 2),
                  _hCell('From', flex: 2),
                  _hCell('To', flex: 2),
                  _hCell('Status', flex: 2),
                  _hCell('Actions', flex: 2),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: processes.length,
                separatorBuilder: (_, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final p = processes[i];
                  return Container(
                    height: 52,
                    color: i.isEven ? Colors.white : const Color(0xFFFAFBFD),
                    child: Row(
                      children: [
                        _dCell(
                          flex: 2,
                          child: Text(
                            p.diamondCode ?? '',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            p.processTypeName ?? '',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            p.partyName,
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.formatCurrency(p.fee),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.displayDate(p.fromDate),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: Text(
                            AppHelpers.displayDate(p.toDate),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        _dCell(
                          flex: 2,
                          child: StatusChip(status: p.status),
                        ),
                        _dCell(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.status == 'pending')
                                _actionBtn(
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green.shade700,
                                  tooltip: 'Complete process',
                                  onTap: () => _showCompleteDialog(p),
                                ),
                              _actionBtn(
                                icon: Icons.edit_outlined,
                                color: AppTheme.primary,
                                tooltip: 'Edit process',
                                onTap: () async {
                                  final updated = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddProcessPage(existing: p),
                                    ),
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  context.read<ProcessProvider>().loadAll();
                                  if (updated == true) {
                                    showSuccessSnack(context, 'Process updated');
                                  }
                                },
                              ),
                              _actionBtn(
                                icon: Icons.delete_outline,
                                color: Colors.red.shade600,
                                tooltip: 'Delete process',
                                onTap: () async {
                                  final processProvider = context.read<ProcessProvider>();
                                  final ok = await showDeleteConfirmDialog(
                                      context, 'process for ${p.diamondCode}');
                                  if (!mounted || !ok) {
                                    return;
                                  }
                                  await processProvider.deleteProcess(p.id!);
                                  if (mounted) {
                                    showSuccessSnack(context, 'Process deleted');
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
