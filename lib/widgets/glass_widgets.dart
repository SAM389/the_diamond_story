import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/app_theme.dart';

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

    final normalized = status.toLowerCase();
    final (bg, fg) = colors[normalized] ??
        (const Color(0xFF334155), const Color(0xFF94A3B8));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? bg,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Text(
        normalized.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(
          color: textColor ?? fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

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
    final color = colors[type.toLowerCase()] ?? AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.isEmpty
            ? '-'
            : type[0].toUpperCase() + type.substring(1).toLowerCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsets? padding;
  final double radius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accentColor != null)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  bottomLeft: Radius.circular(radius),
                ),
              ),
            ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(24),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact) ...[
          _buildTitleBlock(effectiveStatusColor),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTitleBlock(effectiveStatusColor)),
              if (action != null) ...[
                const SizedBox(width: 16),
                action!,
              ],
            ],
          ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.divider),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTitleBlock(Color effectiveStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
        if (statusText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: effectiveStatusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: effectiveStatusColor.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon ?? Icons.notifications_none_outlined,
                  size: 14,
                  color: effectiveStatusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: effectiveStatusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

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
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5A000000),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: field,
                ),
              ),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 14),
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
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            Text(
              'Confirm Delete',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Delete "$item"? This cannot be undone.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}


