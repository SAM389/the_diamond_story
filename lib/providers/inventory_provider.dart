import 'package:flutter/material.dart';
import '../models/rough_stone.dart';
import '../models/diamond.dart';
import '../repositories/rough_repository.dart';
import '../repositories/diamond_repository.dart';
import '../repositories/purchase_repository.dart';
import '../core/utils/helpers.dart';

class InventoryProvider extends ChangeNotifier {
  final _roughRepo = RoughRepository();
  final _diamondRepo = DiamondRepository();
  PurchaseRepository? _purchaseRepo;

  PurchaseRepository get purchaseRepo => _purchaseRepo ??= PurchaseRepository();

  List<RoughStone> _roughStones = [];
  List<Diamond> _diamonds = [];
  bool _loading = false;
  String? _error;

  List<RoughStone> get roughStones => _roughStones;
  List<Diamond> get diamonds => _diamonds;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _roughStones = await _roughRepo.getAll();
      _diamonds = await _diamondRepo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadRoughStones() async {
    _roughStones = await _roughRepo.getAll();
    notifyListeners();
  }

  Future<void> loadDiamonds() async {
    _diamonds = await _diamondRepo.getAll();
    notifyListeners();
  }

  Future<String> getNextLotNo() => _roughRepo.nextLotNo();

  Future<bool> addRoughStone(RoughStone stone) async {
    if (stone.supplierId == null) {
      _error = 'Supplier is required.';
      notifyListeners();
      return false;
    }

    int? newLotId;
    try {
      newLotId = await _roughRepo.insert(stone);
      await purchaseRepo.upsertAutoForRoughStone(
        lotId: newLotId,
        partyId: stone.supplierId!,
        amount: stone.purchasePrice,
        date: stone.purchaseDate,
        notes: stone.notes,
      );
      await loadRoughStones();
      return true;
    } catch (e) {
      if (newLotId != null) {
        await _roughRepo.delete(newLotId);
      }
      final msg = e.toString();
      if (msg.contains('UNIQUE constraint failed: rough_stones.lot_no')) {
        _error = 'Lot number already exists. Please choose a different lot number.';
      } else {
        _error = msg;
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRoughStone(RoughStone stone) async {
    if (stone.id == null) {
      _error = 'Rough stone id is missing.';
      notifyListeners();
      return false;
    }
    if (stone.supplierId == null) {
      _error = 'Supplier is required.';
      notifyListeners();
      return false;
    }

    RoughStone? beforeUpdate;
    try {
      beforeUpdate = await _roughRepo.getById(stone.id!);
      await _roughRepo.update(stone);
      await purchaseRepo.upsertAutoForRoughStone(
        lotId: stone.id!,
        partyId: stone.supplierId!,
        amount: stone.purchasePrice,
        date: stone.purchaseDate,
        notes: stone.notes,
      );
      await loadRoughStones();
      return true;
    } catch (e) {
      if (beforeUpdate != null) {
        await _roughRepo.update(beforeUpdate);
      }
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRoughStone(int id) async {
    final existing = await _roughRepo.getById(id);
    try {
      await _roughRepo.delete(id);
      await purchaseRepo.deleteAutoForRoughStoneByLotId(id);
      await loadRoughStones();
      return true;
    } catch (e) {
      if (existing != null) {
        final current = await _roughRepo.getById(id);
        if (current == null) {
          await _roughRepo.insert(existing);
        }
      }
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Split a lot into N diamonds
  Future<bool> splitLot(String lotNo, int count, double totalWeight) async {
    try {
      final existingDiamonds = await _diamondRepo.getByParentLot(lotNo);
      if (existingDiamonds.isNotEmpty) {
        _error = 'Lot $lotNo is already split into diamonds.';
        notifyListeners();
        return false;
      }

      final codes = AppHelpers.splitLot(lotNo, count);
      await _diamondRepo.splitLot(lotNo, codes, totalWeight);
      await loadDiamonds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDiamond(Diamond diamond) async {
    try {
      await _diamondRepo.insert(diamond);
      await loadDiamonds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDiamond(Diamond diamond) async {
    try {
      await _diamondRepo.update(diamond);
      await loadDiamonds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDiamond(int id) async {
    try {
      await _diamondRepo.delete(id);
      await loadDiamonds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final roughCount = await _roughRepo.count();
    final diamondCount = await _diamondRepo.count();
    final roughWeight = await _roughRepo.totalWeight();
    final diamondWeight = await _diamondRepo.totalWeight();
    final rawCount = await _diamondRepo.countByStatus('raw');
    final inProcessCount = await _diamondRepo.countByStatus('in_process');
    final completedCount = await _diamondRepo.countByStatus('completed');
    final soldCount = await _diamondRepo.countByStatus('sold');
    return {
      'roughCount': roughCount,
      'diamondCount': diamondCount,
      'roughWeight': roughWeight,
      'diamondWeight': diamondWeight,
      'rawDiamonds': rawCount,
      'inProcessDiamonds': inProcessCount,
      'completedDiamonds': completedCount,
      'soldDiamonds': soldCount,
    };
  }
}
