import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/app_theme.dart';

enum DashboardCardVariant { standard, compact, detailed }

class DashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? secondaryValue;
  final String? trendLabel;
  final bool? trendPositive;
  final IconData icon;
  final Color color;
  final bool? isPositive;
  final DashboardCardVariant variant;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.secondaryValue,
    this.trendLabel,
    this.trendPositive,
    required this.icon,
    required this.color,
    this.isPositive,
    this.variant = DashboardCardVariant.standard,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isPositive == null
        ? widget.color
        : (widget.isPositive! ? AppTheme.success : AppTheme.danger);
    final compact = widget.variant == DashboardCardVariant.compact;
    final detailed = widget.variant == DashboardCardVariant.detailed;
    final valueSize = compact ? 22.0 : 26.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translateByDouble(0.0, _isHovered ? -3.0 : 0.0, 0.0, 1.0),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.divider),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: effectiveColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.cardRadius),
                    bottomLeft: Radius.circular(AppTheme.cardRadius),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, compact ? 14 : 16, 16, compact ? 14 : 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.value,
                                    style: GoogleFonts.inter(
                                      fontSize: valueSize,
                                      fontWeight: FontWeight.w700,
                                      color: effectiveColor,
                                      height: 1.06,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isPositive != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    widget.isPositive!
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: effectiveColor,
                                  ),
                                ],
                              ],
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (detailed && widget.secondaryValue != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.secondaryValue!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (detailed && widget.trendLabel != null) ...[
                              const SizedBox(height: 10),
                              _TrendChip(
                                label: widget.trendLabel!,
                                positive: widget.trendPositive,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: compact ? 42 : 46,
                        height: compact ? 42 : 46,
                        decoration: BoxDecoration(
                          color: effectiveColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: effectiveColor, size: compact ? 20 : 22),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String label;
  final bool? positive;

  const _TrendChip({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive == null
        ? AppTheme.textSecondary
        : (positive! ? AppTheme.success : AppTheme.danger);
    final icon = positive == null
        ? Icons.trending_flat_rounded
        : (positive! ? Icons.trending_up_rounded : Icons.trending_down_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
