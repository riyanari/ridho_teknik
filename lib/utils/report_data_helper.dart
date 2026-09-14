import '../models/servis_model.dart';

class ReportRoomInfo {
  final String roomName;
  final String floorName;

  const ReportRoomInfo({
    required this.roomName,
    required this.floorName,
  });
}

class ReportDataHelper {
  static String firstNonEmpty(
      List<dynamic> values,
      ) {
    for (final value in values) {
      if (value == null || value is Map) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty &&
          text.toLowerCase() != 'null' &&
          text != '-') {
        return text;
      }
    }

    return '';
  }

  static ReportRoomInfo extractRoom(
      Map<String, dynamic> item,
      ) {
    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(item['ac_unit'])
        : <String, dynamic>{};

    Map<String, dynamic> room = {};

    if (ac['room'] is Map) {
      room = Map<String, dynamic>.from(ac['room']);
    } else if (item['room'] is Map) {
      room = Map<String, dynamic>.from(item['room']);
    }

    final roomName = firstNonEmpty([
      room['name'],
      room['nama'],
      ac['room_name'],
      ac['nama_room'],
      item['room_name'],
      item['nama_room'],
    ]);

    dynamic floorRaw =
        room['floor'] ??
            room['lantai'] ??
            ac['floor'] ??
            ac['lantai'] ??
            item['floor'] ??
            item['lantai'];

    String floorName = '';

    if (floorRaw is Map) {
      final floorMap =
      Map<String, dynamic>.from(floorRaw);

      floorName = firstNonEmpty([
        floorMap['name'],
        floorMap['nama'],
      ]);

      if (floorName.isEmpty) {
        final number =
            floorMap['number'] ??
                floorMap['nomor'];

        if (number != null) {
          floorName = 'Lantai $number';
        }
      }
    } else if (floorRaw != null) {
      final value = floorRaw.toString().trim();

      if (value.isNotEmpty &&
          value.toLowerCase() != 'null' &&
          value != '-') {
        floorName =
        value.toLowerCase().contains('lantai')
            ? value
            : 'Lantai $value';
      }
    }

    return ReportRoomInfo(
      roomName: roomName,
      floorName: floorName,
    );
  }

  static String acName(
      Map<String, dynamic> item,
      ) {
    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(item['ac_unit'])
        : <String, dynamic>{};

    return firstNonEmpty([
      ac['name'],
      ac['nama'],
      'AC #${ac['id'] ?? item['ac_unit_id'] ?? '-'}',
    ]);
  }

  static String brand(
      Map<String, dynamic> item,
      ) {
    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(item['ac_unit'])
        : <String, dynamic>{};

    return firstNonEmpty([
      ac['brand'],
      ac['merk'],
    ]);
  }

  static String type(
      Map<String, dynamic> item,
      ) {
    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(item['ac_unit'])
        : <String, dynamic>{};

    return firstNonEmpty([
      ac['type'],
      ac['tipe'],
    ]);
  }

  static String capacity(
      Map<String, dynamic> item,
      ) {
    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(item['ac_unit'])
        : <String, dynamic>{};

    return firstNonEmpty([
      ac['capacity'],
      ac['kapasitas'],
    ]);
  }

  static String technician(
      Map<String, dynamic> item,
      ) {
    if (item['technician'] is! Map) {
      return 'Belum ditugaskan';
    }

    final technician =
    Map<String, dynamic>.from(
      item['technician'],
    );

    final name = firstNonEmpty([
      technician['name'],
      technician['nama'],
    ]);

    return name.isEmpty
        ? 'Belum ditugaskan'
        : name;
  }

  static DateTime? parseDate(
      dynamic value,
      ) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static String formatDate(
      DateTime? date,
      ) {
    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  static String formatDateTime(
      DateTime? date,
      ) {
    if (date == null) return '-';

    return '${formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String effectiveStatus(
      ServisModel servis,
      ) {
    final items = servis.itemsData;

    if (items.isEmpty) {
      return servis.statusDisplay;
    }

    final statuses = items
        .map(
          (e) => (e['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim(),
    )
        .where((e) => e.isNotEmpty)
        .toList();

    if (statuses.isEmpty) {
      return servis.statusDisplay;
    }

    if (statuses.every((e) => e == 'selesai')) {
      return 'Selesai';
    }

    if (statuses.any((e) => e == 'dikerjakan')) {
      return 'Dikerjakan';
    }

    if (statuses.any((e) => e == 'ditugaskan')) {
      return 'Ditugaskan';
    }

    if (statuses.any((e) => e == 'batal')) {
      return 'Dibatalkan';
    }

    return servis.statusDisplay;
  }
}