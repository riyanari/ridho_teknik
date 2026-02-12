// lib/utils/photo_url_helper.dart
import 'dart:convert';

/// GANTI sesuai domain backend kamu (tanpa trailing slash)
const String kApiBaseUrl = 'https://cvrt.thepride.id';

/// Convert value dari DB/API (null / list / json string / string tunggal)
/// menjadi list PATH (bukan URL).
List<String> asPhotoPaths(dynamic v) {
  List<String> paths = [];

  if (v == null) {
    paths = [];
  } else if (v is List) {
    paths = v.map((e) => e.toString()).toList();
  } else if (v is String) {
    final s = v.trim();
    if (s.isEmpty) {
      paths = [];
    } else if (s.startsWith('[')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) {
          paths = decoded.map((e) => e.toString()).toList();
        } else {
          paths = [s];
        }
      } catch (_) {
        paths = [s];
      }
    } else {
      paths = [s];
    }
  } else {
    paths = [v.toString()];
  }

  return paths.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

/// Bangun URL API media untuk 1 foto berdasarkan itemId, type, dan index.
/// (kita ignore isi PATH-nya, karena API pakai index `i`)
String serviceItemPhotoUrl({
  required int itemId,
  required String type, // sebelum|pengerjaan|sesudah|suku_cadang
  required int index,
}) {
  final t = type.toLowerCase();
  return '$kApiBaseUrl/api/media/service-item/$itemId/photo?type=$t&i=$index';
}

/// Dari field foto (list/json string) -> list URL yang siap dipakai Image.network,
/// dengan strategi: URL diambil dari API media pakai index `i`.
List<String> asServiceItemPhotoUrls({
  required int itemId,
  required String type,
  required dynamic valueFromApi,
}) {
  final paths = asPhotoPaths(valueFromApi);
  // jumlah foto = panjang list paths di DB
  return List.generate(
    paths.length,
        (i) => serviceItemPhotoUrl(itemId: itemId, type: type, index: i),
  );
}
