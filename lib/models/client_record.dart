import 'complaint_record.dart';

class ClientRecord {
  final String name;
  final String address;
  final String whatsapp;
  final String mapsQuery;                 // koordinat "lat,lng" atau kata kunci alamat
  final List<ComplaintRecord> complaints; // bisa banyak keluhan

  const ClientRecord({
    required this.name,
    required this.address,
    required this.whatsapp,
    required this.mapsQuery,
    required this.complaints,
  });

  // Pencarian menyentuh nama, alamat, WA, dan judul/notes keluhan
  bool matchesQuery(String q) {
    if (q.isEmpty) return true;
    final lq = q.toLowerCase();
    final inClient = name.toLowerCase().contains(lq) ||
        address.toLowerCase().contains(lq) ||
        whatsapp.toLowerCase().contains(lq);
    final inComplaints = complaints.any(
          (c) => c.title.toLowerCase().contains(lq) || c.notes.toLowerCase().contains(lq),
    );
    return inClient || inComplaints;
  }

  // Filter berdasarkan tipe keluhan
  bool matchesFilter(String filter) {
    if (filter == 'Semua') return true;
    return complaints.any((c) => c.type == filter);
  }
}
