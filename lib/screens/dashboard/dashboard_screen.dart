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
  List<Map<String, dynamic>> _stageBreakdown = [];
  List<Process> _recentActivity = [];
  List<Payment> _recentPayments = [];
  List<Process> _overdueProcesses = [];
  double _pendingPaymentTotal = 0;
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
        inv.getDashboardStats(),
        ledger.getDashboardStats(),
        process.getPendingCount(),
        process.getStageBreakdown(),
        process.getRecentActivity(10),
        ledger.getRecentPayments(10),
        process.getOverdueProcesses(),
        ledger.getPendingPayments(),
      ]);
      if (!mounted) return;
      final rawLedger = results[1] as Map<dynamic, dynamic>;
      final safeLedger = <String, double>{
        for (final entry in rawLedger.entries)
          entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0.0,
      };
      
      double pendingTotal = 0;
      final pendingList = results[7] as List<Payment>;
      for (var p in pendingList) pendingTotal += p.amount;

      setState(() {
        _inventoryStats = results[0] as Map<String, dynamic>;
        _ledgerStats = safeLedger;
        _pendingProcesses = results[2] as int;
        _stageBreakdown = List<Map<String, dynamic>>.from(results[3] as List);
        _recentActivity = List<Process>.from(results[4] as List);
        _recentPayments = List<Payment>.from(results[5] as List);
        _overdueProcesses = List<Process>.from(results[6] as List);
        _pendingPaymentTotal = pendingTotal;
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null) return Scaffold(body: Center(child: Text(_errorMessage!)));

    final roughCount = (_inventoryStats['roughCount'] ?? 0) as int;
    final diamondCount = (_inventoryStats['diamondCount'] ?? 0) as int;
    final roughWeight = (_inventoryStats['roughWeight'] as double? ?? 0.0);
    final diamondWeight = (_inventoryStats['diamondWeight'] as double? ?? 0.0);
    final totalRevenue = _ledgerStats['totalRevenue'] ?? 0.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Row 1: KPI strip
            _buildResponsiveGrid(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              children: [
                _buildKpiCard(
                  label: 'Total diamonds',
                  value: '${roughCount + diamondCount}',
                  valueColor: const Color(0xFFA07820),
                  sub: '${(roughWeight + diamondWeight).toStringAsFixed(2)} ct inventory',
                ),
                _buildKpiCard(
                  label: 'Total revenue',
                  value: AppHelpers.formatCurrency(totalRevenue),
                  valueColor: const Color(0xFF15803D),
                  sub: 'Lifetime sales',
                ),
                _buildKpiCard(
                  label: 'Pending processes',
                  value: '$_pendingProcesses',
                  valueColor: const Color(0xFFB91C1C),
                  sub: '${_overdueProcesses.length} overdue',
                ),
                _buildKpiCard(
                  label: 'Net receivable',
                  value: AppHelpers.formatCurrency(_pendingPaymentTotal),
                  valueColor: const Color(0xFF0F172A),
                  sub: 'From pending payments',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Row 2: Pipeline
            _buildCard(
              title: 'Diamond pipeline',
              expandChild: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildPipelineElements(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Row 3: Recent Diamonds & Recent Lots
            _buildResponsiveGrid(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              children: [
                _buildCard(
                  title: 'Recent Activity',
                  child: _buildRecentActivityTable(),
                ),
                _buildCard(
                  title: 'Overdue Processes',
                  child: _buildOverdueProcessTable(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Row 4: Monthly Revenue, Stage Breakdown, Payments
            _buildResponsiveGrid(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              children: [
                _buildCard(
                  title: 'Monthly Revenue',
                  child: Center(child: Text('Chart Placeholder', style: GoogleFonts.inter(color: AppTheme.textMuted))),
                ),
                _buildCard(
                  title: 'Process stage breakdown',
                  child: _buildStageBreakdownLines(),
                ),
                _buildCard(
                  title: 'Recent Transactions',
                  child: _buildTransactionsList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({required int crossAxisCount, required double childAspectRatio, required List<Widget> children}) {
    return LayoutBuilder(builder: (context, constraints) {
      int cols = crossAxisCount;
      if (constraints.maxWidth < 600) cols = 1;
      else if (constraints.maxWidth < 900) cols = 2;
      
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: cols == 1 ? (childAspectRatio * 2) : childAspectRatio,
        children: children,
      );
    });
  }

  Widget _buildKpiCard({required String label, required String value, required Color valueColor, required String sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, letterSpacing: 0.6, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: valueColor)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    bool expandChild = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.7)),
          const SizedBox(height: 12),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }

  List<Widget> _buildPipelineElements() {
    if (_stageBreakdown.isEmpty) return [Text('No active pipelines', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted))];
    List<Widget> nodes = [];
    for (int i = 0; i < _stageBreakdown.length; i++) {
       final s = _stageBreakdown[i];
       Color c = const Color(0xFF185FA5);
       if (i == 0) c = const Color(0xFFA07820);
       else if (i == _stageBreakdown.length - 1) c = const Color(0xFF15803D);
       
       nodes.add(Container(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
         decoration: BoxDecoration(
           color: const Color(0xFFF1F5F9),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: AppTheme.divider, width: 0.5),
         ),
         child: Column(
           children: [
             Text('${s['count']}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: c)),
             const SizedBox(height: 2),
             Text(s['name'], style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
           ],
         ),
       ));
       if (i < _stageBreakdown.length - 1) {
         nodes.add(const Padding(
           padding: EdgeInsets.symmetric(horizontal: 10),
           child: Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
         ));
       }
    }
    return nodes;
  }

  Widget _buildRecentActivityTable() {
    return ListView(
      children: [
        _buildTableHeader(['Code', 'Process', 'Party', 'Status']),
        ..._recentActivity.take(5).map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(p.diamondCode ?? '-', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Text(p.processTypeName ?? '-', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
              Expanded(child: Text(p.partyName.isEmpty ? '-' : p.partyName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
              Expanded(child: _buildBadge(p.status)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildOverdueProcessTable() {
    return ListView(
      children: [
        _buildTableHeader(['Diamond', 'Stage', 'Party', 'Since']),
        ..._overdueProcesses.take(5).map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(p.diamondCode ?? '-', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Text(p.processTypeName ?? '-', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
              Expanded(child: Text(p.partyName.isEmpty ? '-' : p.partyName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
              Expanded(child: Text(AppHelpers.displayDate(p.toDate), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB91C1C)))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStageBreakdownLines() {
    int total = _stageBreakdown.fold(0, (sum, item) => sum + (item['count'] as int));
    if (total == 0) total = 1;
    return ListView(
      children: _stageBreakdown.map((s) {
        final count = s['count'] as int;
        final pct = count / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 70, child: Text(s['name'], style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFF185FA5), borderRadius: BorderRadius.circular(3))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 30, child: Text('$count', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsList() {
    return ListView(
      children: _recentPayments.take(5).map((p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(p.partyName ?? 'Unknown', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                   Text(AppHelpers.displayDate(p.date), style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                 ]
               )
            ),
            Text(AppHelpers.formatCurrency(p.amount), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF15803D))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 0.5))
        )).toList(),
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    if (status == 'completed') { bg = const Color(0xFFEAF3DE); fg = const Color(0xFF27500A); }
    else if (status == 'pending') { bg = const Color(0xFFFAEEDA); fg = const Color(0xFF633806); }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(status.capitalize(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}