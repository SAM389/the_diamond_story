import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../models/payment.dart';
import '../../models/process.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/process_provider.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/donut_chart.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSettings;

  const DashboardScreen({super.key, this.onNavigateToSettings});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _inventoryStats = {};
  Map<String, double> _ledgerStats = {};
  int _pendingProcesses = 0;
  List<Map<String, dynamic>> _stageBreakdown = [];
  List<Process> _recentActivity = [];
  List<Payment> _recentPayments = [];
  List<Process> _overdueProcesses = [];
  List<Map<String, dynamic>> _monthlySales = [];
  double _pendingPaymentTotal = 0;
  double _totalProcessFees = 0;

  bool _loading = true;
  bool _lightMode = true;
  bool _revealed = false;

  final _overdueTableKey = GlobalKey();
  final _scrollController = ScrollController();
  int _monthRange = 6;

  int _sortColumn = 0;
  bool _sortAscending = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _revealed = false;
    });

    final inv = context.read<InventoryProvider>();
    final ledger = context.read<LedgerProvider>();
    final process = context.read<ProcessProvider>();

    try {
      final results = await Future.wait([
        inv.getDashboardStats(),
        ledger.getDashboardStats(),
        process.getPendingCount(),
        process.getStageBreakdown(),
        process.getRecentActivity(10),
        ledger.getRecentPayments(10),
        process.getOverdueProcesses(),
        ledger.getPendingPayments(),
        process.getTotalProcessFees(),
        ledger.getMonthlySales(_monthRange),
      ]);

      if (!mounted) return;

      final rawLedger = results[1] as Map<dynamic, dynamic>;
      final safeLedger = <String, double>{
        for (final entry in rawLedger.entries)
          entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0.0,
      };

      final pendingList = results[7] as List<Payment>;
      double pendingTotal = 0;
      for (final p in pendingList) {
        pendingTotal += p.amount;
      }

      setState(() {
        _inventoryStats = results[0] as Map<String, dynamic>;
        _ledgerStats = safeLedger;
        _pendingProcesses = results[2] as int;
        _stageBreakdown = List<Map<String, dynamic>>.from(results[3] as List);
        _recentActivity = List<Process>.from(results[4] as List);
        _recentPayments = List<Payment>.from(results[5] as List);
        _overdueProcesses = List<Process>.from(results[6] as List);
        _pendingPaymentTotal = pendingTotal;
        _totalProcessFees = (results[8] as num).toDouble();
        _monthlySales =
            List<Map<String, dynamic>>.from(results[9] as List<dynamic>);
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _revealed = true);
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
    final palette = _Palette.light();

    if (_loading) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: CircularProgressIndicator(color: palette.accent)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Text(
            _errorMessage!,
            style: GoogleFonts.dmSans(color: palette.textPrimary, fontSize: 14),
          ),
        ),
      );
    }

    final roughCount = (_inventoryStats['roughCount'] ?? 0) as int;
    final rawDiamonds = (_inventoryStats['rawDiamonds'] ?? 0) as int;
    final inProcess = (_inventoryStats['inProcessDiamonds'] ?? 0) as int;
    final readyToSell = (_inventoryStats['completedDiamonds'] ?? 0) as int;
    final sold = (_inventoryStats['soldDiamonds'] ?? 0) as int;
    final roughWeight = (_inventoryStats['roughWeight'] as double? ?? 0.0);
    final diamondWeight = (_inventoryStats['diamondWeight'] as double? ?? 0.0);

    final totalRevenue = _ledgerStats['totalRevenue'] ?? 0.0;
    final totalPurchases = _ledgerStats['totalPurchases'] ?? 0.0;
    final totalPaid = _ledgerStats['totalPaid'] ?? 0.0;
    final trueProfit = totalRevenue - totalPurchases - _totalProcessFees - totalPaid;

    final financialSegments = [
      DonutSegment(label: 'Sales', value: totalRevenue, color: palette.chartRevenue),
      DonutSegment(label: 'Rough Purchase', value: totalPurchases, color: palette.chartPurchase),
      DonutSegment(label: 'Process Cost', value: _totalProcessFees, color: palette.chartProcess),
      DonutSegment(label: 'Payments Out', value: totalPaid, color: palette.chartPayment),
    ];

    final monthlyPoints = _buildMonthSeries(_monthRange, _monthlySales);

    return Scaffold(
      backgroundColor: palette.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.background, palette.backgroundAlt, palette.background],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            children: [
              _buildReveal(
                0,
                _buildHeader(palette),
              ),
              const SizedBox(height: 14),
              _buildReveal(
                1,
                _buildProfitHero(palette, trueProfit, totalRevenue, totalPurchases, totalPaid),
              ),
              const SizedBox(height: 16),
              _buildReveal(
                2,
                _buildKpiGrid(palette, totalRevenue, totalPurchases),
              ),
              const SizedBox(height: 16),
              _buildReveal(
                3,
                _buildLifecycleGrid(
                  palette,
                  roughCount: roughCount,
                  rawDiamonds: rawDiamonds,
                  inProcess: inProcess,
                  readyToSell: readyToSell,
                  sold: sold,
                  roughWeight: roughWeight,
                  diamondWeight: diamondWeight,
                ),
              ),

              const SizedBox(height: 16),
              _buildReveal(
                5,
                _buildResponsiveColumns(
                  left: _buildCard(
                    palette,
                    title: 'Financial Breakdown',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chartSize =
                            (constraints.maxHeight - 80).clamp(160.0, 230.0).toDouble();
                        return SingleChildScrollView(
                          child: DonutChart(
                            segments: financialSegments,
                            size: chartSize,
                            centerLabel: 'Net Profit',
                            centerValue: AppHelpers.formatCurrency(trueProfit),
                            centerLabelStyle: GoogleFonts.dmSans(
                              color: palette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            centerValueStyle: GoogleFonts.jetBrainsMono(
                              color: trueProfit >= 0
                                  ? palette.positive
                                  : palette.negative,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  right: _buildCard(
                    palette,
                    title: 'Revenue Trend (${_monthRange} Months)',
                    child: _MonthlyAreaChart(
                      points: monthlyPoints,
                      lineColor: palette.chartRevenue,
                      fillColor: palette.chartRevenue.withValues(alpha: 0.18),
                      textColor: palette.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildReveal(
                6,
                _buildResponsiveColumns(
                  left: _buildCard(
                    palette,
                    title: 'Cost Comparison',
                    child: _CostBarChart(
                      bars: [
                        _BarValue('Purchases', totalPurchases, palette.chartPurchase),
                        _BarValue('Process', _totalProcessFees, palette.chartProcess),
                        _BarValue('Payments', totalPaid, palette.chartPayment),
                      ],
                      textColor: palette.textSecondary,
                    ),
                  ),
                  right: _buildCard(
                    palette,
                    title: 'Process Stage Breakdown',
                    child: _buildStageBreakdownLines(palette),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildReveal(
                7,
                _buildResponsiveColumns(
                  left: _buildCard(
                    palette,
                    title: 'Recent Activity',
                    child: _buildRecentActivityTable(palette),
                  ),
                  right: _buildCard(
                    palette,
                    title: 'Recent Transactions',
                    child: _buildTransactionsList(palette),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildReveal(
                8,
                SizedBox(
                  key: _overdueTableKey,
                  child: _buildCard(
                    palette,
                    title: 'Overdue Process Table',
                    expandChild: false,
                    child: _buildOverdueSortableTable(palette),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildReveal(
                9,
                _buildCard(
                  palette,
                  title: 'Diamond Pipeline',
                  expandChild: false,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _buildPipelineElements(palette)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_Palette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diamond Intelligence Deck',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Profit, lifecycle and overdue risk at a glance',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _monthRange,
              iconEnabledColor: palette.textSecondary,
              borderRadius: BorderRadius.circular(18),
              dropdownColor: palette.surface,
              style: GoogleFonts.dmSans(color: palette.textPrimary),
              items: const [3, 6, 12]
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text('Last $m months'),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null || value == _monthRange) return;
                setState(() => _monthRange = value);
                await _loadStats();
              },
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              final ctx = _overdueTableKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  alignment: 0.1,
                );
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(Icons.notifications_none_rounded, color: palette.textSecondary),
                ),
                if (_overdueProcesses.isNotEmpty)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: palette.negative,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${math.min(_overdueProcesses.length, 9)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onNavigateToSettings,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [palette.accent.withValues(alpha: 0.95), palette.chartRevenue],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'DS',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitHero(
    _Palette palette,
    double profit,
    double revenue,
    double purchases,
    double paid,
  ) {
    final positive = profit >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: positive
              ? [palette.surface, palette.surfaceAlt]
              : [palette.surface, palette.negative.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: positive
              ? palette.positive.withValues(alpha: 0.40)
              : palette.negative.withValues(alpha: 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: (positive ? palette.positive : palette.negative).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'True Profit',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: profit,
            formatter: AppHelpers.formatCurrency,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: positive ? palette.positive : palette.negative,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Revenue - Purchases - Process Cost - Payments Out',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: palette.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _miniInfo(palette, 'Sales', revenue, palette.chartRevenue),
              _miniInfo(palette, 'Rough Stones', purchases, palette.chartPurchase),
              _miniInfo(palette, 'Process', _totalProcessFees, palette.chartProcess),
              _miniInfo(palette, 'Payments', paid, palette.chartPayment),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(_Palette palette, String label, double value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(width: 7),
          Text(
            '$label: ${AppHelpers.formatCurrency(value)}',
            style: GoogleFonts.dmSans(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(_Palette palette, double totalRevenue, double totalPurchases) {
    return _buildGrid(
      maxColumns: 4,
      mobileHeight: 124,
      children: [
        _metricCard(
          palette,
          icon: Icons.payments_rounded,
          label: 'Revenue',
          value: totalRevenue,
          color: palette.chartRevenue,
          subtitle: 'Total sales income',
        ),
        _metricCard(
          palette,
          icon: Icons.inventory_2_rounded,
          label: 'Purchase Cost',
          value: totalPurchases,
          color: palette.chartPurchase,
          subtitle: 'Rough stone acquisition',
        ),
        _metricCard(
          palette,
          icon: Icons.precision_manufacturing_rounded,
          label: 'Process Cost',
          value: _totalProcessFees,
          color: palette.chartProcess,
          subtitle: 'Labor + process fees',
        ),
        _metricCard(
          palette,
          icon: Icons.receipt_long_rounded,
          label: 'Pending Payments',
          value: _pendingPaymentTotal,
          color: palette.chartPayment,
          subtitle: '${_pendingProcesses} active pending processes',
        ),
      ],
    );
  }

  Widget _buildLifecycleGrid(
    _Palette palette, {
    required int roughCount,
    required int rawDiamonds,
    required int inProcess,
    required int readyToSell,
    required int sold,
    required double roughWeight,
    required double diamondWeight,
  }) {
    return _buildGrid(
      maxColumns: 4,
      mobileHeight: 108,
      children: [
        _countCard(
          palette,
          title: 'Rough Stones',
          count: roughCount,
          subtitle: AppHelpers.formatWeight(roughWeight),
          color: const Color(0xFF7A8799),
          icon: Icons.circle_outlined,
        ),
        _countCard(
          palette,
          title: 'Under Process',
          count: inProcess,
          subtitle: '$rawDiamonds raw diamonds remaining',
          color: const Color(0xFFF59E0B),
          icon: Icons.autorenew_rounded,
        ),
        _countCard(
          palette,
          title: 'Ready To Sell',
          count: readyToSell,
          subtitle: AppHelpers.formatWeight(diamondWeight),
          color: const Color(0xFF10B981),
          icon: Icons.verified_rounded,
        ),
        _countCard(
          palette,
          title: 'Sold',
          count: sold,
          subtitle: 'Processed stones sold',
          color: const Color(0xFF3B82F6),
          icon: Icons.local_shipping_rounded,
        ),
      ],
    );
  }

  Widget _buildStageBreakdownLines(_Palette palette) {
    int total = _stageBreakdown.fold(0, (sum, item) => sum + (item['count'] as int));
    if (total == 0) total = 1;

    return Column(
      children: _stageBreakdown.map((s) {
        final count = s['count'] as int;
        final pct = count / total;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  s['name'] as String,
                  style: GoogleFonts.dmSans(fontSize: 12, color: palette.textSecondary),
                ),
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette.border.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.chartProcess,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(
                  '$count',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivityTable(_Palette palette) {
    return Column(
      children: [
        _buildTableHeader(palette, const ['Code', 'Process', 'Party', 'Status']),
        ..._recentActivity.take(6).map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.diamondCode ?? '-',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p.processTypeName ?? '-',
                        style: GoogleFonts.dmSans(fontSize: 12, color: palette.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p.partyName.isEmpty ? '-' : p.partyName,
                        style: GoogleFonts.dmSans(fontSize: 12, color: palette.textSecondary),
                      ),
                    ),
                    Expanded(child: _buildStatusBadge(palette, p.status)),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildTransactionsList(_Palette palette) {
    return Column(
      children: _recentPayments.take(6).map((p) {
        final color = p.type == 'received' ? palette.chartRevenue : palette.chartPayment;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.partyName ?? 'Unknown',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppHelpers.displayDate(p.date),
                      style: GoogleFonts.dmSans(fontSize: 11, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                AppHelpers.formatCurrency(p.amount),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverdueSortableTable(_Palette palette) {
    final rows = List<Process>.from(_overdueProcesses)..sort(_compareOverdueRows);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surfaceAlt.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _sortableHeader(palette, 0, 'Diamond'),
                _sortableHeader(palette, 1, 'Stage'),
                _sortableHeader(palette, 2, 'Party'),
                _sortableHeader(palette, 3, 'Due Date'),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final p = rows[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: palette.border.withValues(alpha: 0.35)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.diamondCode ?? '-',
                          style: GoogleFonts.jetBrainsMono(
                            color: palette.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          p.processTypeName ?? '-',
                          style: GoogleFonts.dmSans(color: palette.textSecondary, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          p.partyName.isEmpty ? '-' : p.partyName,
                          style: GoogleFonts.dmSans(color: palette.textSecondary, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              AppHelpers.displayDate(p.toDate),
                              style: GoogleFonts.dmSans(
                                color: palette.negative,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(palette, 'pending'),
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
    );
  }

  Widget _sortableHeader(_Palette palette, int column, String title) {
    final selected = _sortColumn == column;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortColumn == column) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = column;
              _sortAscending = true;
            }
          });
        },
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                color: selected ? palette.textPrimary : palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            if (selected)
              Icon(
                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: palette.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  int _compareOverdueRows(Process a, Process b) {
    int result;
    switch (_sortColumn) {
      case 1:
        result = (a.processTypeName ?? '').compareTo(b.processTypeName ?? '');
        break;
      case 2:
        result = a.partyName.compareTo(b.partyName);
        break;
      case 3:
        result = (a.toDate ?? '').compareTo(b.toDate ?? '');
        break;
      case 0:
      default:
        result = (a.diamondCode ?? '').compareTo(b.diamondCode ?? '');
        break;
    }
    return _sortAscending ? result : -result;
  }

  Widget _buildStatusBadge(_Palette palette, String status) {
    Color bg = palette.surfaceAlt;
    Color fg = palette.textMuted;
    if (status == 'completed') {
      bg = palette.positive.withValues(alpha: 0.18);
      fg = palette.positive;
    } else if (status == 'pending') {
      bg = palette.warning.withValues(alpha: 0.18);
      fg = palette.warning;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(
          status.capitalize(),
          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }

  Widget _buildTableHeader(_Palette palette, List<String> headers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                child: Text(
                  h.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.textMuted,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _buildPipelineElements(_Palette palette) {
    if (_stageBreakdown.isEmpty) {
      return [
        Text(
          'No active pipelines',
          style: GoogleFonts.dmSans(fontSize: 12, color: palette.textMuted),
        ),
      ];
    }

    final nodes = <Widget>[];
    for (int i = 0; i < _stageBreakdown.length; i++) {
      final s = _stageBreakdown[i];
      Color c = palette.chartProcess;
      if (i == 0) c = palette.accent;
      if (i == _stageBreakdown.length - 1) c = palette.chartRevenue;

      nodes.add(
        AnimatedContainer(
          duration: Duration(milliseconds: 180 + (i * 80)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceAlt.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              AnimatedCounter(
                value: (s['count'] as int).toDouble(),
                formatter: (v) => v.toInt().toString(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s['name'] as String,
                style: GoogleFonts.dmSans(fontSize: 11, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      );

      if (i < _stageBreakdown.length - 1) {
        nodes.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right_rounded, color: palette.textMuted, size: 18),
          ),
        );
      }
    }
    return nodes;
  }

  Widget _metricCard(
    _Palette palette, {
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required String subtitle,
  }) {
    return _HoverCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            AnimatedCounter(
              value: value,
              formatter: AppHelpers.formatCurrency,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 19,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(fontSize: 11, color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countCard(
    _Palette palette, {
    required String title,
    required int count,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return _HoverCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedCounter(
                    value: count.toDouble(),
                    formatter: (v) => v.toInt().toString(),
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(color: palette.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveColumns({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              SizedBox(height: 360, child: left),
              const SizedBox(height: 16),
              SizedBox(height: 360, child: right),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: SizedBox(height: 360, child: left)),
            const SizedBox(width: 16),
            Expanded(child: SizedBox(height: 360, child: right)),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    _Palette palette, {
    required String title,
    required Widget child,
    bool expandChild = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _lightMode ? 0.04 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }

  Widget _buildGrid({
    required int maxColumns,
    required List<Widget> children,
    required double mobileHeight,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = maxColumns;
        if (constraints.maxWidth < 640) {
          cols = 1;
        } else if (constraints.maxWidth < 1024) {
          cols = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 2.5 : 1.9,
          ),
          itemBuilder: (context, index) {
            if (cols == 1) {
              return SizedBox(height: mobileHeight, child: children[index]);
            }
            return children[index];
          },
        );
      },
    );
  }

  Widget _buildReveal(int index, Widget child) {
    final delay = index * 55;
    return AnimatedOpacity(
      opacity: _revealed ? 1 : 0,
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _revealed ? Offset.zero : const Offset(0, 0.04),
        duration: Duration(milliseconds: 420 + delay),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  List<_MonthPoint> _buildMonthSeries(
    int months,
    List<Map<String, dynamic>> raw,
  ) {
    final lookup = <String, double>{};
    for (final row in raw) {
      final key = row['month']?.toString();
      if (key == null || key.isEmpty) continue;
      lookup[key] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }

    final now = DateTime.now();
    final points = <_MonthPoint>[];
    for (int i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(d);
      final label = DateFormat('MMM').format(d);
      points.add(_MonthPoint(label: label, value: lookup[key] ?? 0));
    }
    return points;
  }
}

class _HoverCard extends StatefulWidget {
  final _Palette palette;
  final Widget child;

  const _HoverCard({required this.palette, required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.palette.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.palette.accent.withValues(alpha: 0.5)
                : widget.palette.border,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hovered ? widget.palette.accent : Colors.black)
                  .withValues(alpha: _hovered ? 0.12 : 0.10),
              blurRadius: _hovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _MonthPoint {
  final String label;
  final double value;

  const _MonthPoint({required this.label, required this.value});
}

class _MonthlyAreaChart extends StatefulWidget {
  final List<_MonthPoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color textColor;

  const _MonthlyAreaChart({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.textColor,
  });

  @override
  State<_MonthlyAreaChart> createState() => _MonthlyAreaChartState();
}

class _MonthlyAreaChartState extends State<_MonthlyAreaChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _hovered;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxY = widget.points
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    final hoveredValue =
        (_hovered != null && _hovered! >= 0 && _hovered! < widget.points.length)
            ? widget.points[_hovered!]
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Text(
            hoveredValue == null
                ? 'Hover points for tooltip'
                : '${hoveredValue.label}  ${AppHelpers.formatCurrency(hoveredValue.value)}',
            style: GoogleFonts.dmSans(
              color: widget.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                onHover: (event) {
                  if (widget.points.isEmpty) return;
                  final step = constraints.maxWidth / math.max(widget.points.length - 1, 1);
                  final idx = (event.localPosition.dx / step).round();
                  final clamped = idx.clamp(0, widget.points.length - 1);
                  if (_hovered != clamped) {
                    setState(() => _hovered = clamped);
                  }
                },
                onExit: (_) => setState(() => _hovered = null),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AreaPainter(
                        points: widget.points,
                        maxY: maxY <= 0 ? 1 : maxY,
                        progress: _controller.value,
                        hovered: _hovered,
                        lineColor: widget.lineColor,
                        fillColor: widget.fillColor,
                        textColor: widget.textColor,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AreaPainter extends CustomPainter {
  final List<_MonthPoint> points;
  final double maxY;
  final double progress;
  final int? hovered;
  final Color lineColor;
  final Color fillColor;
  final Color textColor;

  const _AreaPainter({
    required this.points,
    required this.maxY,
    required this.progress,
    required this.hovered,
    required this.lineColor,
    required this.fillColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = textColor.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (points.isEmpty) return;

    final stepX = size.width / math.max(points.length - 1, 1);
    final pathLine = Path();
    final pathFill = Path();

    for (int i = 0; i < points.length; i++) {
      final x = stepX * i;
      final y = size.height - ((points[i].value / maxY) * size.height * 0.9) - 6;
      final yAnimated = size.height - ((size.height - y) * progress);

      if (i == 0) {
        pathLine.moveTo(x, yAnimated);
        pathFill.moveTo(x, size.height);
        pathFill.lineTo(x, yAnimated);
      } else {
        pathLine.lineTo(x, yAnimated);
        pathFill.lineTo(x, yAnimated);
      }
    }

    pathFill.lineTo(stepX * (points.length - 1), size.height);
    pathFill.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(pathFill, fillPaint);
    canvas.drawPath(pathLine, linePaint);

    for (int i = 0; i < points.length; i++) {
      final x = stepX * i;
      final y = size.height - ((points[i].value / maxY) * size.height * 0.9) - 6;
      final yAnimated = size.height - ((size.height - y) * progress);
      final active = hovered == i;

      canvas.drawCircle(
        Offset(x, yAnimated),
        active ? 5 : 3,
        Paint()..color = active ? lineColor : lineColor.withValues(alpha: 0.85),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: GoogleFonts.dmSans(
            color: textColor.withValues(alpha: 0.82),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((x - tp.width / 2).clamp(0, size.width - tp.width), size.height + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _AreaPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.hovered != hovered || oldDelegate.points != points;
  }
}

class _BarValue {
  final String label;
  final double value;
  final Color color;

  const _BarValue(this.label, this.value, this.color);
}

class _CostBarChart extends StatelessWidget {
  final List<_BarValue> bars;
  final Color textColor;

  const _CostBarChart({required this.bars, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    return Column(
      children: [
        for (int index = 0; index < bars.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final bar = bars[index];
              final ratio = bar.value / safeMax;

              return Tooltip(
                message: '${bar.label}: ${AppHelpers.formatCurrency(bar.value)}',
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        bar.label,
                        style: GoogleFonts.dmSans(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ratio),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [bar.color.withValues(alpha: 0.8), bar.color],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppHelpers.formatCurrency(bar.value),
                      style: GoogleFonts.jetBrainsMono(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Palette {
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color chartRevenue;
  final Color chartPurchase;
  final Color chartProcess;
  final Color chartPayment;

  const _Palette({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.chartRevenue,
    required this.chartPurchase,
    required this.chartProcess,
    required this.chartPayment,
  });

  factory _Palette.light() {
    return const _Palette(
      background: Color(0xFFF3F5F9),
      backgroundAlt: Color(0xFFE5EAF3),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFF6F8FC),
      border: Color(0xFFDEE5F1),
      textPrimary: Color(0xFF1A2433),
      textSecondary: Color(0xFF4A5B72),
      textMuted: Color(0xFF7A8AA1),
      accent: Color(0xFFB9851F),
      positive: Color(0xFF059669),
      negative: Color(0xFFE11D48),
      warning: Color(0xFFD97706),
      chartRevenue: Color(0xFF0F766E),
      chartPurchase: Color(0xFFDC2626),
      chartProcess: Color(0xFFEA580C),
      chartPayment: Color(0xFF2563EB),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
