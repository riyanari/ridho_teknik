import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ridho_teknik/models/servis_model.dart';
import 'package:ridho_teknik/pages/klien/servis_item_ac_detail_page.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:share_plus/share_plus.dart';

class ServisDetailPage extends StatelessWidget {
  final ServisModel servis;

  const ServisDetailPage({
    super.key,
    required this.servis,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusHero(),
                const SizedBox(height: 20),
                _buildModernInfoSection(),
                const SizedBox(height: 20),
                if ((servis.keluhanClient ?? '').trim().isNotEmpty)
                  _buildModernKeluhanSection(),
                if ((servis.keluhanClient ?? '').trim().isNotEmpty)
                  const SizedBox(height: 20),
                if (servis.itemsData.isNotEmpty)
                  _buildModernItemsAcSection(context),
                if (servis.itemsData.isNotEmpty) const SizedBox(height: 20),
                _buildModernDetailSection(),
                const SizedBox(height: 20),
                _buildModernBiayaSection(context),
                const SizedBox(height: 20),
                if (servis.fotoSebelum.isNotEmpty ||
                    servis.fotoPengerjaan.isNotEmpty ||
                    servis.fotoSesudah.isNotEmpty ||
                    servis.fotoSukuCadang.isNotEmpty)
                  _buildModernFotoSection(),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 8, top: 8),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPrimaryColor,
                kPrimaryColor.withValues(alpha: 0.8),
                const Color(0xFF2A5C8A),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getJenisIcon(servis.jenis),
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                servis.jenisDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: servis.statusColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: servis.statusColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(servis.status),
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                servis.statusDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      servis.lokasiNama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _lokasiAlamat,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHero() {
    final duration = _durationDisplay;

    if (servis.status == ServisStatus.selesai && duration != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kBoxMenuGreenColor.withValues(alpha: 0.2),
              kBoxMenuGreenColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kBoxMenuGreenColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBoxMenuGreenColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kBoxMenuGreenColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servis Selesai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durasi pengerjaan: $duration',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer,
                color: kBoxMenuGreenColor,
                size: 20,
              ),
            ),
          ],
        ),
      );
    }

    if (_isInProgress) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.2),
              Colors.purple.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.engineering,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servis Sedang Berlangsung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    servis.tanggalMulai != null
                        ? 'Mulai: ${_formatDateTime(servis.tanggalMulai)}'
                        : 'Menunggu teknisi memulai',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildModernInfoSection() {
    final acNames = _acNames;
    final teknisiList = _teknisiList;
    final teknisiDisplay = _teknisiDisplay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.info_outline,
          title: 'Informasi Servis',
          color: kPrimaryColor,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildModernInfoTile(
                icon: Icons.ac_unit,
                iconColor: kSecondaryColor,
                title: 'Unit AC',
                value: _acDisplay,
                subtitle:
                acNames.length > 1 ? '${acNames.length} unit terdaftar' : null,
              ),
              _buildDivider(),
              _buildModernInfoTile(
                icon: Icons.person_outline,
                iconColor: Colors.orange,
                title: 'Teknisi',
                value: teknisiDisplay,
                subtitle: teknisiDisplay != 'Belum ditugaskan'
                    ? '${teknisiList.length} teknisi'
                    : null,
              ),
              _buildDivider(),
              _buildModernInfoTile(
                icon: Icons.calendar_today,
                iconColor: Colors.purple,
                title: 'Tanggal Ditugaskan',
                value: _formatDate(servis.tanggalDitugaskan),
                subtitle: _getDayName(servis.tanggalDitugaskan),
              ),
              if ((servis.noInvoice ?? '').trim().isNotEmpty) ...[
                _buildDivider(),
                _buildModernInfoTile(
                  icon: Icons.receipt_outlined,
                  iconColor: Colors.green,
                  title: 'No. Invoice',
                  value: servis.noInvoice!,
                  subtitle: null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernKeluhanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.warning_amber_rounded,
          title: 'Keluhan Awal',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.report_problem,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Keluhan Klien',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (servis.keluhanClient ?? '-').trim().isEmpty
                          ? '-'
                          : (servis.keluhanClient ?? '-').trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    if (servis.tanggalBerkunjung != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Diajukan: ${_formatDateTime(servis.tanggalBerkunjung)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernItemsAcSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.ac_unit,
          title: 'Daftar AC (${servis.itemsData.length})',
          color: kPrimaryColor,
        ),
        const SizedBox(height: 12),
        ...servis.itemsData
            .map((it) => _buildModernAcItemCard(context, it))
            .toList(),
      ],
    );
  }

  Widget _buildModernAcItemCard(
      BuildContext context,
      Map<String, dynamic> it,
      ) {
    final ac = (it['ac_unit'] is Map)
        ? Map<String, dynamic>.from(it['ac_unit'])
        : <String, dynamic>{};

    final itemStatus = (it['status'] ?? '').toString();
    final acName = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '').toString();
    final capacity = (ac['capacity'] ?? '').toString();
    final type = (ac['type'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServisItemAcDetailPage(
                  servisId: servis.id.toString(),
                  item: it,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.ac_unit,
                        color: kPrimaryColor.withValues(alpha: 0.5),
                        size: 32,
                      ),
                      if (servis.fotoSesudah.isNotEmpty)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              [brand, capacity]
                                  .where((e) => e.trim().isNotEmpty)
                                  .join(' • '),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (type.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _itemStatusColor(itemStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getItemStatusDisplay(itemStatus),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _itemStatusColor(itemStatus),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailSection() {
    final tindakan = _tindakanList;
    final acNamesFromItemsOnly = _acNamesFromItemsOnly;
    final diagnosa = (servis.diagnosa ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.build_circle_outlined,
          title: 'Detail Pengerjaan',
          color: Colors.purple,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tindakan.isNotEmpty) ...[
                _buildDetailChipSection(
                  icon: Icons.handyman,
                  title: 'Tindakan yang dilakukan',
                  items: tindakan.map(_getTindakanText).toList(),
                  color: kPrimaryColor,
                ),
                const SizedBox(height: 16),
              ],
              if (diagnosa.isNotEmpty) ...[
                _buildDetailTextSection(
                  icon: Icons.medical_services,
                  title: 'Diagnosa',
                  content: diagnosa,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
              ],
              if (acNamesFromItemsOnly.isNotEmpty && tindakan.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Unit AC yang diservis:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: acNamesFromItemsOnly.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kPrimaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: kPrimaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChipSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailTextSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBiayaSection(BuildContext context) {
    if (servis.status != ServisStatus.selesai) {
      return const SizedBox.shrink();
    }

    final isBiayaZero = servis.totalBiaya == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.receipt_long,
          title: 'Rincian Biaya',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              if (!isBiayaZero) ...[
                _buildModernBiayaRow(
                  icon: Icons.build,
                  label: 'Biaya Servis',
                  value: _formatRupiah(servis.biayaServis),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Total Biaya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _formatRupiah(servis.totalBiaya),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Biaya Belum Diatur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Biaya servis ini belum diatur oleh Owner Ridho Teknik. Silakan hubungi admin untuk informasi lebih lanjut.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0066B3).withValues(alpha: 0.05),
                      const Color(0xFF00A36C).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0066B3).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066B3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pembayaran QRIS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0066B3),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Scan untuk melakukan pembayaran',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/qris_cvrt.jpeg',
                              height: 200,
                              width: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'QRIS tidak ditemukan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet,
                                      size: 16,
                                      color: Color(0xFF0066B3),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ridho Teknik Official',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Scan QRIS di atas menggunakan:\n• Mobile Banking\n• E-Wallet (OVO, GoPay, Dana, dll)\n• QRIS Merchant',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (!isBiayaZero) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Total: ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(servis.totalBiaya),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _saveQrisImage(context),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text(
                                    'Simpan QRIS',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0066B3),
                                    side: const BorderSide(
                                      color: Color(0xFF0066B3),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _sharePaymentInfo(context),
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Bagikan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066B3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveQrisImage(BuildContext context) async {
    try {
      final byteData = await rootBundle.load('assets/qris_cvrt.jpeg');
      final Uint8List bytes = byteData.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'qris_ridho_teknik',
      );

      final isSuccess = (result['isSuccess'] == true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess
                ? 'QRIS berhasil disimpan ke galeri'
                : 'Gagal menyimpan QRIS',
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menyimpan QRIS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePaymentInfo(BuildContext context) async {
    try {
      final byteData = await rootBundle.load('assets/qris_cvrt.jpeg');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qris_ridho_teknik.jpeg');
      await file.writeAsBytes(bytes, flush: true);

      final text = (servis.totalBiaya == 0)
          ? 'QRIS Ridho Teknik (biaya belum diatur). Silakan scan QRIS untuk pembayaran.'
          : 'Pembayaran Ridho Teknik\nTotal: ${_formatRupiah(servis.totalBiaya)}\nSilakan scan QRIS.';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Pembayaran QRIS Ridho Teknik',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error membagikan QRIS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildModernBiayaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModernFotoSection() {
    final allPhotos = [
      if (servis.fotoSebelum.isNotEmpty)
        _FotoCategory(title: 'Sebelum', photos: servis.fotoSebelum),
      if (servis.fotoPengerjaan.isNotEmpty)
        _FotoCategory(title: 'Proses', photos: servis.fotoPengerjaan),
      if (servis.fotoSesudah.isNotEmpty)
        _FotoCategory(title: 'Sesudah', photos: servis.fotoSesudah),
      if (servis.fotoSukuCadang.isNotEmpty)
        _FotoCategory(title: 'Suku Cadang', photos: servis.fotoSukuCadang),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.photo_camera,
          title: 'Dokumentasi',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var category in allPhotos) ...[
                _buildModernFotoCategory(category),
                if (category != allPhotos.last) const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernFotoCategory(_FotoCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Foto ${category.title}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${category.photos.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: category.photos.length > 6 ? 6 : category.photos.length,
          itemBuilder: (context, index) {
            if (index == 5 && category.photos.length > 6) {
              return _buildMorePhotosTile(category.photos.length - 5);
            }
            return _buildModernFotoGridItem(category.photos[index], context);
          },
        ),
      ],
    );
  }

  Widget _buildModernFotoGridItem(String url, BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoDialog(url, context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: kPrimaryColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 24,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMorePhotosTile(int remainingCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+$remainingCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const Text(
              'Lainnya',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(String url, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 400,
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Colors.grey[200],
      ),
    );
  }

  IconData _getStatusIcon(ServisStatus status) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return Icons.access_time;
      case ServisStatus.ditugaskan:
        return Icons.person_outline;
      case ServisStatus.dikerjakan:
        return Icons.engineering;
      case ServisStatus.selesai:
        return Icons.check_circle;
      case ServisStatus.batal:
        return Icons.cancel;
    }
  }

  String _getItemStatusDisplay(String status) {
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
        return status;
    }
  }

  Color _itemStatusColor(String status) {
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

  String _getTindakanText(String tindakan) {
    return tindakan;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final monthNames = [
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
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${_formatDate(date)} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(DateTime? date) {
    if (date == null) return '-';
    final dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return dayNames[date.weekday % 7];
  }

  String _formatRupiah(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    )}';
  }

  String get _lokasiAlamat {
    return (servis.lokasiData?['address'] ?? '-').toString();
  }

  List<String> get _acNames {
    final names = <String>[];

    if (servis.acData != null) {
      final name = (servis.acData!['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    for (final item in servis.itemsData) {
      final ac = item['ac_unit'];
      if (ac is Map) {
        final name = (ac['name'] ?? '').toString().trim();
        if (name.isNotEmpty && !names.contains(name)) {
          names.add(name);
        }
      }
    }

    return names;
  }

  List<String> get _acNamesFromItemsOnly {
    final names = <String>[];

    for (final item in servis.itemsData) {
      final ac = item['ac_unit'];
      if (ac is Map) {
        final name = (ac['name'] ?? '').toString().trim();
        if (name.isNotEmpty && !names.contains(name)) {
          names.add(name);
        }
      }
    }

    return names;
  }

  String get _acDisplay {
    if (servis.jenis == JenisPenanganan.instalasi) {
      if (servis.jumlahAc > 0) return 'Instalasi ${servis.jumlahAc} unit';
      return 'Instalasi';
    }

    final names = _acNames;
    if (names.isEmpty) return '-';
    if (names.length <= 2) return names.join(', ');
    return '${names.first} +${names.length - 1}';
  }

  List<String> get _teknisiList {
    final names = <String>[];

    for (final t in servis.techniciansData) {
      final name = (t['name'] ?? t['nama'] ?? '').toString().trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    final fallback =
    (servis.teknisiData?['name'] ?? servis.teknisiData?['nama'] ?? '')
        .toString()
        .trim();
    if (fallback.isNotEmpty && !names.contains(fallback)) {
      names.add(fallback);
    }

    for (final item in servis.itemsData) {
      final tech = item['technician'];
      if (tech is Map) {
        final map = Map<String, dynamic>.from(tech);
        final name = (map['name'] ?? map['nama'] ?? '').toString().trim();
        if (name.isNotEmpty && !names.contains(name)) {
          names.add(name);
        }
      }
    }

    return names;
  }

  String get _teknisiDisplay {
    final names = _teknisiList;

    if (names.isNotEmpty) {
      if (names.length == 1) return names.first;
      return '${names.first} +${names.length - 1}';
    }

    final hasAssignedTech = servis.itemsData.any((item) {
      final techId = item['technician_id'];
      return techId != null && techId.toString().trim().isNotEmpty;
    });

    return hasAssignedTech ? 'Teknisi ditugaskan' : 'Belum ditugaskan';
  }

  List<String> get _tindakanList {
    final raw = (servis.tindakanSummary ?? '').trim();
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool get _isInProgress {
    return servis.status == ServisStatus.ditugaskan ||
        servis.status == ServisStatus.dikerjakan;
  }

  String? get _durationDisplay {
    if (servis.tanggalMulai == null) return null;

    final end = servis.tanggalSelesai ?? DateTime.now();
    final diff = end.difference(servis.tanggalMulai!);

    if (diff.inMinutes < 1) return 'Baru dimulai';
    if (diff.inHours < 1) return '${diff.inMinutes} menit';

    if (diff.inDays < 1) {
      final jam = diff.inHours;
      final menit = diff.inMinutes % 60;
      if (menit == 0) return '$jam jam';
      return '$jam jam $menit menit';
    }

    final hari = diff.inDays;
    final jam = diff.inHours % 24;
    if (jam == 0) return '$hari hari';
    return '$hari hari $jam jam';
  }

  IconData _getJenisIcon(JenisPenanganan jenis) {
    switch (jenis) {
      case JenisPenanganan.cuci:
        return Icons.clean_hands;
      case JenisPenanganan.perbaikan:
        return Icons.build;
      case JenisPenanganan.instalasi:
        return Icons.install_desktop;
    }
  }
}

class _FotoCategory {
  final String title;
  final List<String> photos;

  _FotoCategory({
    required this.title,
    required this.photos,
  });
}