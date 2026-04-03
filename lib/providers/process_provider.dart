import 'package:flutter/material.dart';
import '../models/process.dart';
import '../models/process_type.dart';
import '../repositories/process_repository.dart';

class ProcessProvider extends ChangeNotifier {
  final _repo = ProcessRepository();

  List<Process> _processes = [];
  List<ProcessType> _processTypes = [];
  bool _loading = false;
  String? _error;

  List<Process> get processes => _processes;
  List<ProcessType> get processTypes => _processTypes;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _processes = await _repo.getAll();
      _processTypes = await _repo.getAllTypes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadProcessTypes() async {
    _processTypes = await _repo.getAllTypes();
    notifyListeners();
  }

  Future<bool> addProcess(Process process) async {
    try {
      await _repo.insert(process);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProcess(Process process) async {
    try {
      await _repo.update(process);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeProcess(int processId, String toDate) async {
    try {
      await _repo.complete(processId, toDate);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProcess(int id) async {
    try {
      await _repo.delete(id);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addProcessType(String name, {double cost = 0}) async {
    try {
      await _repo.insertType(
        ProcessType(
          name: name,
          cost: cost,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      await loadProcessTypes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProcessType(int id) async {
    try {
      await _repo.deleteType(id);
      await loadProcessTypes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> getPendingCount() => _repo.countPending();

  Future<int> getCompletedCount() => _repo.countCompleted();

  Future<List<Map<String, dynamic>>> getStageBreakdown() => _repo.countByType();

  Future<double> getTotalProcessFees() => _repo.totalFees();

  Future<List<Process>> getRecentActivity(int limit) => _repo.getRecent(limit);

  Future<List<Process>> getOverdueProcesses() => _repo.getOverdue();
}
