import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../models/payment.dart';
import '../../models/process.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/process_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/data_table_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _inventoryStats = {};
  Map<String, double> _ledgerStats = {};
  int _pendingProcesses = 0;
  int _completedProcesses = 0;
  int _inProcessDiamonds = 0;
  int _soldDiamonds = 0;
  int _salesCount = 0;
  double _pendingPaymentTotal = 0;
  List<Map<String, dynamic>> _stageBreakdown = [];
  List<Process> _recentActivity = [];
  List<Payment> _pendingPayments = [];
  List<Payment> _recentPayments = [];
  bool _loading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final inv = context.read<InventoryProvider>();
    final ledger = context.read<LedgerProvider>();
    final process = context.read<ProcessProvider>();

    try {
      final results = await Future.wait([
        inv.getDashboardStats(),            // 0
        ledger.getDashboardStats(),          // 1
        process.getPendingCount(),           // 2
        process.getCompletedCount(),         // 3
        process.getStageBreakdown(),         // 4
        process.getRecentActivity(10),       // 5
        ledger.getPendingPayments(),         // 6
        ledger.getRecentPayments(5),         // 7
      ]);

      if (!mounted) return;

      final invStats = results[0] as Map<String, dynamic>;
      final rawLedger = results[1] as Map<dynamic, dynamic>;
      final safeLedger = <String, double>{
        for (final entry in rawLedger.entries)
          entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0.0,
      };

      setState(() {
        _inventoryStats = invStats;
        _ledgerStats = safeLedger;
        _pendingProcesses = results[2] as int;
        _completedProcesses = results[3] as int;
        _stageBreakdown = List<Map<String, dynamic>>.from(results[4] as List);
        _recentActivity = List<Process>.from(results[5] as List);
        _pendingPayments = List<Payment>.from(results[6] as List);
        _recentPayments = List<Payment>.from(results[7] as List);
        _inProcessDiamonds = invStats['inProcessDiamonds'] as int? ?? 0;
        _soldDiamonds = invStats['soldDiamonds'] as int? ?? 0;
        _salesCount = (safeLedger['salesCount'] ?? 0).toInt();
        _pendingPaymentTotal = safeLedger['pendingPaymentTotal'] ?? 0;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load dashboard data right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _lastUpdated == null
        ? 'Awaiting first refresh'
        : 'Updated ${_formatRelativeTime(_lastUpdated!)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: PageHeader(
            title: 'Dashboard',
            subtitle: 'Executive overview of inventory, finance, and operations',
            statusText: _errorMessage == null ? statusText : 'Sync failed',
            statusIcon:
                _errorMessage == null ? Icons.verified_outlined : Icons.warning_amber_rounded,
            statusColor: _errorMessage == null ? AppTheme.textSecondary : AppTheme.danger,
            action: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh'),
              onPressed: _loadStats,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_errorMessage != null) return _buildErrorState();

    final roughCount = (_inventoryStats['roughCount'] ?? 0) as int;
    final diamondCount = (_inventoryStats['diamondCount'] ?? 0) as int;
    final roughWeight = (_inventoryStats['roughWeight'] as double? ?? 0.0);
    final diamondWeight = (_inventoryStats['diamondWeight'] as double? ?? 0.0);
    final revenue = _ledgerStats['totalRevenue'] ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1 - KPI strip
        const SizedBox(height: 24),
        _KpiRow(children: [
          _KpiCard(
            title: 'Rough Stones',
            value: '$roughCount',
            subtitle: '${roughWeight.toStringAsFixed(2)} ct available',
            icon: Icons.circle_outlined,
            color: AppTheme.kpiInventory,
          ),
          _KpiCard(
            title: 'Diamonds Created',
            value: '$diamondCount',
            subtitle: '${diamondWeight.toStringAsFixed(2)} ct total',
            icon: Icons.diamond_outlined,
            color: AppTheme.kpiDiamond,
          ),
          _KpiCard(
            title: 'In Process',
            value: '$_inProcessDiamonds',
            subtitle: '$_pendingProcesses active work order${_pendingProcesses == 1 ? '' : 's'}',
            icon: Icons.precision_manufacturing_rounded,
            color: AppTheme.kpiProcess,
          ),
          _KpiCard(
            title: 'Completed',
            value: '$_completedProcesses',
            subtitle: '$_soldDiamonds diamonds sold',
            icon: Icons.task_alt_rounded,
            color: AppTheme.success,
          ),
          _KpiCard(
            title: 'Pending Payments',
            value: AppHelpers.formatCurrency(_pendingPaymentTotal),
            subtitle: '${_pendingPayments.length} payment${_pendingPayments.length == 1 ? '' : 's'} outstanding',
            icon: Icons.account_balance_wallet_outlined,
            color: AppTheme.danger,
          ),
          _KpiCard(
            title: 'Total Sales',
            value: '$_salesCount',
            subtitle: '${AppHelpers.formatCurrency(revenue)} revenue',
            icon: Icons.sell_outlined,
            color: AppTheme.kpiRevenue,
          ),
        ]),
        const SizedBox(height: 24),
        // Section 2 - Pipeline and payments
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 860;
            if (narrow) {
              return Column(
                children: [
                  _ProcessPipelineSection(stageBreakdown: _stageBreakdown),
                  const SizedBox(height: 16),
                  _PaymentAlertPanel(
                    pendingTotal: _pendingPaymentTotal,
                    pendingPayments: _pendingPayments,
                    recentPayments: _recentPayments,
                  ),
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: _ProcessPipelineSection(stageBreakdown: _stageBreakdown),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _PaymentAlertPanel(
                      pendingTotal: _pendingPaymentTotal,
                      pendingPayments: _pendingPayments,
                      recentPayments: _recentPayments,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Section 3 - Recent activity
        _RecentActivityTable(processes: _recentActivity),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Unable to load dashboard data.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Check your data connection and refresh again.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: List.generate(6, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 5 ? 12 : 0),
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              padding: const EdgeInsets.all(14),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(height: 10, width: 70, shimmer: true),
                  SkeletonLoader(height: 22, width: 60, shimmer: true),
                  SkeletonLoader(height: 9, width: 100, shimmer: true),
                ],
              ),
            ),
          )),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              flex: 6,
              child: SkeletonLoader(height: 220, shimmer: true, borderRadius: 10),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: SkeletonLoader(height: 220, shimmer: true, borderRadius: 10),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonLoader(height: 280, shimmer: true, borderRadius: 10),
      ],
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============================================================================
// KPI ROW - responsive 6 / 3 / 2 / 1 column grid
// ============================================================================

class _KpiRow extends StatelessWidget {
  final List<Widget> children;
  const _KpiRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      int cols = 6;
      if (w < 600) {
        cols = 1;
      } else if (w < 800) {
        cols = 2;
      } else if (w < 1100) {
        cols = 3;
      }

      if (cols == 6) {
        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }

      final rows = <Widget>[];
      for (int i = 0; i < children.length; i += cols) {
        final chunk = children.skip(i).take(cols).toList();
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (int j = 0; j < chunk.length; j++) ...[
                  Expanded(child: chunk[j]),
                  if (j < chunk.length - 1) const SizedBox(width: 12),
                ],
                for (int j = chunk.length; j < cols; j++) ...[
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        );
      }
      return Column(children: rows);
    });
  }
}

// ============================================================================
// KPI CARD
// ============================================================================

class _KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()..translateByDouble(0.0, _hovered ? -2.0 : 0.0, 0.0, 1.0),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? widget.color.withValues(alpha: 0.3) : AppTheme.divider,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.color.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 6))]
              : AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, color: widget.color),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.value,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.color),
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

// ============================================================================
// PROCESS PIPELINE SECTION
// ============================================================================

class _ProcessPipelineSection extends StatelessWidget {
  final List<Map<String, dynamic>> stageBreakdown;
  const _ProcessPipelineSection({required this.stageBreakdown});

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'PRODUCTION PIPELINE',
      icon: Icons.precision_manufacturing_outlined,
      child: stageBreakdown.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: EmptyState(
                message: 'No active processes',
                icon: Icons.precision_manufacturing_outlined,
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stageBreakdown
                    .map((s) => _StageTile(
                          name: s['name'] as String,
                          count: s['count'] as int,
                        ))
                    .toList(),
              ),
            ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final String name;
  final int count;
  const _StageTile({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: const Border(top: BorderSide(color: AppTheme.kpiProcess, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAYMENT ALERT PANEL
// ============================================================================

class _PaymentAlertPanel extends StatelessWidget {
  final double pendingTotal;
  final List<Payment> pendingPayments;
  final List<Payment> recentPayments;

  const _PaymentAlertPanel({
    required this.pendingTotal,
    required this.pendingPayments,
    required this.recentPayments,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'PAYMENT ALERTS',
      icon: Icons.notifications_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${pendingPayments.length} pending - ${AppHelpers.formatCurrency(pendingTotal)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (pendingPayments.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...pendingPayments.take(4).map((p) => _PaymentRow(payment: p, isAlert: true)),
          ],
          if (recentPayments.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppTheme.divider, height: 1),
            ),
            Text(
              'RECENTLY COMPLETED',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ...recentPayments.map((p) => _PaymentRow(payment: p, isAlert: false)),
          ],
          if (pendingPayments.isEmpty && recentPayments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                message: 'No payment records',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final bool isAlert;
  const _PaymentRow({required this.payment, required this.isAlert});

  @override
  Widget build(BuildContext context) {
    final amtColor = isAlert ? AppTheme.danger : AppTheme.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.partyName ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppHelpers.displayDate(payment.date),
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            AppHelpers.formatCurrency(payment.amount),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: amtColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT ACTIVITY TABLE
// ============================================================================

class _RecentActivityTable extends StatelessWidget {
  final List<Process> processes;
  const _RecentActivityTable({required this.processes});

  static const _headers = ['Diamond Code', 'Process', 'Party', 'Date', 'Status'];

  @override
  Widget build(BuildContext context) {
    final recentProcesses = processes.take(10).toList();

    return _DashboardPanel(
      title: 'RECENT ACTIVITY',
      icon: Icons.history_rounded,
      child: recentProcesses.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: EmptyState(
                message: 'No process activity yet',
                icon: Icons.history_rounded,
              ),
            )
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: _headers
                        .map((h) => Expanded(
                              child: Text(
                                h,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(
                      'Showing latest 10 activities',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      itemCount: recentProcesses.length,
                      itemBuilder: (context, i) {
                        final p = recentProcesses[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: i.isOdd
                                ? AppTheme.surfaceSoft.withValues(alpha: 0.5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.diamondCode ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  p.processTypeName ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  p.partyName.isEmpty ? '-' : p.partyName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  AppHelpers.displayDate(p.fromDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: StatusChip(status: p.status),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// SHARED DASHBOARD PANEL CONTAINER
// ============================================================================

class _DashboardPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: AppTheme.divider, height: 16),
          child,
        ],
      ),
    );
  }
}