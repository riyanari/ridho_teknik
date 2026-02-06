// lib/models/schedule_model.dart
import 'package:flutter/material.dart';

enum ScheduleStatus {
  pending,
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum ScheduleType {
  service,
  installation,
  maintenance,
  emergency,
}

class ScheduleModel {
  final String id;
  final String clientId;
  final String locationId;
  final String? acId;
  final String? technicianId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleStatus status;
  final ScheduleType type;
  final String address;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Data relasional
  final Map<String, dynamic>? clientData;
  final Map<String, dynamic>? locationData;
  final Map<String, dynamic>? acData;
  final Map<String, dynamic>? technicianData;

  const ScheduleModel({
    required this.id,
    required this.clientId,
    required this.locationId,
    this.acId,
    this.technicianId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.status = ScheduleStatus.pending,
    this.type = ScheduleType.service,
    required this.address,
    this.notes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.clientData,
    this.locationData,
    this.acData,
    this.technicianData,
  });

  // Helper untuk parsing dari API
  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'].toString(),
      clientId: map['client_id'].toString(),
      locationId: map['location_id'].toString(),
      acId: map['ac_unit_id']?.toString(),
      technicianId: map['technician_id']?.toString(),
      title: map['title']?.toString() ?? 'Tanpa Judul',
      description: map['description']?.toString() ?? '',
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      status: _parseStatus(map['status']?.toString() ?? 'pending'),
      type: _parseType(map['type']?.toString() ?? 'service'),
      address: map['address']?.toString() ?? '',
      notes: map['notes']?.toString(),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      clientData: map['client'],
      locationData: map['location'],
      acData: map['ac'],
      technicianData: map['technician'],
    );
  }

  static ScheduleStatus _parseStatus(String status) {
    switch (status) {
      case 'scheduled': return ScheduleStatus.scheduled;
      case 'in_progress': return ScheduleStatus.inProgress;
      case 'completed': return ScheduleStatus.completed;
      case 'cancelled': return ScheduleStatus.cancelled;
      default: return ScheduleStatus.pending;
    }
  }

  static ScheduleType _parseType(String type) {
    switch (type) {
      case 'installation': return ScheduleType.installation;
      case 'maintenance': return ScheduleType.maintenance;
      case 'emergency': return ScheduleType.emergency;
      default: return ScheduleType.service;
    }
  }

  // Helper methods
  String get statusDisplay {
    switch (status) {
      case ScheduleStatus.pending: return 'Pending';
      case ScheduleStatus.scheduled: return 'Terjadwal';
      case ScheduleStatus.inProgress: return 'Dalam Proses';
      case ScheduleStatus.completed: return 'Selesai';
      case ScheduleStatus.cancelled: return 'Dibatalkan';
    }
  }

  Color get statusColor {
    switch (status) {
      case ScheduleStatus.pending: return Colors.orange;
      case ScheduleStatus.scheduled: return Colors.blue;
      case ScheduleStatus.inProgress: return Colors.purple;
      case ScheduleStatus.completed: return Colors.green;
      case ScheduleStatus.cancelled: return Colors.red;
    }
  }

  String get typeDisplay {
    switch (type) {
      case ScheduleType.service: return 'Service';
      case ScheduleType.installation: return 'Instalasi';
      case ScheduleType.maintenance: return 'Maintenance';
      case ScheduleType.emergency: return 'Emergency';
    }
  }

  Color get typeColor {
    switch (type) {
      case ScheduleType.service: return Colors.blue;
      case ScheduleType.installation: return Colors.green;
      case ScheduleType.maintenance: return Colors.orange;
      case ScheduleType.emergency: return Colors.red;
    }
  }

  String get clientName => clientData?['name']?.toString() ?? 'Unknown';
  String get locationName => locationData?['name']?.toString() ?? 'Unknown';
  String get technicianName => technicianData?['name']?.toString() ?? 'Belum ditugaskan';

  // Durasi jadwal
  Duration get duration => endTime.difference(startTime);

  // Cek apakah jadwal hari ini
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  // Cek apakah jadwal sedang berlangsung
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Cek apakah jadwal akan datang
  bool get isUpcoming => DateTime.now().isBefore(startTime);

  // Cek apakah jadwal sudah lewat
  bool get isPast => DateTime.now().isAfter(endTime);

  // Format waktu
  String get formattedTime =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - '
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  String get formattedDate =>
      '${startTime.day}/${startTime.month}/${startTime.year}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'location_id': locationId,
      'ac_unit_id': acId,
      'technician_id': technicianId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': _convertStatusToApi(status),
      'type': _convertTypeToApi(type),
      'address': address,
      'notes': notes,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  String _convertStatusToApi(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.pending: return 'pending';
      case ScheduleStatus.scheduled: return 'scheduled';
      case ScheduleStatus.inProgress: return 'in_progress';
      case ScheduleStatus.completed: return 'completed';
      case ScheduleStatus.cancelled: return 'cancelled';
    }
  }

  String _convertTypeToApi(ScheduleType type) {
    switch (type) {
      case ScheduleType.service: return 'service';
      case ScheduleType.installation: return 'installation';
      case ScheduleType.maintenance: return 'maintenance';
      case ScheduleType.emergency: return 'emergency';
    }
  }

  ScheduleModel copyWith({
    String? id,
    String? clientId,
    String? locationId,
    String? acId,
    String? technicianId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    ScheduleStatus? status,
    ScheduleType? type,
    String? address,
    String? notes,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? clientData,
    Map<String, dynamic>? locationData,
    Map<String, dynamic>? acData,
    Map<String, dynamic>? technicianData,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      locationId: locationId ?? this.locationId,
      acId: acId ?? this.acId,
      technicianId: technicianId ?? this.technicianId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      type: type ?? this.type,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientData: clientData ?? this.clientData,
      locationData: locationData ?? this.locationData,
      acData: acData ?? this.acData,
      technicianData: technicianData ?? this.technicianData,
    );
  }
}