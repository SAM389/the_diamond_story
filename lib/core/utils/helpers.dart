import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  /// Hash a password with SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Verify a password against its hash
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Generate lot number like LOT-001, LOT-002 from an index
  static String generateLotNo(int index) {
    return 'LOT-${index.toString().padLeft(3, '0')}';
  }

  /// Split a lot into diamond codes: LOT-001 → LOT-001A, LOT-001B...
  static List<String> splitLot(String lotNumber, int count) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return List.generate(
      count,
      (i) => '$lotNumber${letters[i % letters.length]}',
    );
  }

  /// Format currency
  static String formatCurrency(double amount) {
    final f = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${f.format(amount)}';
  }

  /// Format weight in carats
  static String formatWeight(double weight) {
    return '${weight.toStringAsFixed(3)} ct';
  }

  /// Format a DateTime as yyyy-MM-dd.
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Parse yyyy-MM-dd text with a fallback date.
  static DateTime parseDate(String? date, {DateTime? fallback}) {
    final fallbackDate = fallback ?? DateTime.now();
    if (date == null || date.isEmpty) return fallbackDate;
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(date);
    } catch (_) {
      return fallbackDate;
    }
  }

  /// Today as yyyy-MM-dd string
  static String today() => formatDate(DateTime.now());

  /// Readable date display
  static String displayDate(String? date) {
    if (date == null || date.isEmpty) return '—';
    try {
      final d = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return date;
    }
  }

  /// Status badge label
  static String statusLabel(String status) {
    switch (status) {
      case 'raw': return 'Raw';
      case 'in_process': return 'In Process';
      case 'completed': return 'Completed';
      case 'sold': return 'Sold';
      case 'pending': return 'Pending';
      default: return status;
    }
  }
}
