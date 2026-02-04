import 'package:flutter/material.dart';
import 'package:ridho_teknik/models/servis_model.dart';
import 'package:ridho_teknik/theme/theme.dart';

class ServisDetailPage extends StatelessWidget {
  final ServisModel servis;

   ServisDetailPage({super.key, required this.servis}) {
    // Debug print
    print('=== SERVIS DETAIL DATA ===');
    print('ID: ${servis.id} | Status: ${servis.statusDisplay}');
    print('Lokasi: ${servis.lokasiNama}');
    print('AC: ${servis.acNama} (${servis.acMerk})');
    print('Teknisi: ${servis.teknisiNama}');
    print('Biaya: ${servis.formattedTotalBiaya}');
    print('Foto Sebelum: ${servis.fotoSebelum.length}');
    print('Foto Pengerjaan: ${servis.fotoPengerjaan.length}');  // CEK INI
    print('Foto Sesudah: ${servis.fotoSesudah.length}');
    print('Foto Suku Cadang: ${servis.fotoSukuCadang.length}');
    print('==========================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar dengan gradient minimalis
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                final minHeight = kToolbarHeight;
                final isExpanded = maxHeight > minHeight + 20;

                return FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 16),
                  title: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: isExpanded
                        ? titleWhiteTextStyle.copyWith(fontSize: 14)
                        : titleWhiteTextStyle.copyWith(fontSize: 18),
                    child: Text(
                      'Servis #${servis.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kPrimaryColor,
                          kPrimaryColor.withValues(alpha:0.9),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  servis.jenisIcon,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  servis.jenisDisplay,
                                  style: whiteTextStyle.copyWith(
                                    fontSize: 12,
                                    fontWeight: medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: servis.statusColor.withValues(alpha:0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              servis.statusDisplay,
                              style: whiteTextStyle.copyWith(
                                fontSize: 10,
                                fontWeight: bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              // Timeline Section - Minimalis
              _buildTimelineSection(),

              // Info Section - Compact
              _buildInfoSection(),

              // Keluhan Section - Jika ada
              if (servis.keluhanData != null) _buildKeluhanSection(),

              // Detail Servis - Minimalis
              _buildDetailSection(),

              // Biaya Section - Compact
              _buildBiayaSection(),

              // Foto Section - Jika ada
              if (servis.fotoSebelum.isNotEmpty ||
                  servis.fotoSesudah.isNotEmpty ||
                  servis.fotoSukuCadang.isNotEmpty)
                _buildFotoSection(),

              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    final timelineItems = [
      _TimelineItem(
        icon: Icons.assignment,
        iconColor: Colors.blue,
        title: 'Ditugaskan',
        date: servis.tanggalDitugaskan,
      ),
      if (servis.tanggalMulai != null)
        _TimelineItem(
          icon: Icons.play_arrow,
          iconColor: Colors.green,
          title: 'Mulai Pengerjaan',
          date: servis.tanggalMulai!,
        ),
      if (servis.tanggalSelesai != null)
        _TimelineItem(
          icon: Icons.check_circle,
          iconColor: kBoxMenuGreenColor,
          title: 'Selesai',
          date: servis.tanggalSelesai!,
        ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Timeline',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Timeline items vertikal
                ...timelineItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == timelineItems.length - 1;

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon dengan garis
                          Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: item.iconColor, width: 1.5),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 14,
                                  color: item.iconColor,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 1.5,
                                  height: 40,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: primaryTextStyle.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 11, color: kGreyColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(item.date),
                                        style: greyTextStyle.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),

                // Durasi
                if (servis.durationDisplay != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha:0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: kPrimaryColor),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durasi Pengerjaan',
                              style: greyTextStyle.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              servis.durationDisplay!,
                              style: primaryTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: bold,
                                color: kPrimaryColor,
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
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Informasi',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
          ),

          // Lokasi Card
          _buildInfoTile(
            icon: Icons.location_on,
            iconColor: kPrimaryColor,
            title: 'Lokasi',
            mainText: servis.lokasiNama,
            subText: servis.lokasiAlamat,
          ),

          // AC Card
          _buildInfoTile(
            icon: Icons.ac_unit,
            iconColor: kSecondaryColor,
            title: 'AC Unit',
            mainText: servis.acNama,
            subText: '${servis.acMerk} • ${servis.acType} • ${servis.acKapasitas}',
          ),

          // Teknisi Card
          if (servis.teknisiData != null)
            _buildInfoTile(
              icon: Icons.person,
              iconColor: Colors.orange,
              title: 'Teknisi',
              mainText: servis.teknisiNama,
              subText: servis.teknisiSpesialisasi.isNotEmpty
                  ? 'Spesialis: ${servis.teknisiSpesialisasi}'
                  : 'Terdaftar teknisi',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String mainText,
    required String subText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  mainText,
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subText,
                  style: greyTextStyle.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeluhanSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.report_problem, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Keluhan Asal',
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servis.keluhanJudul,
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  servis.keluhanDeskripsi,
                  style: greyTextStyle.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (servis.keluhanSubmittedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: kGreyColor),
                        const SizedBox(width: 4),
                        Text(
                          'Diajukan: ${_formatDate(servis.keluhanSubmittedAt!)}',
                          style: greyTextStyle.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Detail Servis',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tindakan
                if (servis.tindakan.isNotEmpty) ...[
                  Text(
                    'Tindakan:',
                    style: primaryTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: medium,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: servis.tindakan.map((tindakan) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: kPrimaryColor.withValues(alpha:0.2)),
                        ),
                        child: Text(
                          _getTindakanText(tindakan),
                          style: primaryTextStyle.copyWith(
                            fontSize: 12,
                            color: kPrimaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Diagnosa
                if (servis.diagnosa.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.medical_services, size: 14, color: Colors.orange[800]),
                            const SizedBox(width: 6),
                            Text(
                              'Diagnosa',
                              style: primaryTextStyle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          servis.diagnosa,
                          style: greyTextStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Catatan
                if (servis.catatan.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, size: 14, color: Colors.green[800]),
                            const SizedBox(width: 6),
                            Text(
                              'Catatan',
                              style: primaryTextStyle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          servis.catatan,
                          style: greyTextStyle.copyWith(fontSize: 12),
                        ),
                      ],
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

  Widget _buildBiayaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Biaya',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 14),

          // Biaya Servis
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.build, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Biaya Servis',
                    style: greyTextStyle.copyWith(fontSize: 13),
                  ),
                ),
                Text(
                  servis.formattedBiayaServis,
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Biaya Suku Cadang
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Biaya Suku Cadang',
                    style: greyTextStyle.copyWith(fontSize: 13),
                  ),
                ),
                Text(
                  servis.formattedBiayaSukuCadang,
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.grey[300]),
          ),

          // Total Biaya
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Biaya',
                  style: primaryTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kBoxMenuGreenColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: kBoxMenuGreenColor),
                    const SizedBox(width: 4),
                    Text(
                      servis.formattedTotalBiaya,
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBoxMenuGreenColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFotoSection() {
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

    if (allPhotos.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: kGreyColor.withValues(alpha:0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada dokumentasi foto',
              style: greyTextStyle.copyWith(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Dokumentasi Foto',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var category in allPhotos) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Foto ${category.title}',
                          style: primaryTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${category.photos.length}',
                            style: primaryTextStyle.copyWith(
                              fontSize: 11,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid foto 2 kolom
                  if (category.photos.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: category.photos.length,
                      itemBuilder: (context, index) {
                        return _buildFotoGridItem(category.photos[index]);
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Tidak ada foto',
                          style: greyTextStyle.copyWith(fontSize: 12),
                        ),
                      ),
                    ),

                  if (category != allPhotos.last) const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoGridItem(String url) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement foto viewer
        print('Tapped photo: $url');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Foto
              Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 20, color: Colors.grey[400]),
                          const SizedBox(height: 4),
                          Text(
                            'Gagal memuat',
                            style: TextStyle(color: Colors.grey[500], fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Overlay gelap di bawah untuk kontras
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha:0.3),
                      Colors.transparent,
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

  String _getTindakanText(TindakanServis tindakan) {
    switch (tindakan) {
      case TindakanServis.pembersihan:
        return 'Pembersihan';
      case TindakanServis.isiFreon:
        return 'Isi Freon';
      case TindakanServis.gantiFilter:
        return 'Ganti Filter';
      case TindakanServis.perbaikanKompressor:
        return 'Perbaikan Kompressor';
      case TindakanServis.perbaikanPCB:
        return 'Perbaikan PCB';
      case TindakanServis.gantiKapasitor:
        return 'Ganti Kapasitor';
      case TindakanServis.gantiFanMotor:
        return 'Ganti Fan Motor';
      case TindakanServis.tuneUp:
        return 'Tune Up';
      case TindakanServis.lainnya:
        return 'Lainnya';
    }
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Helper classes untuk struktur data
class _TimelineItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final DateTime date;

  _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
  });
}

class _FotoCategory {
  final String title;
  final List<String> photos;

  _FotoCategory({
    required this.title,
    required this.photos,
  });
}