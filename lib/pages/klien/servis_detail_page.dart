// lib/pages/klien/servis_detail_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/servis_model.dart';
import '../../services/reports/service_report_pdf.dart';
import '../../theme/theme.dart';
import 'servis_item_ac_detail_page.dart';

class ServisDetailPage extends StatelessWidget {
  final ServisModel servis;

  const ServisDetailPage({
    super.key,
    required this.servis,
  });

  // ============================================================
  // EFFECTIVE STATUS
  // ============================================================

  ServisStatus get _effectiveStatus {
    final items = servis.itemsData;

    if (items.isEmpty) {
      return servis.status;
    }

    final statuses = items
        .map(
          (item) => (item['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim(),
    )
        .where((status) => status.isNotEmpty)
        .toList();

    if (statuses.isEmpty) {
      return servis.status;
    }

    if (statuses.every((status) => status == 'selesai')) {
      return ServisStatus.selesai;
    }

    if (statuses.any((status) => status == 'dikerjakan')) {
      return ServisStatus.dikerjakan;
    }

    if (statuses.any((status) => status == 'ditugaskan')) {
      return ServisStatus.ditugaskan;
    }

    if (statuses.any((status) => status == 'batal')) {
      return ServisStatus.batal;
    }

    return servis.status;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildStatusOverview(),

                  const SizedBox(height: 18),

                  _buildServiceInformation(),

                  if ((servis.keluhanClient ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildComplaintSection(),
                  ],

                  if (servis.itemsData.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildAcSection(context),
                  ],

                  if (_shouldShowGeneralWorkSection) ...[
                    const SizedBox(height: 20),
                    _buildGeneralWorkSection(),
                  ],

                  if (_effectiveStatus == ServisStatus.selesai) ...[
                    const SizedBox(height: 20),
                    _buildCostSection(context),
                  ],

                  if (_hasGeneralPhotos) ...[
                    const SizedBox(height: 20),
                    _buildPhotoSection(context),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(
      BuildContext context,
      ) {
    final status = _effectiveStatus;
    final statusColor = _statusColor(status);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 190,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 8,
          ),
          child: Material(
            color: Colors.white.withValues(
              alpha: 0.16,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                _showReportMenu(context);
              },
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPrimaryColor,
                const Color(0xFF6372D0),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -55,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.045),
                  ),
                ),
              ),

              Positioned(
                left: -45,
                bottom: -70,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    58,
                    20,
                    18,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildHeaderBadge(
                            icon: _jenisIcon(servis.jenis),
                            label: servis.jenisDisplay,
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(status),
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statusText(status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        servis.lokasiNama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _lokasiAlamat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS OVERVIEW
  // ============================================================

  Widget _buildStatusOverview() {
    final status = _effectiveStatus;
    final statusColor = _statusColor(status);

    final title = switch (status) {
      ServisStatus.menungguKonfirmasi => 'Menunggu Konfirmasi',
      ServisStatus.ditugaskan => 'Teknisi Sudah Ditugaskan',
      ServisStatus.dikerjakan => 'Servis Sedang Dikerjakan',
      ServisStatus.selesai => 'Servis Telah Selesai',
      ServisStatus.batal => 'Servis Dibatalkan',
    };

    final subtitle = switch (status) {
      ServisStatus.menungguKonfirmasi =>
      'Permintaan sedang menunggu konfirmasi dari Ridho Teknik.',
      ServisStatus.ditugaskan =>
      'Teknisi telah ditentukan dan akan menangani pekerjaan ini.',
      ServisStatus.dikerjakan =>
      'Teknisi sedang melakukan pengerjaan pada unit AC.',
      ServisStatus.selesai =>
      _durationDisplay != null
          ? 'Pengerjaan selesai dalam ${_durationDisplay!}.'
          : 'Seluruh pekerjaan pada servis ini telah selesai.',
      ServisStatus.batal =>
      'Permintaan servis ini telah dibatalkan.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _statusIcon(status),
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: primaryTextStyle.copyWith(
                    fontSize: 13.5,
                    fontWeight: bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: greyTextStyle.copyWith(
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICE INFORMATION
  // ============================================================

  Widget _buildServiceInformation() {
    final totalUnits = servis.itemsData.isNotEmpty
        ? servis.itemsData.length
        : servis.jumlahAc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.info_outline_rounded,
          title: 'Informasi Servis',
          subtitle: 'Ringkasan pekerjaan dan jadwal',
          color: kPrimaryColor,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.ac_unit_rounded,
                      label: 'Jumlah AC',
                      value: '$totalUnits unit',
                      color: kPrimaryColor,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.person_outline_rounded,
                      label: 'Teknisi',
                      value: _teknisiDisplay,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.calendar_month_rounded,
                      label: 'Jadwal Kunjungan',
                      value: _formatDate(
                        servis.tanggalBerkunjung ??
                            servis.tanggalDitugaskan,
                      ),
                      color: Colors.purple,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.access_time_rounded,
                      label: 'Waktu',
                      value: _formatTime(
                        servis.tanggalBerkunjung ??
                            servis.tanggalDitugaskan,
                      ),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              if ((servis.noInvoice ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),

                Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.10),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No. Invoice',
                      style: greyTextStyle.copyWith(
                        fontSize: 9.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      servis.noInvoice!,
                      style: primaryTextStyle.copyWith(
                        fontSize: 10.5,
                        fontWeight: bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: greyTextStyle.copyWith(
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: primaryTextStyle.copyWith(
                    fontSize: 10,
                    fontWeight: bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLAINT
  // ============================================================

  Widget _buildComplaintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.report_problem_outlined,
          title: 'Keluhan Awal',
          subtitle: 'Keluhan yang disampaikan saat pengajuan',
          color: Colors.orange,
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            (servis.keluhanClient ?? '').trim(),
            style: primaryTextStyle.copyWith(
              fontSize: 11,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AC SECTION
  // ============================================================

  Widget _buildAcSection(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.ac_unit_rounded,
          title: 'Unit AC',
          subtitle:
          '${servis.itemsData.length} unit dalam pekerjaan ini',
          color: kPrimaryColor,
        ),

        const SizedBox(height: 12),

        ...List.generate(
          servis.itemsData.length,
              (index) {
            final item = servis.itemsData[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == servis.itemsData.length - 1
                    ? 0
                    : 10,
              ),
              child: _buildAcItem(
                context,
                item,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAcItem(
      BuildContext context,
      Map<String, dynamic> item,
      ) {
    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(
      item['ac_unit'],
    )
        : <String, dynamic>{};

    final room = _extractRoom(ac, item);

    final roomName = room.name;
    final floor = room.floor;

    final acName = _firstNonEmpty([
      ac['name'],
      ac['nama'],
      'AC #${ac['id'] ?? item['ac_unit_id'] ?? '-'}',
    ]);

    final brand = _firstNonEmpty([
      ac['brand'],
      ac['merk'],
    ]);

    final type = _firstNonEmpty([
      ac['type'],
      ac['tipe'],
    ]);

    final capacity = _firstNonEmpty([
      ac['capacity'],
      ac['kapasitas'],
    ]);

    final status = (item['status'] ?? '').toString();

    final technician =
    item['technician'] is Map
        ? Map<String, dynamic>.from(
      item['technician'],
    )
        : <String, dynamic>{};

    final technicianName = _firstNonEmpty([
      technician['name'],
      technician['nama'],
    ]);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServisItemAcDetailPage(
                servisId: servis.id.toString(),
                item: item,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.022),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      size: 20,
                      color: kPrimaryColor,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // ROOM NAME PRIORITAS
                        // ==================================================

                        Text(
                          roomName.isNotEmpty
                              ? roomName
                              : acName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: primaryTextStyle.copyWith(
                            fontSize: 13.5,
                            fontWeight: bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Row(
                          children: [
                            if (floor.isNotEmpty) ...[
                              _buildTinyChip(
                                icon: Icons.layers_outlined,
                                label: floor,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                            ],

                            if (roomName.isNotEmpty)
                              Expanded(
                                child: Text(
                                  acName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _itemStatusColor(status).withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getItemStatusDisplay(status),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: _itemStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 11),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildAcMeta(
                            label: 'Merek',
                            value: brand.isEmpty ? '-' : brand,
                          ),
                        ),

                        Expanded(
                          child: _buildAcMeta(
                            label: 'Kapasitas',
                            value:
                            capacity.isEmpty ? '-' : capacity,
                          ),
                        ),
                      ],
                    ),

                    if (type.isNotEmpty ||
                        technicianName.isNotEmpty) ...[
                      const SizedBox(height: 9),

                      Row(
                        children: [
                          Expanded(
                            child: _buildAcMeta(
                              label: 'Tipe',
                              value:
                              type.isEmpty ? '-' : type,
                            ),
                          ),

                          Expanded(
                            child: _buildAcMeta(
                              label: 'Teknisi',
                              value: technicianName.isEmpty
                                  ? 'Belum ditugaskan'
                                  : technicianName,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Lihat detail pengerjaan unit',
                    style: greyTextStyle.copyWith(
                      fontSize: 8.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: kPrimaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcMeta({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: greyTextStyle.copyWith(
            fontSize: 7.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: primaryTextStyle.copyWith(
            fontSize: 9.5,
            fontWeight: medium,
          ),
        ),
      ],
    );
  }

  Widget _buildTinyChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROOM PARSER
  // ============================================================

  _RoomInfo _extractRoom(
      Map<String, dynamic> ac,
      Map<String, dynamic> item,
      ) {
    Map<String, dynamic> room = {};

    if (ac['room'] is Map) {
      room = Map<String, dynamic>.from(
        ac['room'],
      );
    } else if (item['room'] is Map) {
      room = Map<String, dynamic>.from(
        item['room'],
      );
    }

    final roomName = _firstNonEmpty([
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
      Map<String, dynamic>.from(
        floorRaw,
      );

      floorName = _firstNonEmpty([
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
      final value =
      floorRaw.toString().trim();

      if (value.isNotEmpty &&
          value.toLowerCase() != 'null' &&
          value != '-') {
        floorName =
        value.toLowerCase().contains(
          'lantai',
        )
            ? value
            : 'Lantai $value';
      }
    }

    return _RoomInfo(
      name: roomName,
      floor: floorName,
    );
  }

  // ============================================================
  // GENERAL WORK
  // ============================================================

  bool get _shouldShowGeneralWorkSection {
    return _tindakanList.isNotEmpty ||
        (servis.diagnosa ?? '').trim().isNotEmpty;
  }

  Widget _buildGeneralWorkSection() {
    final diagnosis = (servis.diagnosa ?? '').trim();
    final actions = _tindakanList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.handyman_outlined,
          title: 'Ringkasan Pengerjaan',
          subtitle: 'Informasi umum dari pekerjaan servis',
          color: Colors.purple,
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (diagnosis.isNotEmpty) ...[
                Text(
                  'Diagnosa',
                  style: primaryTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    diagnosis,
                    style: primaryTextStyle.copyWith(
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              if (diagnosis.isNotEmpty &&
                  actions.isNotEmpty)
                const SizedBox(height: 14),

              if (actions.isNotEmpty) ...[
                Text(
                  'Tindakan',
                  style: primaryTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: actions.map(
                        (action) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(
                            alpha: 0.07,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          action,
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COST
  // ============================================================

  Widget _buildCostSection(
      BuildContext context,
      ) {
    final noCost = servis.totalBiaya <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.receipt_long_rounded,
          title: 'Pembayaran',
          subtitle: 'Rincian biaya dan metode pembayaran',
          color: Colors.green,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              if (!noCost) ...[
                _buildCostRow(
                  label: 'Biaya Servis',
                  value: _formatRupiah(
                    servis.biayaServis,
                  ),
                ),

                const SizedBox(height: 11),

                Divider(
                  height: 1,
                  color: Colors.grey.withValues(
                    alpha: 0.10,
                  ),
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total Pembayaran',
                        style: primaryTextStyle.copyWith(
                          fontSize: 12,
                          fontWeight: bold,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatRupiah(
                          servis.totalBiaya,
                        ),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Biaya servis belum ditentukan oleh Ridho Teknik.',
                          style: primaryTextStyle.copyWith(
                            fontSize: 9.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              _buildQrisCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          Icons.build_outlined,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: greyTextStyle.copyWith(
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: 11,
            fontWeight: bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQrisCard(
      BuildContext context,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0066B3).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0066B3).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066B3),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bayar dengan QRIS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ridho Teknik Official',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/qris_cvrt.jpeg',
              width: 190,
              height: 190,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 190,
                  height: 190,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _saveQrisImage(
                        context,
                      ),
                  icon: const Icon(
                    Icons.download_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'Simpan',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(
                      0xFF0066B3,
                    ),
                    side: const BorderSide(
                      color: Color(
                        0xFF0066B3,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _sharePaymentInfo(
                        context,
                      ),
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'Bagikan',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF0066B3,
                    ),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERAL PHOTOS
  // ============================================================

  bool get _hasGeneralPhotos {
    return servis.fotoSebelum.isNotEmpty ||
        servis.fotoPengerjaan.isNotEmpty ||
        servis.fotoSesudah.isNotEmpty ||
        servis.fotoSukuCadang.isNotEmpty;
  }

  Widget _buildPhotoSection(
      BuildContext context,
      ) {
    final categories = [
      if (servis.fotoSebelum.isNotEmpty)
        _FotoCategory(
          title: 'Sebelum',
          photos: servis.fotoSebelum,
        ),
      if (servis.fotoPengerjaan.isNotEmpty)
        _FotoCategory(
          title: 'Proses',
          photos: servis.fotoPengerjaan,
        ),
      if (servis.fotoSesudah.isNotEmpty)
        _FotoCategory(
          title: 'Sesudah',
          photos: servis.fotoSesudah,
        ),
      if (servis.fotoSukuCadang.isNotEmpty)
        _FotoCategory(
          title: 'Suku Cadang',
          photos: servis.fotoSukuCadang,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.photo_library_outlined,
          title: 'Dokumentasi',
          subtitle: 'Dokumentasi umum pekerjaan',
          color: Colors.blue,
        ),

        const SizedBox(height: 12),

        ...List.generate(
          categories.length,
              (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == categories.length - 1
                    ? 0
                    : 12,
              ),
              child: _buildPhotoCategory(
                context,
                categories[index],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoCategory(
      BuildContext context,
      _FotoCategory category,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Foto ${category.title}',
                style: primaryTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: bold,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${category.photos.length}',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemCount: category.photos.length > 6
                ? 6
                : category.photos.length,
            itemBuilder: (context, index) {
              if (index == 5 &&
                  category.photos.length > 6) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '+${category.photos.length - 5}',
                      style: primaryTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: bold,
                      ),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () =>
                    _showPhotoDialog(
                      context,
                      category.photos[index],
                    ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    category.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(
      BuildContext context,
      String url,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Colors.black,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  child: IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: greyTextStyle.copyWith(
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.grey.withValues(alpha: 0.07),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.022),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT ACTION
  // ============================================================

  Future<void> _saveQrisImage(
      BuildContext context,
      ) async {
    try {
      final byteData =
      await rootBundle.load(
        'assets/qris_cvrt.jpeg',
      );

      final Uint8List bytes =
      byteData.buffer.asUint8List();

      final result =
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'qris_ridho_teknik',
      );

      final success =
          result['isSuccess'] == true;

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'QRIS berhasil disimpan ke galeri.'
                : 'QRIS gagal disimpan.',
          ),
          backgroundColor:
          success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan QRIS: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sharePaymentInfo(
      BuildContext context,
      ) async {
    try {
      final byteData =
      await rootBundle.load(
        'assets/qris_cvrt.jpeg',
      );

      final bytes =
      byteData.buffer.asUint8List();

      final directory =
      await getTemporaryDirectory();

      final file = File(
        '${directory.path}/qris_ridho_teknik.jpeg',
      );

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      final text =
      servis.totalBiaya > 0
          ? 'Pembayaran Ridho Teknik\n'
          'Total: ${_formatRupiah(servis.totalBiaya)}\n'
          'Silakan scan QRIS.'
          : 'QRIS Ridho Teknik.\n'
          'Biaya servis belum ditentukan.';

      await Share.shareXFiles(
        [
          XFile(
            file.path,
          ),
        ],
        text: text,
        subject:
        'Pembayaran QRIS Ridho Teknik',
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membagikan QRIS: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
// REPORT
// ============================================================

  void _showReportMenu(
      BuildContext context,
      ) {
    final totalUnits = servis.itemsData.isNotEmpty
        ? servis.itemsData.length
        : servis.jumlahAc;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Laporan Servis',
                style: primaryTextStyle.copyWith(
                  fontSize: 17,
                  fontWeight: bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Buat laporan seluruh pekerjaan pada pengajuan ini.',
                textAlign: TextAlign.center,
                style: greyTextStyle.copyWith(
                  fontSize: 10,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 18),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    try {
                      await ServiceReportPdf.preview(
                        servis: servis,
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal membuat laporan: $e',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laporan PDF',
                                style: primaryTextStyle.copyWith(
                                  fontSize: 12,
                                  fontWeight: bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$totalUnits unit AC dalam pengajuan',
                                style: greyTextStyle.copyWith(
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return 'Menunggu';

      case ServisStatus.ditugaskan:
        return 'Ditugaskan';

      case ServisStatus.dikerjakan:
        return 'Dikerjakan';

      case ServisStatus.selesai:
        return 'Selesai';

      case ServisStatus.batal:
        return 'Dibatalkan';
    }
  }

  Color _statusColor(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return Colors.orange;

      case ServisStatus.ditugaskan:
        return Colors.blue;

      case ServisStatus.dikerjakan:
        return Colors.purple;

      case ServisStatus.selesai:
        return Colors.green;

      case ServisStatus.batal:
        return Colors.red;
    }
  }

  IconData _statusIcon(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return Icons.access_time_rounded;

      case ServisStatus.ditugaskan:
        return Icons.person_outline_rounded;

      case ServisStatus.dikerjakan:
        return Icons.engineering_rounded;

      case ServisStatus.selesai:
        return Icons.check_circle_rounded;

      case ServisStatus.batal:
        return Icons.cancel_rounded;
    }
  }

  String _getItemStatusDisplay(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'menunggu_konfirmasi':
      case 'menunggukonfirmasi':
        return 'Menunggu';

      case 'ditugaskan':
        return 'Ditugaskan';

      case 'dikerjakan':
        return 'Dikerjakan';

      case 'selesai':
        return 'Selesai';

      case 'batal':
        return 'Batal';

      default:
        return status.isEmpty
            ? '-'
            : status;
    }
  }

  Color _itemStatusColor(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'menunggu_konfirmasi':
      case 'menunggukonfirmasi':
        return Colors.orange;

      case 'ditugaskan':
        return Colors.blue;

      case 'dikerjakan':
        return Colors.purple;

      case 'selesai':
        return Colors.green;

      case 'batal':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // TYPE
  // ============================================================

  IconData _jenisIcon(
      JenisPenanganan jenis,
      ) {
    switch (jenis) {
      case JenisPenanganan.cuci:
        return Icons.cleaning_services_rounded;

      case JenisPenanganan.perbaikan:
        return Icons.build_rounded;

      case JenisPenanganan.instalasi:
        return Icons.install_desktop_rounded;
    }
  }

  // ============================================================
  // BASIC DATA
  // ============================================================

  String get _lokasiAlamat {
    return _firstNonEmpty([
      servis.lokasiData?['address'],
      servis.lokasiData?['alamat'],
      '-',
    ]);
  }

  List<String> get _teknisiList {
    final names = <String>[];

    for (final technician
    in servis.techniciansData) {
      final name =
      _firstNonEmpty([
        technician['name'],
        technician['nama'],
      ]);

      if (name.isNotEmpty &&
          !names.contains(name)) {
        names.add(name);
      }
    }

    final parentTechnician =
    _firstNonEmpty([
      servis.teknisiData?['name'],
      servis.teknisiData?['nama'],
    ]);

    if (parentTechnician.isNotEmpty &&
        !names.contains(parentTechnician)) {
      names.add(parentTechnician);
    }

    for (final item in servis.itemsData) {
      if (item['technician'] is Map) {
        final technician =
        Map<String, dynamic>.from(
          item['technician'],
        );

        final name =
        _firstNonEmpty([
          technician['name'],
          technician['nama'],
        ]);

        if (name.isNotEmpty &&
            !names.contains(name)) {
          names.add(name);
        }
      }
    }

    return names;
  }

  String get _teknisiDisplay {
    final names = _teknisiList;

    if (names.isEmpty) {
      final assigned =
      servis.itemsData.any(
            (item) =>
        item['technician_id'] != null,
      );

      return assigned
          ? 'Sudah ditugaskan'
          : 'Belum ditugaskan';
    }

    if (names.length == 1) {
      return names.first;
    }

    return '${names.first} +${names.length - 1}';
  }

  List<String> get _tindakanList {
    final raw =
    (servis.tindakanSummary ?? '')
        .trim();

    if (raw.isEmpty) {
      return [];
    }

    return raw
        .split(',')
        .map(
          (value) =>
          value.trim(),
    )
        .where(
          (value) =>
      value.isNotEmpty,
    )
        .toList();
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Belum ditentukan';
    }

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(
      DateTime? date,
      ) {
    if (date == null) {
      return '-';
    }

    if (date.hour == 0 &&
        date.minute == 0) {
      return '-';
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatRupiah(
      double value,
      ) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(
        r'(\d{1,3})(?=(\d{3})+(?!\d))',
      ),
          (match) => '${match[1]}.',
    )}';
  }

  String? get _durationDisplay {
    if (servis.tanggalMulai == null) {
      return null;
    }

    final end =
        servis.tanggalSelesai ??
            DateTime.now();

    final difference =
    end.difference(
      servis.tanggalMulai!,
    );

    if (difference.inMinutes < 1) {
      return 'kurang dari 1 menit';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes} menit';
    }

    if (difference.inDays < 1) {
      final hours =
          difference.inHours;

      final minutes =
          difference.inMinutes %
              60;

      if (minutes == 0) {
        return '$hours jam';
      }

      return '$hours jam $minutes menit';
    }

    final days =
        difference.inDays;

    final hours =
        difference.inHours %
            24;

    if (hours == 0) {
      return '$days hari';
    }

    return '$days hari $hours jam';
  }

  // ============================================================
  // GENERIC HELPERS
  // ============================================================

  String _firstNonEmpty(
      List<dynamic> values,
      ) {
    for (final value in values) {
      if (value == null) continue;

      if (value is Map) {
        continue;
      }

      final text =
      value.toString().trim();

      if (text.isNotEmpty &&
          text.toLowerCase() != 'null' &&
          text != '-') {
        return text;
      }
    }

    return '';
  }
}

// ============================================================
// ROOM INFO
// ============================================================

class _RoomInfo {
  final String name;
  final String floor;

  const _RoomInfo({
    required this.name,
    required this.floor,
  });
}

// ============================================================
// PHOTO CATEGORY
// ============================================================

class _FotoCategory {
  final String title;
  final List<String> photos;

  const _FotoCategory({
    required this.title,
    required this.photos,
  });
}