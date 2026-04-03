import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/app_theme.dart';

enum NavSection {
  dashboard,
  roughStones,
  diamonds,
  processes,
  parties,
  purchases,
  sales,
  payments,
  settings,
  processTypes,
  expenseCategories,
  backupRestore,
  about,
}

class AppSidebar extends StatelessWidget {
  final NavSection selected;
  final ValueChanged<NavSection> onSelect;
  final bool collapsed;

  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 80.0 : 280.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
            Color(0xFFF8FAFC),
          ],
        ),
        border: Border(
          right: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 16 : 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.diamond_rounded,
                      color: AppTheme.accent, size: 28),
                  if (!collapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Diamond Story',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(color: AppTheme.divider, height: 1, thickness: 1),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!collapsed) const _SectionHeader('DASHBOARD'),
                  _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', section: NavSection.dashboard, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  if (!collapsed) const _SectionHeader('INVENTORY'),
                  if (collapsed) const SizedBox(height: 8),
                  _NavItem(icon: Icons.circle_outlined, label: 'Rough Stones', section: NavSection.roughStones, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.diamond_outlined, label: 'Diamonds', section: NavSection.diamonds, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  if (!collapsed) const _SectionHeader('PROCESS'),
                  if (collapsed) const SizedBox(height: 8),
                  _NavItem(icon: Icons.precision_manufacturing_rounded, label: 'Processes', section: NavSection.processes, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  if (!collapsed) const _SectionHeader('LEDGER'),
                  if (collapsed) const SizedBox(height: 8),
                  _NavItem(icon: Icons.people_alt_outlined, label: 'Parties', section: NavSection.parties, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.shopping_bag_outlined, label: 'Purchases', section: NavSection.purchases, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.sell_outlined, label: 'Sales', section: NavSection.sales, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Payments', section: NavSection.payments, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  if (!collapsed) const _SectionHeader('SETTINGS'),
                  if (collapsed) const SizedBox(height: 8),
                  _NavItem(icon: Icons.settings_applications_rounded, label: 'Process Types', section: NavSection.processTypes, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.category_outlined, label: 'Exp. Categories', section: NavSection.expenseCategories, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.backup_outlined, label: 'Backup & Restore', section: NavSection.backupRestore, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.settings_rounded, label: 'Settings', section: NavSection.settings, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  _NavItem(icon: Icons.auto_awesome_rounded, label: 'About', section: NavSection.about, selected: selected, onSelect: onSelect, collapsed: collapsed),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
              const Divider(color: AppTheme.divider, height: 1, thickness: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 20, vertical: 12),
            child: collapsed
                ? const Center(child: Icon(Icons.info_outline, color: AppTheme.textMuted, size: 14))
                : Text('v1.0.0', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final NavSection section;
  final NavSection selected;
  final ValueChanged<NavSection> onSelect;
  final bool collapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.section,
    required this.selected,
    required this.onSelect,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == section;
    final iconColor = isSelected ? AppTheme.accent : AppTheme.textSecondary;
    final bgColor = isSelected ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent;

    if (collapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: () => onSelect(section),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 80,
            height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onSelect(section),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


