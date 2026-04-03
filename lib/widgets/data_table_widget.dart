import 'package:flutter/material.dart';
import '../core/utils/app_theme.dart';

// ============================================================================
// STATUS CHIP
// ============================================================================

class StatusChip extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusChip({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      'raw': (const Color(0xFF334155), const Color(0xFF94A3B8)),
      'in_process': (const Color(0xFF78350F), const Color(0xFFFBBF24)),
      'completed': (const Color(0xFF064E3B), const Color(0xFF34D399)),
      'sold': (const Color(0xFF1E3A8A), const Color(0xFF60A5FA)),
      'pending': (const Color(0xFF451A03), const Color(0xFFFB923C)),
      'active': (const Color(0xFF064E3B), const Color(0xFF2DD4BF)),
      'paid': (const Color(0xFF064E3B), const Color(0xFF34D399)),
      'received': (const Color(0xFF1E3A8A), const Color(0xFF60A5FA)),
    };
    final (bg, fg) =
        colors[status] ?? (const Color(0xFF334155), const Color(0xFF94A3B8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor ?? bg, borderRadius: BorderRadius.circular(16)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: textColor ?? fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ============================================================================
// PARTY TYPE BADGE
// ============================================================================

class PartyTypeBadge extends StatelessWidget {
  final String type;
  const PartyTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'supplier': const Color(0xFF2196F3),
      'customer': const Color(0xFF4CAF50),
      'worker': const Color(0xFFFF9800),
    };
    final color = colors[type.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF1A237E).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.add, size: 18),
              label: Text(ctaLabel!),
            )
          ]
        ],
      ),
    );
  }
}

// ============================================================================
// DELETE CONFIRM DIALOG
// ============================================================================

Future<bool> showDeleteConfirmDialog(BuildContext context, String item) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Delete',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Delete "$item"? This cannot be undone.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                )
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

// ============================================================================
// PAGE HEADER
// ============================================================================

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final String? statusText;
  final IconData? statusIcon;
  final Color? statusColor;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.statusText,
    this.statusIcon,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStatusColor = statusColor ?? AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  ],
                  if (statusText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: effectiveStatusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: effectiveStatusColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon ?? Icons.schedule_rounded,
                              size: 14, color: effectiveStatusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: effectiveStatusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?action
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.divider),
        const SizedBox(height: 20)
      ],
    );
  }
}

// ============================================================================
// FORM FIELD LABEL WRAPPER
// ============================================================================

class AppFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;

  const AppFormField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
            children: required
                ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        child
      ],
    );
  }
}

// ============================================================================
// STYLED DIALOG WRAPPER
// ============================================================================

class AppDialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool loading;
  final String? errorMessage;

  const AppDialog({
    super.key,
    required this.title,
    required this.fields,
    this.confirmLabel = 'Save',
    required this.onConfirm,
    this.loading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4A000000),
                blurRadius: 40,
                offset: Offset(0, 18),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ...fields.map(
                  (f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: f),
                ),
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16)
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: loading ? null : onConfirm,
                      child: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(confirmLabel),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SKELETON LOADER
// ============================================================================

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool shimmer;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 6,
    this.shimmer = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        if (!widget.shimmer) {
          final pulse = _anim.value <= 0.5 ? _anim.value * 2 : (1 - _anim.value) * 2;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSoft.withValues(alpha: 0.55 + (pulse * 0.25)),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sweep = constraints.maxWidth * 0.9;
              return Stack(
                children: [
                  Positioned(
                    left: (constraints.maxWidth + sweep) * _anim.value - sweep,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: sweep,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// TABLE SKELETON
// ============================================================================

class TableSkeleton extends StatelessWidget {
  final int rows;
  const TableSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSoft,
              borderRadius:
                  const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: SkeletonLoader(height: 12, width: 60 + i * 20.0),
                  ),
                ),
              ),
            ),
          ),
          ...List.generate(
            rows,
            (i) => Container(
              height: 52,
              color: i.isEven
                  ? Colors.transparent
                  : AppTheme.surfaceSoft.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  4,
                  (j) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: SkeletonLoader(height: 12, width: 40 + j * 30.0),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// STYLED CARD
// ============================================================================

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accentColor != null) Container(width: 4, color: accentColor),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION LABEL
// ============================================================================

class SectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showDivider;

  const SectionLabel(
    this.text, {
    super.key,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.accent.withValues(alpha: 0.7),
        letterSpacing: 2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
              ],
              Expanded(child: label),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppTheme.divider),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// TABLE ROW DATA
// ============================================================================

class TableRowData {
  final List<Widget> cells;
  const TableRowData({required this.cells});
}

// ============================================================================
// STYLED TABLE
// ============================================================================

class StyledTable extends StatelessWidget {
  final List<String> columns;
  final List<TableRowData> rows;
  final List<double>? columnWidths;

  const StyledTable({
    super.key,
    required this.columns,
    required this.rows,
    this.columnWidths,
  });

  List<double> _getColumnWidths(BuildContext context) {
    if (columnWidths != null) return columnWidths!;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // padding
    final colWidth = availableWidth / columns.length;
    return List.generate(columns.length, (_) => colWidth);
  }

  @override
  Widget build(BuildContext context) {
    final colWidths = _getColumnWidths(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSoft,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: List.generate(
                  columns.length,
                  (i) => SizedBox(
                    width: colWidths[i],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          columns[i],
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Rows
            if (rows.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No data available',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ...List.generate(
              rows.length,
              (i) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: 52,
                  color: i.isEven
                      ? Colors.transparent
                      : AppTheme.surfaceSoft.withValues(alpha: 0.45),
                  child: Row(
                    children: List.generate(
                      rows[i].cells.length,
                      (j) => SizedBox(
                        width: colWidths[j],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: rows[i].cells[j],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SNACKBAR HELPERS
// ============================================================================

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}


