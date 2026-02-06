import 'package:flutter/foundation.dart';
import '../models/technician_model.dart';
import '../services/technician_service.dart';

class TechnicianProvider with ChangeNotifier {
  final TechnicianService service;

  List<Technician> _technicians = [];
  bool _isLoading = false;
  String _error = '';
  Technician? _selectedTechnician;

  TechnicianProvider({required this.service});

  // Getters
  List<Technician> get technicians => _technicians;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalTechnicians => _technicians.length;
  Technician? get selectedTechnician => _selectedTechnician;

  // Get active technicians
  List<Technician> get activeTechnicians {
    return _technicians.where((tech) => tech.status == 'aktif').toList();
  }

  // Get top technicians by rating
  List<Technician> get topTechnicians {
    return _technicians.where((tech) => tech.rating >= 4.5).toList();
  }

  // Get top 3 technicians for home page display
  List<Technician> get topTechniciansForHome {
    // Sort by rating and total service
    final sorted = List<Technician>.from(activeTechnicians)
      ..sort((a, b) {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.totalService.compareTo(a.totalService);
      });
    return sorted.take(3).toList();
  }

  // Get technicians by specialization
  List<Technician> getTechniciansBySpecialization(String specialization) {
    return _technicians
        .where((tech) => tech.spesialisasi.toLowerCase() == specialization.toLowerCase())
        .toList();
  }

  // Fetch all technicians
  Future<void> fetchTechnicians() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _technicians = await service.getTechnicians();

      if (_technicians.isEmpty) {
        _error = 'Belum ada data teknisi';
      }
    } catch (e) {
      _error = 'Gagal mengambil data teknisi: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching technicians: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single technician detail
  // Future<void> fetchTechnicianDetail(int id) async {
  //   try {
  //     _isLoading = true;
  //     _error = '';
  //     notifyListeners();
  //
  //     _selectedTechnician = await service.getTechnicianDetail(id);
  //   } catch (e) {
  //     _error = 'Gagal mengambil detail teknisi: ${e.toString()}';
  //     if (kDebugMode) {
  //       print('Error fetching technician detail: $e');
  //     }
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Search technicians by name, phone, or specialization
  List<Technician> searchTechnicians(String query) {
    if (query.isEmpty) return _technicians;

    final lowercaseQuery = query.toLowerCase();
    return _technicians.where((tech) {
      return tech.name.toLowerCase().contains(lowercaseQuery) ||
          tech.phone.contains(query) ||
          tech.email.toLowerCase().contains(lowercaseQuery) ||
          tech.spesialisasi.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Clear selected technician
  void clearSelectedTechnician() {
    _selectedTechnician = null;
    notifyListeners();
  }
}