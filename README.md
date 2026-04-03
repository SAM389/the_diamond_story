Great — adding **Backup/Restore + App Password** makes your system much closer to a **real ERP**. I’ll integrate these features into the design and then give you the **complete production structure**.

---

# 1. New Feature: Backup & Restore System 💾

Goal:

* User works on **Company PC**
* Creates **encrypted backup**
* Copies to **Pendrive**
* Restores on **Home Laptop**
* Data loads exactly the same

---

## Backup Flow

```
User clicks Backup
        ↓
Enter Password
        ↓
Export SQLite DB
        ↓
Convert tables → CSV
        ↓
Zip files
        ↓
Encrypt ZIP with password
        ↓
Download backup file
```

Backup File Example

```
diamond_backup_2026_03_12.dbackup
```

---

## Restore Flow

You already described it correctly:

```
User selects backup file
        ↓
Enter password
        ↓
Decrypt file
        ↓
Unzip
        ↓
Replace database
        ↓
Restart app
```

---

## Backup Folder Structure

```
backup/
   rough_stones.csv
   diamonds.csv
   processes.csv
   parties.csv
   purchases.csv
   sales.csv
   payments.csv
   expense_categories.csv
   metadata.json
```

---

## Flutter Packages Needed

```
file_picker
archive
encrypt
path_provider
csv
```

---

# 2. App Password System 🔐

When user opens app:

```
App Start
   ↓
Check password exists?
   ↓
No → Create Password
Yes → Enter Password
   ↓
Open Dashboard
```

---

## Password Table

SQLite table:

```
app_settings
-----------------
id
app_password_hash
created_at
```

Use:

```
bcrypt or sha256
```

Never store raw password.

---

# 3. Complete SQLite Schema (Production Ready)

This schema is structured for **manufacturing flow**.

---

# Table 1 — Rough Stones

```
rough_stones
-------------------------
id INTEGER PRIMARY KEY
lot_no TEXT UNIQUE
title TEXT
weight REAL
quality TEXT
purchase_price REAL
purchase_date TEXT
supplier_id INTEGER
notes TEXT
created_at TEXT
```

---

# Table 2 — Diamonds

Each diamond created from a rough lot.

```
diamonds
-------------------------
id INTEGER PRIMARY KEY
parent_lot TEXT
diamond_code TEXT UNIQUE
weight REAL
status TEXT
created_at TEXT
```

status values:

```
raw
in_process
completed
sold
```

---

# Table 3 — Process Types

User-defined.

```
process_types
-------------------------
id INTEGER PRIMARY KEY
name TEXT UNIQUE
created_at TEXT
```

Examples

```
Cutting
Polishing
Shining
Grading
```

---

# Table 4 — Processes

```
processes
-------------------------
id INTEGER PRIMARY KEY
diamond_id INTEGER
process_type_id INTEGER
party_name TEXT
from_date TEXT
to_date TEXT
status TEXT
notes TEXT
created_at TEXT
```

status

```
pending
completed
```

---

# Table 5 — Parties (Supplier / Customer)

```
parties
-------------------------
id INTEGER PRIMARY KEY
name TEXT
type TEXT
phone TEXT
address TEXT
created_at TEXT
```

type

```
supplier
customer
worker
```

---

# Table 6 — Purchases

```
purchases
-------------------------
id INTEGER PRIMARY KEY
party_id INTEGER
lot_id INTEGER
amount REAL
date TEXT
notes TEXT
created_at TEXT
```

---

# Table 7 — Sales

```
sales
-------------------------
id INTEGER PRIMARY KEY
party_id INTEGER
diamond_id INTEGER
price REAL
date TEXT
notes TEXT
created_at TEXT
```

---

# Table 8 — Payments

```
payments
-------------------------
id INTEGER PRIMARY KEY
party_id INTEGER
amount REAL
type TEXT
category TEXT
date TEXT
status TEXT
notes TEXT
```

type

```
paid
received
```

status

```
pending
completed
```

---

# Table 9 — Expense Categories

```
expense_categories
-------------------------
id INTEGER PRIMARY KEY
name TEXT
created_at TEXT
```

---

# Table 10 — App Settings

```
app_settings
-------------------------
id INTEGER PRIMARY KEY
app_password_hash TEXT
last_backup TEXT
created_at TEXT
```

---

# 4. Flutter Folder Architecture (Production)

```
lib/
│
├ main.dart
│
├ core/
│   ├ database/
│   │     database_helper.dart
│   │
│   ├ services/
│   │     backup_service.dart
│   │     encryption_service.dart
│   │
│   ├ utils/
│         constants.dart
│         helpers.dart
│
├ models/
│   rough_stone.dart
│   diamond.dart
│   process.dart
│   party.dart
│   purchase.dart
│   sales.dart
│   payment.dart
│
├ repositories/
│   rough_repository.dart
│   diamond_repository.dart
│   process_repository.dart
│
├ providers/
│   inventory_provider.dart
│   process_provider.dart
│   ledger_provider.dart
│
├ screens/
│
│   dashboard/
│       dashboard_screen.dart
│
│   inventory/
│       rough_stone_page.dart
│       diamonds_page.dart
│
│   process/
│       process_list_page.dart
│       add_process_page.dart
│
│   ledger/
│       parties_page.dart
│       purchase_page.dart
│       sales_page.dart
│       payments_page.dart
│
│   settings/
│       process_types_page.dart
│       expense_category_page.dart
│       backup_restore_page.dart
│
├ widgets/
│   sidebar.dart
│   data_table_widget.dart
│   dashboard_card.dart
```

---

# 5. UI Wireframe (Desktop)

### Main Layout

```
 --------------------------------------------------
| Sidebar        |                                |
|                |          Dashboard              |
| Dashboard      |                                |
| Inventory      |                                |
| Process        |                                |
| Ledger         |                                |
| Settings       |                                |
| Backup         |                                |
 --------------------------------------------------
```

---

# Rough Stones Page

```
 ---------------------------------------------------
| Add Rough Stone                                   |
 ---------------------------------------------------
| Lot | Title | Weight | Quality | Price | Date |
 ---------------------------------------------------
| 001 | Africa | 3.2 | A | 45000 | 10 Jan |
 ---------------------------------------------------
```

Button

```
+ Add Rough Stone
```

---

# Diamonds Page

```
---------------------------------------------------
| Parent Lot | Diamond Code | Weight | Status |
---------------------------------------------------
| LOT-001 | LOT-001A | 1.1 | Cutting |
| LOT-001 | LOT-001B | 1.0 | Polishing |
| LOT-001 | LOT-001C | 0.9 | Ready |
---------------------------------------------------
```

---

# Process Page

```
---------------------------------------------------
| Diamond | Process | Party | From | To | Status |
---------------------------------------------------
| 001A | Cutting | Star Cutter | 10 | 12 | Done |
---------------------------------------------------
```

---

# Ledger Page

Tabs

```
Parties | Purchases | Sales | Payments
```

---

# Backup Page

```
-------------------------------
Backup & Restore
-------------------------------

[ Backup Data ]

Enter Password

[ Create Backup File ]

-------------------------------

[ Restore Data ]

Select Backup File

Enter Password

[ Restore Database ]
```

---

# 6. Diamond Splitting Algorithm

Example

```
LOT-001
weight = 3.5
```

User splits into

```
3 diamonds
```

System creates

```
LOT-001A
LOT-001B
LOT-001C
```

---

## Pseudocode

```
function splitLot(lotNumber, numberOfDiamonds):

    letters = A,B,C,D,E,F...

    for i in range(numberOfDiamonds):

        diamondCode = lotNumber + letters[i]

        insert into diamonds(
            parent_lot = lotNumber
            diamond_code = diamondCode
        )
```

---

Example Output

```
splitLot("LOT-001",3)
```

Creates

```
LOT-001A
LOT-001B
LOT-001C
```

---

# 7. Process Tracking Logic

Important rule:

```
One diamond → one active process
```

---

### Process Flow

```
Diamond Created
        ↓
Select Process
        ↓
Send to Party
        ↓
Status = Pending
        ↓
Process Completed
        ↓
Status = Completed
```

---

### Validation Rules

Rule 1

```
Cannot start process if another process is active
```

---

Rule 2

```
Weight after process <= original weight
```

---

Rule 3

```
Completed process updates diamond status
```

---

Example

```
LOT-001A
status = in_process
```

After polishing

```
status = completed
```

---

# 8. Future Features (Highly Recommended)

You can later add:

### Diamond Photos

```
diamond_images table
```

---

### Worker Management

```
workers table
```

---

### Profit Report

```
purchase price vs sale price
```

---

# Final Result

You now have a **complete system architecture** for:

💎 Diamond Manufacturing ERP

Includes:

✔ Inventory
✔ Process Tracking
✔ Ledger
✔ Payments
✔ Backup & Restore
✔ Password Login
✔ Desktop UI

---

If you want, I can also give you **3 extremely important things next**:

1️⃣ **Complete Flutter SQLite database helper (ready to paste)**
2️⃣ **Backup + Restore code implementation**
3️⃣ **Advanced Diamond Manufacturing Workflow used in Surat factories** (very powerful system)

These will make your project **10x more professional.**

---

# Windows Setup Installer (.exe)

This project now includes a Windows installer pipeline using Inno Setup.

## Prerequisites

1. Flutter SDK installed and configured for Windows desktop.
2. Inno Setup 6 installed (ISCC compiler).

## Files

- `windows/installer/the_diamond_story.iss` - Inno Setup definition.
- `tool/build_installer.ps1` - One-command release + installer build script.

## Build Installer

Run from project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_installer.ps1
```

Optional custom metadata:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_installer.ps1 -Publisher "TheDiamondStorySetup" -AppName "The Diamond Story"
```

## Output

The generated setup executable is placed in:

`dist/installer`

Example file name:

`TheDiamondStorySetup-1.0.0.exe`
