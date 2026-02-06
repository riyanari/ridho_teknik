import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';

class ClientProvider with ChangeNotifier {
  final ClientService service;

  List<Client> _clients = [];
  bool _isLoading = false;
  String _error = '';
  Client? _selectedClient;

  ClientProvider({required this.service});

  // Getters
  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalClients => _clients.length;
  Client? get selectedClient => _selectedClient;

  // Get top 3 clients for home page display
  List<Client> get topClients {
    // Sort by total service or rating
    final sorted = List<Client>.from(_clients)
      ..sort((a, b) => b.totalService.compareTo(a.totalService));
    return sorted.take(3).toList();
  }

  // Get active clients (with recent service)
  List<Client> get activeClients {
    return _clients.where((client) => client.totalService > 0).toList();
  }

  // Get new clients (created within last 30 days)
  List<Client> get newClients {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _clients.where((client) {
      return client.createdAt != null && client.createdAt!.isAfter(thirtyDaysAgo);
    }).toList();
  }

  // Fetch all clients
  Future<void> fetchClients() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _clients = await service.getClients();

      if (_clients.isEmpty) {
        _error = 'Belum ada data client';
      }
    } catch (e) {
      _error = 'Gagal mengambil data client: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching clients: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single client detail
  Future<void> fetchClientDetail(int id) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _selectedClient = await service.getClientDetail(id);
    } catch (e) {
      _error = 'Gagal mengambil detail client: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching client detail: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search clients by name or phone
  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;

    final lowercaseQuery = query.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(lowercaseQuery) ||
          client.phone.contains(query) ||
          client.email.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Clear selected client
  void clearSelectedClient() {
    _selectedClient = null;
    notifyListeners();
  }
}