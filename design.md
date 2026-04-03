# The Diamond Story Front-end Design Scheme

This document captures the complete front-end visual scheme so the UI can be ported to another software stack with minimal drift.

## 1) Global Design System

### 1.1 Theme Entry
- Material app theme is applied from [lib/main.dart](lib/main.dart#L28) via `theme: AppTheme.lightTheme`.
- Source of truth for visual tokens is [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart).

### 1.2 Core Palette (Global Tokens)
From [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart#L6):

| Token | Hex | Usage |
|---|---|---|
| primary | #0F172A | Primary dark surfaces |
| accent | #D4AF37 | Gold highlight, primary CTA |
| surface | #0F172A | Surface color |
| background | #020617 | Main app background |
| cardColor | #0F172A | Card/dialog core base |
| divider | #1E293B | Borders/dividers |
| surfaceSoft | #1E293B | Soft dark container |
| textPrimary | #F8FAFC | Main foreground text |
| textSecondary | #94A3B8 | Secondary text |
| textMuted | #64748B | Muted text |

### 1.3 Semantic Colors
From [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart#L22):

- KPI tokens:
  - `kpiInventory` #475569
  - `kpiDiamond` #D4AF37
  - `kpiProcess` #D97706
  - `kpiPurchase` #DC2626
  - `kpiRevenue` #059669
  - `kpiProfit` #0F172A
- Status tokens:
  - `statusRaw` #9E9E9E
  - `statusInProcess` #FFB300
  - `statusCompleted` #43A047
  - `statusSold` #1E88E5
  - `statusPending` #FF7043
  - `statusPaid` #43A047
  - `statusReceived` #1E88E5
- Party tokens:
  - `partySupplier` #7B1FA2
  - `partyCustomer` #0277BD
  - `partyWorker` #00695C
- Utility tokens:
  - `success` #15803D
  - `danger` #B91C1C

### 1.4 Typography
From [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart#L73):

- Primary family: `GoogleFonts.inter`.
- Text theme:
  - `headlineSmall`: 24, bold, textPrimary
  - `titleLarge`: 20, w600, textPrimary
  - `titleMedium`: 16, w600, textPrimary
  - `bodyLarge`: 15, regular, textPrimary, letterSpacing -0.2
  - `bodyMedium`: 14, regular, textPrimary, letterSpacing -0.1
  - `bodySmall`: 13, regular, textSecondary
  - `labelLarge`: 14, w600, white, letterSpacing 0.2
  - `labelMedium`: 12, w600, textSecondary, letterSpacing 0.5
  - `labelSmall`: 11, w600, textMuted, letterSpacing 0.5

### 1.5 Shape / Spacing / Shadows
From [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart#L53):

- Radius:
  - cardRadius 16
  - dialogRadius 24
  - buttonRadius 12
  - chipRadius 24
- Button height: 48
- Dashboard spacing rhythm:
  - section gap 28
  - block gap 20
- Card shadow: dual layer shadow (`0x0A0F172A` and `0x050F172A`).

### 1.6 Component Theme Defaults
From [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart#L117):

- Input:
  - Fill #1E293B
  - Border #334155
  - Focus border accent #D4AF37
- Filled buttons:
  - Background accent #D4AF37
  - Foreground primary #0F172A
- Outlined buttons:
  - Border divider #1E293B
- Dialog:
  - Dark card background + 24 radius + elevated shadow
- Divider:
  - #1E293B
- Tooltip:
  - Dark overlay + 12px Inter
- SnackBar:
  - Floating dark base #1A1A2E

### 1.7 Icon System
- Material Icons enabled in [pubspec.yaml](pubspec.yaml#L78) via `uses-material-design: true`.
- Primary icon usage is Material rounded variants (`Icons.*_rounded`) across pages.
- `cupertino_icons` dependency exists but not used in screen/widget UI.

### 1.8 Assets and Fonts Packaging
From [pubspec.yaml](pubspec.yaml):

- No local assets declared under `flutter/assets`.
- No local custom font family declared under `flutter/fonts`.
- Typography depends on Google Fonts (`google_fonts` package).

## 2) Shared Reusable UI Contracts

### 2.1 AppCard
From [lib/widgets/glass_widgets.dart](lib/widgets/glass_widgets.dart#L11):
- Glass container style:
  - Default color #0F172A at 0.6 opacity
  - Border white at 10% opacity, width 1.5
  - Default radius 24
  - Default padding 24

### 2.2 PageHeader
From [lib/widgets/glass_widgets.dart](lib/widgets/glass_widgets.dart#L47):
- Title style: Inter, 28, w900, white, letterSpacing -0.5
- Subtitle style: Inter, 14, w500, white38
- Responsive behavior:
  - Mobile (<600): stacked title + actions
  - Desktop: row with right action slot

### 2.3 AppDialog and AppFormField
From [lib/widgets/glass_widgets.dart](lib/widgets/glass_widgets.dart#L142):
- Dialog:
  - Dark surface #0F172A at 0.95 opacity
  - 28 radius
  - White border at 10%
  - Heavy soft shadow
- Header title: 22, w800, white
- Confirm button: gold accent background + black text
- Form field labels: Inter 13, white70, optional red `*`

### 2.4 StatusChip and PartyTypeBadge
From [lib/widgets/glass_widgets.dart](lib/widgets/glass_widgets.dart#L304):
- `StatusChip` map:
  - raw: bg #334155, text #94A3B8
  - in_process: bg #78350F, text #FBBF24
  - completed: bg #064E3B, text #34D399
  - sold: bg #1E3A8A, text #60A5FA
  - pending: bg #451A03, text #FB923C
  - active: bg #064E3B, text #2DD4BF
- `PartyTypeBadge`:
  - supplier #2196F3
  - customer #4CAF50
  - worker #FF9800

### 2.5 Sidebar Navigation Contract
From [lib/widgets/sidebar.dart](lib/widgets/sidebar.dart):
- Width:
  - Expanded 280
  - Collapsed 80
- Background gradient: #0F172A -> #1E293B -> #020617
- Right border: white 8%
- Selected nav:
  - Accent indicator bar + subtle glass highlight
  - Icon accent and heavier text
- Sections:
  - Console, Inventory, Operations, Ledger, Config, System

### 2.6 Data Table Contract
From [lib/widgets/data_table_widget.dart](lib/widgets/data_table_widget.dart):
- Header:
  - Height 52
  - White 5% background
  - Header text 10, w800, white54, letterSpacing 1.2
- Rows:
  - Height 52
  - Alternate stripe white 1%
  - Divider white10
- Confirm delete dialog:
  - Background #1E293B
  - Destructive action redAccent
- Snackbar helpers:
  - success: green.shade600
  - error: red.shade600

## 3) Page-by-Page Design Scheme

## 3.1 Auth

### 3.1.1 Password Screen
File: [lib/screens/auth/password_screen.dart](lib/screens/auth/password_screen.dart)

- Background:
  - Full-screen linear gradient: #0F172A -> #1E293B -> #020617
  - Decorative accent orb: accent with 5% opacity
- Container:
  - Uses `AppCard`; max content width 420; responsive padding 24/48
- Typography:
  - Title: Inter 24, w900, white
  - Subtitle: Inter 13, w500, white38
- Inputs:
  - Custom glass style (white 5% fill), rounded 12, no standard border
  - Prefix icons: `lock_person_rounded`, `verified_user_rounded`
  - Toggle icons: `visibility_rounded`/`visibility_off_rounded`
- Primary icon:
  - `diamond_rounded` in accent circle
- Motion:
  - Elastic shake animation on validation failure

## 3.2 Shell / Navigation

### 3.2.1 Home Screen
File: [lib/screens/home/home_screen.dart](lib/screens/home/home_screen.dart)

- Scaffold background: #0F172A
- Desktop structure:
  - Left `AppSidebar` + right animated content panel
- Mobile structure:
  - Drawer-based `AppSidebar`
  - AppBar with `diamond_rounded` accent icon and centered brand text
- Transition:
  - AnimatedSwitcher fade + slight slide (220ms)

## 3.3 Dashboard

### 3.3.1 Dashboard Overview
File: [lib/screens/dashboard/dashboard_screen.dart](lib/screens/dashboard/dashboard_screen.dart)

- Background:
  - Gradient #020617 -> #0F172A -> #020617
  - Decorative circles: indigo #6366F1 (8%) and gold #D4AF37 (5%)
- Header:
  - Title Inter 24/28, bold, textPrimary
  - Last updated line Inter 13, textMuted
  - Notification chip icon `notifications_none_outlined`
- Payment dues block:
  - Glass card style with white low-opacity borders
  - Total amount in emerald #10B981, 32px, w900
  - Party badge in red #EF4444 tint
- Process alerts block:
  - Main count in indigo #6366F1
  - Overdue badge amber #F59E0B
  - Stage bars in indigo gradient #6366F1 -> #818CF8
- Repeated icon usage:
  - `payments_rounded`, `diamond_rounded`, `person_outline_rounded`, `warning_amber_rounded`

## 3.4 Inventory

### 3.4.1 Diamonds Page
File: [lib/screens/inventory/diamonds_page.dart](lib/screens/inventory/diamonds_page.dart)

- Header:
  - Title: Diamond Inventory
  - Subtitle: Manage and track your cut stones
- Top controls:
  - Search box: white 5% fill, white 10% border, 12 radius
  - Status filter chip/dropdown
- Stats cards:
  - Inventory (accent), weight (cyan #38BDF8), raw/process (amber #FB923C), sold (green #4ADE80)
- Table:
  - 900 fixed width horizontal table container
  - Header 52 high, white 5% fill
  - Zebra rows white 1%
  - Diamond code cell uses accent icon+text
- Status visual:
  - Uses shared `StatusChip`

### 3.4.2 Rough Stones Page
File: [lib/screens/inventory/rough_stone_page.dart](lib/screens/inventory/rough_stone_page.dart)

- Header:
  - Title: Rough Stones
  - Subtitle breadcrumb style: Inventory > Rough Stones
- Controls:
  - Search field same glass style
  - CTA button: Add Rough Stone
- Stats:
  - Lots accent, weight cyan #38BDF8, value green #4ADE80
- Table:
  - 900 fixed width
  - Lot number text accent
  - Price text emerald #10B981
- Action icons:
  - Split, edit, delete with semantic colors

## 3.5 Ledger

### 3.5.1 Parties Page
File: [lib/screens/ledger/parties_page.dart](lib/screens/ledger/parties_page.dart)

- Header:
  - Title: Business Directory
  - Subtitle: supplier/customer/worker management
- Controls:
  - Search box + type filter + Add Partner CTA
- Stats:
  - Total accent, suppliers cyan #38BDF8, customers green #4ADE80, workers pink #F472B6
- Table:
  - 900 fixed width
  - Category via `PartyTypeBadge`
  - Contact and address use lower contrast white shades

### 3.5.2 Purchase Page
File: [lib/screens/ledger/purchase_page.dart](lib/screens/ledger/purchase_page.dart)

- Header:
  - Title: Purchase Ledger
  - Subtitle: rough stone acquisition history
- Controls:
  - Search + Record Purchase button
- Stats:
  - Entries accent, spent green #4ADE80, inventory cyan #38BDF8, suppliers pink #F472B6
- Table:
  - 900 width
  - Lot chip: accent tint + accent text
  - Amounts highlighted in green #4ADE80

### 3.5.3 Sales Page
File: [lib/screens/ledger/sales_page.dart](lib/screens/ledger/sales_page.dart)

- Header:
  - Title: Sales Ledger
  - Subtitle: premium sales tracking
- Controls:
  - Search + Record Sale button
- Stats:
  - Total accent, revenue green #4ADE80, assets cyan #38BDF8, customers pink #F472B6
- Table:
  - Asset code chip: cyan tint + cyan text
  - Sale price text green #4ADE80

### 3.5.4 Payments Page
File: [lib/screens/ledger/payments_page.dart](lib/screens/ledger/payments_page.dart)

- Header:
  - Title: Payment Ledger
  - Subtitle: comprehensive financial tracking
- Controls:
  - Search + Record Payment button
- Stats:
  - Total accent, paid red #F87171, received green #4ADE80, pending amber #FB923C
- Table:
  - 1000 width
  - Amount text changes by transaction type
  - Type/status represented with `StatusChip`

## 3.6 Process

### 3.6.1 Process List Page
File: [lib/screens/process/process_list_page.dart](lib/screens/process/process_list_page.dart)

- Header:
  - Title: Production Tracking
  - Subtitle: manufacturing phase management
- Controls:
  - Search + New Process CTA
- Stats:
  - Total accent, pending amber #FB923C, completed green #4ADE80, costs indigo #818CF8
- Table:
  - 1000 width
  - Process cell has dark badge style
  - Fee text accent

### 3.6.2 Add Process Dialog
File: [lib/screens/process/add_process_dialog.dart](lib/screens/process/add_process_dialog.dart)

- Uses `AppDialog` shell
- Field style:
  - Container fill white 5%
  - Border white 10%
  - Radius 12
- Dropdown style:
  - `dropdownColor` #1E293B
  - Text white, hint white24
- Date fields:
  - Calendar suffix icons white30
- Error text:
  - redAccent, 12

## 3.7 Settings

### 3.7.1 Settings Page
File: [lib/screens/settings/settings_page.dart](lib/screens/settings/settings_page.dart)

- Background:
  - Gradient #0F172A@0.8 -> #1E293B@0.9
- Layout:
  - Sectioned settings cards with 24 radius
  - Section labels: uppercase, accent at ~70%, 11 size, letterSpacing 2
- Tiles:
  - Icon block white 5%
  - Title 15 white, subtitle 12 white38
  - Trailing switch/label/chevron

### 3.7.2 Process Types Page
File: [lib/screens/settings/process_types_page.dart](lib/screens/settings/process_types_page.dart)

- Header:
  - Title: Manufacturing Workflow
- List card pattern:
  - `AppCard` row with accent circular icon
- Dialog style:
  - AppDialog with glass form input
- Icons:
  - `settings_suggest_rounded`, `delete_sweep_rounded`

### 3.7.3 Expense Category Page
File: [lib/screens/settings/expense_category_page.dart](lib/screens/settings/expense_category_page.dart)

- Header:
  - Title: Financial Classifications
- Visual pattern:
  - Mirrors Process Types page
  - Accent circular icon and glass list card
- Icons:
  - `label_outline_rounded`, `delete_sweep_rounded`

### 3.7.4 Backup Restore Page
File: [lib/screens/settings/backup_restore_page.dart](lib/screens/settings/backup_restore_page.dart)

- Header:
  - Title: Data Vault
- Message banner:
  - Error: redAccent tint + icon
  - Success: tealAccent tint + icon
- Sections:
  - Uses `SectionLabel` headings for ARCHIVAL CONTROLS and SYSTEM INTEGRITY
- Cards:
  - Glass cards with icon-leading action groups
- Primary action colors:
  - Teal used for export button/action emphasis

### 3.7.5 About Us Page
File: [lib/screens/settings/about_us_page.dart](lib/screens/settings/about_us_page.dart)

- Background scene:
  - Radial gradient orbs using accent and indigo #6366F1 at low opacity
- Hero block:
  - Circular logo holder (140x140) with accent border glow
  - Main title 48, w900, white
  - Version pill with accent tint/border
- Content cards:
  - Uses `AppCard` for manifesto and metric cards
- Icon set:
  - `diamond_rounded`, `auto_awesome_rounded`, `shield_moon_rounded`, `rocket_launch_rounded`

## 4) Cross-Page Design Patterns

- Dark luxury visual language:
  - Deep slate backgrounds, gold accents, glass overlays.
- Table-heavy ERP layout:
  - 900-1000 fixed width table blocks with horizontal scroll.
- Consistent CTA language:
  - Filled gold buttons with black text for primary actions.
- Icon style:
  - Rounded Material icons and compact visual chips.
- Text density:
  - Inter used everywhere with small, controlled letterSpacing and high weight for headings/metrics.

## 5) Transfer Checklist (For Another Software)

1. Recreate global tokens first (colors, typography, radius, spacing, shadows) from [lib/core/utils/app_theme.dart](lib/core/utils/app_theme.dart).
2. Implement reusable primitives before pages:
   - AppCard
   - PageHeader
   - AppDialog
   - StatusChip
   - PartyTypeBadge
   - Sidebar
   - Styled Table
3. Implement each page in the same order as section 3 to reduce dependency issues.
4. Keep fixed-width horizontal table behavior for desktop parity.
5. Preserve semantic color logic for statuses and financial metrics.
6. Add fallback strategy for Inter font in target stack.

## 6) Portability Notes

- A number of pages use hardcoded color values in addition to theme tokens (notably dashboard/auth/settings/process/ledger stats). Keep these explicit overrides if pixel parity is required.
- No local font assets are bundled; if target environment is offline-sensitive, package Inter locally.
- No image/SVG theme assets are required for baseline UI parity.

## 7) Page Coverage Confirmation

All screen files currently under [lib/screens](lib/screens) are covered in this design document:
- [lib/screens/auth/password_screen.dart](lib/screens/auth/password_screen.dart)
- [lib/screens/home/home_screen.dart](lib/screens/home/home_screen.dart)
- [lib/screens/dashboard/dashboard_screen.dart](lib/screens/dashboard/dashboard_screen.dart)
- [lib/screens/inventory/diamonds_page.dart](lib/screens/inventory/diamonds_page.dart)
- [lib/screens/inventory/rough_stone_page.dart](lib/screens/inventory/rough_stone_page.dart)
- [lib/screens/ledger/parties_page.dart](lib/screens/ledger/parties_page.dart)
- [lib/screens/ledger/purchase_page.dart](lib/screens/ledger/purchase_page.dart)
- [lib/screens/ledger/sales_page.dart](lib/screens/ledger/sales_page.dart)
- [lib/screens/ledger/payments_page.dart](lib/screens/ledger/payments_page.dart)
- [lib/screens/process/process_list_page.dart](lib/screens/process/process_list_page.dart)
- [lib/screens/process/add_process_dialog.dart](lib/screens/process/add_process_dialog.dart)
- [lib/screens/settings/settings_page.dart](lib/screens/settings/settings_page.dart)
- [lib/screens/settings/process_types_page.dart](lib/screens/settings/process_types_page.dart)
- [lib/screens/settings/expense_category_page.dart](lib/screens/settings/expense_category_page.dart)
- [lib/screens/settings/backup_restore_page.dart](lib/screens/settings/backup_restore_page.dart)
- [lib/screens/settings/about_us_page.dart](lib/screens/settings/about_us_page.dart)
