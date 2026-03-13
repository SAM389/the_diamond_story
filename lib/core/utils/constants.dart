import 'package:intl/intl.dart';

class AppConstants {
  // App info
  static const String appName = 'Diamond Story ERP';
  static const String appVersion = '1.0.0';

  // Status values
  static const String statusRaw = 'raw';
  static const String statusInProcess = 'in_process';
  static const String statusCompleted = 'completed';
  static const String statusSold = 'sold';

  static const String processPending = 'pending';
  static const String processCompleted = 'completed';

  static const String paymentPaid = 'paid';
  static const String paymentReceived = 'received';

  static const String partySupplier = 'supplier';
  static const String partyCustomer = 'customer';
  static const String partyWorker = 'worker';

  // Backup
  static const String backupExtension = '.dbackup';

  // Colors
  static const int primaryColorValue = 0xFF1A237E;
  static const int accentColorValue = 0xFF283593;
  static const int successColorValue = 0xFF2E7D32;
  static const int warningColorValue = 0xFFF57F17;
  static const int errorColorValue = 0xFFC62828;

  // Currency format
  static final NumberFormat currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat weightFormat = NumberFormat('#,##0.000');
  static final DateFormat dateDisplay = DateFormat('dd MMM yyyy');
  static final DateFormat dateInput = DateFormat('yyyy-MM-dd');
}
