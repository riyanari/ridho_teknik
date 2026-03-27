import 'package:flutter/foundation.dart';
import '../models/technician_model.dart';
import '../services/technician_service.dart';

class TechnicianProvider with ChangeNotifier {
  final TechnicianService service;

  TechnicianProvider({required this.service});

  List<Technician> _technicians = [];
  bool _isLoading = false;
  String? _error;
  Technician? _selectedTechnician;

  // ===== GETTERS =====
  List<Technician> get technicians => _technicians;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalTechnicians => _technicians.length;
  Technician? get selectedTechnician => _selectedTechnician;

  // ===== FILTERS =====

  List<Technician> get activeTechnicians =>
      _technicians.where((e) => e.status == 'aktif').toList();

  List<Technician> get topTechnicians =>
      _technicians.where((e) => e.rating >= 4.5).toList();

  List<Technician> get topTechniciansForHome {
    final sorted = [...activeTechnicians]
      ..sort((a, b) {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.totalService.compareTo(a.totalService);
      });
    return sorted.take(3).toList();
  }

  List<Technician> getTechniciansBySpecialization(String specialization) {
    return _technicians
        .where((e) =>
    e.spesialisasi.toLowerCase() ==
        specialization.toLowerCase())
        .toList();
  }

  // ===== FETCH =====

  Future<void> fetchTechnicians() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await service.getTechnicians();
      _technicians = result;

      if (result.isEmpty) {
        _error = 'Belum ada data teknisi';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ fetchTechnicians error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== SEARCH =====

  List<Technician> searchTechnicians(String query) {
    if (query.isEmpty) return _technicians;

    final q = query.toLowerCase();

    return _technicians.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.phone.contains(query) ||
          e.email.toLowerCase().contains(q) ||
          e.spesialisasi.toLowerCase().contains(q);
    }).toList();
  }

  // ===== STATE =====

  void selectTechnician(Technician tech) {
    _selectedTechnician = tech;
    notifyListeners();
  }

  void clearSelectedTechnician() {
    _selectedTechnician = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}