import 'package:flutter/foundation.dart';

import '../models/client_model.dart';
import '../services/client_service.dart';

class ClientProvider with ChangeNotifier {
  final ClientService service;

  ClientProvider({required this.service});

  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;
  Client? _selectedClient;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalClients => _clients.length;
  Client? get selectedClient => _selectedClient;

  bool get hasData => _clients.isNotEmpty;
  bool get hasError => _error != null && _error!.isNotEmpty;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<Client> get topClients {
    final sorted = [..._clients]
      ..sort((a, b) => b.totalService.compareTo(a.totalService));
    return sorted.take(3).toList();
  }

  List<Client> get activeClients {
    return _clients.where((client) => client.totalService > 0).toList();
  }

  List<Client> get newClients {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _clients.where((client) {
      return client.createdAt != null &&
          client.createdAt!.isAfter(thirtyDaysAgo);
    }).toList();
  }

  Future<void> fetchClients() async {
    _error = null;
    _setLoading(true);

    try {
      final result = await service.getClients();
      _clients = result;

      if (result.isEmpty) {
        _error = 'Belum ada data client';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchClients error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchClientDetail(int id) async {
    _error = null;
    _setLoading(true);

    try {
      _selectedClient = await service.getClientDetail(id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('❌ fetchClientDetail error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;

    final q = query.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(q) ||
          client.phone.contains(query) ||
          client.email.toLowerCase().contains(q);
    }).toList();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    notifyListeners();
  }

  void clearSelectedClient() {
    _selectedClient = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _clients = [];
    _selectedClient = null;
    _error = null;
    notifyListeners();
  }
}