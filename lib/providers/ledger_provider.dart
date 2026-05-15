import 'package:flutter/material.dart';
import '../models/party.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/payment.dart';
import '../models/expense_category.dart';
import '../repositories/party_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/payment_repository.dart';

class LedgerProvider extends ChangeNotifier {
  final _partyRepo = PartyRepository();
  final _purchaseRepo = PurchaseRepository();
  final _saleRepo = SaleRepository();
  final _paymentRepo = PaymentRepository();

  List<Party> _parties = [];
  List<Purchase> _purchases = [];
  List<Sale> _sales = [];
  List<Payment> _payments = [];
  List<ExpenseCategory> _expenseCategories = [];
  bool _loading = false;
  String? _error;

  List<Party> get parties => _parties;
  List<Purchase> get purchases => _purchases;
  List<Sale> get sales => _sales;
  List<Payment> get payments => _payments;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([
        _partyRepo.getAll().then((v) => _parties = v),
        _purchaseRepo.getAll().then((v) => _purchases = v),
        _saleRepo.getAll().then((v) => _sales = v),
        _paymentRepo.getAll().then((v) => _payments = v),
        _paymentRepo.getAllCategories().then((v) => _expenseCategories = v),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- Parties ---
  Future<bool> addParty(Party party) async {
    try {
      await _partyRepo.insert(party);
      _parties = await _partyRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateParty(Party party) async {
    try {
      await _partyRepo.update(party);
      _parties = await _partyRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteParty(int id) async {
    try {
      await _partyRepo.delete(id);
      _parties = await _partyRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Purchases ---
  Future<bool> addPurchase(Purchase purchase) async {
    _error = 'Purchases are auto-generated from Rough Stones. Please add a Rough Stone instead.';
    notifyListeners();
    return false;
  }

  Future<bool> deletePurchase(int id) async {
    _error = 'Purchase entries are managed from Rough Stones and cannot be deleted here.';
    notifyListeners();
    return false;
  }

  // --- Sales ---
  Future<bool> addSale(Sale sale) async {
    try {
      await _saleRepo.insert(sale);
      _sales = await _saleRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSale(Sale sale) async {
    try {
      await _saleRepo.update(sale);
      _sales = await _saleRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(int id) async {
    try {
      await _saleRepo.delete(id);
      _sales = await _saleRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreSale(int id) async {
    try {
      await _saleRepo.restore(id);
      _sales = await _saleRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> hardDeleteSale(int id) async {
    try {
      await _saleRepo.hardDelete(id);
      _sales = await _saleRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Payments ---
  Future<bool> addPayment(Payment payment) async {
    try {
      await _paymentRepo.insert(payment);
      _payments = await _paymentRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePayment(Payment payment) async {
    try {
      await _paymentRepo.update(payment);
      _payments = await _paymentRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayment(int id) async {
    try {
      await _paymentRepo.delete(id);
      _payments = await _paymentRepo.getAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Expense Categories ---
  Future<bool> addExpenseCategory(String name) async {
    try {
      await _paymentRepo.insertCategory(
        ExpenseCategory(name: name, createdAt: DateTime.now().toIso8601String()),
      );
      _expenseCategories = await _paymentRepo.getAllCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpenseCategory(int id) async {
    try {
      await _paymentRepo.deleteCategory(id);
      _expenseCategories = await _paymentRepo.getAllCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, double>> getDashboardStats() async {
    final totalPurchases = await _purchaseRepo.totalAmount();
    final totalRevenue = await _saleRepo.totalRevenue();
    final paymentTotals = await _paymentRepo.totals();
    final salesCount = await _saleRepo.countSales();
    final pendingPaymentTotal = await _paymentRepo.pendingTotal();
    return {
      'totalPurchases': totalPurchases,
      'totalRevenue': totalRevenue,
      'totalPaid': paymentTotals['paid'] ?? 0.0,
      'totalReceived': paymentTotals['received'] ?? 0.0,
      'profit': totalRevenue - totalPurchases,
      'salesCount': salesCount.toDouble(),
      'pendingPaymentTotal': pendingPaymentTotal,
    };
  }

  Future<List<Payment>> getPendingPayments() => _paymentRepo.getPending();

  Future<List<Payment>> getRecentPayments(int limit) =>
      _paymentRepo.getRecentCompleted(limit);

    Future<List<Map<String, dynamic>>> getMonthlySales(int months) =>
      _saleRepo.monthlySales(months);
}
