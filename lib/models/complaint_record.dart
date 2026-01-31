class ComplaintRecord {
  final String title;     // contoh: "AC tidak dingin"
  final String notes;     // opsional detail
  final DateTime? date;   // opsional tanggal

  const ComplaintRecord({
    required this.title,
    this.notes = '',
    this.date,
  });

  String get type {
    final s = title.toLowerCase();
    if (s.contains('maintenance')) return 'Maintenance';
    if (s.contains('instalasi') || s.contains('pemasangan')) return 'Instalasi';
    if (s.contains('cuci')) return 'Cuci';
    if (s.contains('freon')) return 'Freon';
    if (s.contains('bocor')) return 'Bocor';
    if (s.contains('troubleshoot') || s.contains('error')) return 'Troubleshoot';
    return 'Lainnya';
  }
}
