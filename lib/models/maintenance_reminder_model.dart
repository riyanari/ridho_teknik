import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'user_model.dart';

// ============================================================
// STATUS REMINDER
// ============================================================

enum MaintenanceStatus {
  safe,
  warning,
  urgent,
}

// ============================================================
// MAINTENANCE REMINDER LOCATION
// ============================================================

class MaintenanceReminderLocation {
  final int? locationId;
  final String locationName;

  final int intervalMonths;

  final int acCount;
  final int roomCount;

  /// Jumlah hari sejak AC yang paling lama belum diservis.
  final int? oldestDays;

  /// Tanggal servis AC yang paling lama belum diservis.
  ///
  /// Ini yang menjadi acuan untuk menentukan:
  /// - jadwal servis berikutnya
  /// - remaining days
  /// - status hijau / kuning / merah
  final DateTime? lastServiceDate;

  final List<UserModel> users;

  const MaintenanceReminderLocation({
    required this.locationId,
    required this.locationName,
    required this.intervalMonths,
    required this.acCount,
    required this.roomCount,
    required this.oldestDays,
    required this.lastServiceDate,
    required this.users,
  });

  // ============================================================
  // NEXT SERVICE DATE
  // ============================================================

  DateTime? get nextServiceDate {
    if (lastServiceDate == null) {
      return null;
    }

    return addMonths(
      lastServiceDate!,
      intervalMonths,
    );
  }

  // ============================================================
  // REMAINING DAYS
  // ============================================================

  int? get remainingDays {
    final next = nextServiceDate;

    if (next == null) {
      return null;
    }

    final today = DateUtils.dateOnly(
      DateTime.now(),
    );

    final target = DateUtils.dateOnly(
      next.toLocal(),
    );

    return target
        .difference(today)
        .inDays;
  }

  // ============================================================
  // STATUS
  //
  // HIJAU:
  // > H-30
  //
  // KUNING:
  // H-30 s/d H-8
  //
  // MERAH:
  // H-7, hari H, atau terlambat
  // ============================================================

  MaintenanceStatus get status {
    final remaining = remainingDays;

    if (remaining == null) {
      return MaintenanceStatus.safe;
    }

    if (remaining <= 7) {
      return MaintenanceStatus.urgent;
    }

    if (remaining <= 30) {
      return MaintenanceStatus.warning;
    }

    return MaintenanceStatus.safe;
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color get statusColor {
    switch (status) {
      case MaintenanceStatus.safe:
        return const Color(
          0xFF16A34A,
        );

      case MaintenanceStatus.warning:
        return const Color(
          0xFFF59E0B,
        );

      case MaintenanceStatus.urgent:
        return const Color(
          0xFFEF4444,
        );
    }
  }

  // ============================================================
  // BACKGROUND COLOR
  // ============================================================

  Color get statusBackgroundColor {
    switch (status) {
      case MaintenanceStatus.safe:
        return const Color(
          0xFFF0FDF4,
        );

      case MaintenanceStatus.warning:
        return const Color(
          0xFFFFFBEB,
        );

      case MaintenanceStatus.urgent:
        return const Color(
          0xFFFEF2F2,
        );
    }
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData get statusIcon {
    switch (status) {
      case MaintenanceStatus.safe:
        return Iconsax.tick_circle;

      case MaintenanceStatus.warning:
        return Iconsax.warning_2;

      case MaintenanceStatus.urgent:
        return Iconsax.danger;
    }
  }

  // ============================================================
  // STATUS TITLE
  // ============================================================

  String get statusTitle {
    switch (status) {
      case MaintenanceStatus.safe:
        return 'Aman';

      case MaintenanceStatus.warning:
        return 'Segera';

      case MaintenanceStatus.urgent:
        return 'Mendesak';
    }
  }

  // ============================================================
  // STATUS DESCRIPTION
  // ============================================================

  String get statusDescription {
    switch (status) {
      case MaintenanceStatus.safe:
        return 'Jadwal servis masih lebih dari 1 bulan';

      case MaintenanceStatus.warning:
        return 'Sudah memasuki H-30 jadwal servis';

      case MaintenanceStatus.urgent:
        return 'Sudah memasuki H-7 atau melewati jadwal';
    }
  }

  // ============================================================
  // LAST SERVICE LABEL
  // ============================================================

  String get lastServiceLabel {
    if (lastServiceDate == null) {
      return 'Belum pernah servis';
    }

    return DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(
      lastServiceDate!.toLocal(),
    );
  }

  // ============================================================
  // NEXT SERVICE LABEL
  // ============================================================

  String get nextServiceLabel {
    final next = nextServiceDate;

    if (next == null) {
      return '-';
    }

    return DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(
      next.toLocal(),
    );
  }

  // ============================================================
  // REMAINING LABEL
  // ============================================================

  String get remainingLabel {
    final remaining = remainingDays;

    if (remaining == null) {
      return 'Belum ada riwayat servis';
    }

    if (remaining < 0) {
      return 'Terlambat ${remaining.abs()} hari';
    }

    if (remaining == 0) {
      return 'Jadwal servis hari ini';
    }

    if (remaining <= 7) {
      return 'H-$remaining menuju jadwal servis';
    }

    if (remaining <= 30) {
      return 'H-$remaining menuju jadwal servis';
    }

    return 'Masih $remaining hari menuju jadwal servis';
  }

  // ============================================================
  // ADD MONTHS
  // ============================================================

  static DateTime addMonths(
      DateTime date,
      int months,
      ) {
    final totalMonths =
        (date.year * 12) +
            (date.month - 1) +
            months;

    final targetYear =
        totalMonths ~/ 12;

    final targetMonth =
        (totalMonths % 12) + 1;

    final lastDay =
        DateTime(
          targetYear,
          targetMonth + 1,
          0,
        ).day;

    final targetDay =
    date.day > lastDay
        ? lastDay
        : date.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}