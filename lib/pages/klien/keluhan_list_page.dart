// lib/pages/klien/keluhan_list_page.dart
import 'package:flutter/material.dart';
import 'package:ridho_teknik/pages/klien/widgets/app_card.dart';
import '../../models/keluhan_model.dart';
import '../../models/lokasi_model.dart';
import '../../theme/theme.dart';

class KeluhanListPage extends StatefulWidget {
  final LokasiModel lokasi;
  const KeluhanListPage({super.key, required this.lokasi});

  @override
  State<KeluhanListPage> createState() => _KeluhanListPageState();
}

class _KeluhanListPageState extends State<KeluhanListPage> {
  final List<KeluhanModel> _keluhanList = [
    KeluhanModel(
      id: 'K1',
      lokasiId: 'L1',
      acId: 'A1',
      judul: 'AC Tidak Dingin',
      deskripsi: 'AC di ruang tamu tidak dingin meski suhu sudah minimum',
      status: KeluhanStatus.diproses,
      prioritas: Prioritas.tinggi,
      tanggalDiajukan: DateTime.now().subtract(const Duration(days: 2)),
      assignedTo: 'S1',
    ),
    KeluhanModel(
      id: 'K2',
      lokasiId: 'L1',
      acId: 'A2',
      judul: 'AC Berisik',
      deskripsi: 'AC mengeluarkan suara berisik saat dinyalakan',
      status: KeluhanStatus.selesai,
      prioritas: Prioritas.sedang,
      tanggalDiajukan: DateTime.now().subtract(const Duration(days: 7)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 1)),
      assignedTo: 'S2',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredKeluhan = _keluhanList
        .where((keluhan) => keluhan.lokasiId == widget.lokasi.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Keluhan', style: titleWhiteTextStyle.copyWith(fontSize: 18)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: kBackgroundColor,
        child: Column(
          children: [
            // Stats Card
            Container(
              margin:  EdgeInsets.all(defaultMargin),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      filteredKeluhan.length.toString(),
                      Icons.list_alt,
                      kPrimaryColor,
                    ),
                    _buildStatItem(
                      'Diproses',
                      filteredKeluhan
                          .where((k) => k.status == KeluhanStatus.diproses)
                          .length
                          .toString(),
                      Icons.build,
                      kSecondaryColor,
                    ),
                    _buildStatItem(
                      'Selesai',
                      filteredKeluhan
                          .where((k) => k.status == KeluhanStatus.selesai)
                          .length
                          .toString(),
                      Icons.check_circle,
                      kBoxMenuGreenColor,
                    ),
                  ],
                ),
              ),
            ),

            // Filter Tabs
            Padding(
              padding: EdgeInsets.symmetric(horizontal: defaultMargin),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: KeluhanStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getStatusText(status)),
                        selected: false,
                        onSelected: (_) {},
                        backgroundColor: status.color.withValues(alpha:0.1),
                        labelStyle: TextStyle(color: status.color),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List Keluhan
            Expanded(
              child: ListView.separated(
                padding:  EdgeInsets.symmetric(horizontal: defaultMargin),
                itemCount: filteredKeluhan.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final keluhan = filteredKeluhan[index];
                  return _KeluhanCard(keluhan: keluhan);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: primaryTextStyle.copyWith(
          fontSize: 18,
          fontWeight: bold,
        )),
        Text(label, style: greyTextStyle.copyWith(fontSize: 12)),
      ],
    );
  }

  String _getStatusText(KeluhanStatus status) {
    switch (status) {
      case KeluhanStatus.diajukan:
        return 'Diajukan';
      case KeluhanStatus.dikirim:
        return 'Dikirim';
      case KeluhanStatus.diproses:
        return 'Diproses';
      case KeluhanStatus.selesai:
        return 'Selesai';
      case KeluhanStatus.ditolak:
        return 'Ditolak';
    }
  }
}

class _KeluhanCard extends StatelessWidget {
  final KeluhanModel keluhan;

  const _KeluhanCard({required this.keluhan});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  keluhan.judul,
                  style: primaryTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: keluhan.status.color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(keluhan.status),
                      size: 12,
                      color: keluhan.status.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      keluhan.statusText,
                      style: primaryTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: medium,
                        color: keluhan.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            keluhan.deskripsi,
            style: greyTextStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: keluhan.prioritasColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: keluhan.prioritasColor.withValues(alpha:0.3)),
                ),
                child: Text(
                  keluhan.prioritasText,
                  style: primaryTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: medium,
                    color: keluhan.prioritasColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.calendar_today, size: 14, color: kGreyColor),
              const SizedBox(width: 4),
              Text(
                _formatDate(keluhan.tanggalDiajukan),
                style: greyTextStyle.copyWith(fontSize: 12),
              ),
              const Spacer(),
              if (keluhan.assignedTo != null)
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: kGreyColor),
                    const SizedBox(width: 4),
                    Text(
                      'Servicer',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(KeluhanStatus status) {
    switch (status) {
      case KeluhanStatus.diajukan:
        return Icons.send;
      case KeluhanStatus.dikirim:
        return Icons.send_to_mobile;
      case KeluhanStatus.diproses:
        return Icons.build;
      case KeluhanStatus.selesai:
        return Icons.check_circle;
      case KeluhanStatus.ditolak:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}