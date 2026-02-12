// pages/owner/owner_ac_detail_view_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../utils/photo_url_helper.dart';

class OwnerAcDetailViewPage extends StatelessWidget {
  final Map<String, dynamic> item; // service_item (punya ac_unit, status, foto_*, diagnosa, tindakan, tanggal_*)
  final int itemId;
  final String? token;

  const OwnerAcDetailViewPage({
    super.key,
    required this.item,
    required this.itemId,
    required this.token,
  });

  Map<String, String> get _authHeaders {
    var t = (token ?? '').trim();
    if (t.toLowerCase().startsWith('bearer ')) {
      t = t.substring(7).trim();
    }
    if (t.isEmpty) return const {'Accept': 'image/*'};
    return {
      'Authorization': 'Bearer $t',
      'Accept': 'image/*',
    };
  }


  String get _itemStatus =>
      (item['status'] ?? '').toString().toLowerCase().trim();

  bool get _isSelesai => _itemStatus == 'selesai';
  bool get _isDikerjakan => _itemStatus == 'dikerjakan';
  bool get _isDitugaskan => _itemStatus == 'ditugaskan';

  Color get _statusColor {
    switch (_itemStatus) {
      case 'ditugaskan':
        return const Color(0xFF2196F3);
      case 'dikerjakan':
        return const Color(0xFF9C27B0);
      case 'selesai':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (_itemStatus) {
      case 'ditugaskan':
        return 'Ditugaskan';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return _itemStatus;
    }
  }

  List<String> get _serverSebelum => asServiceItemPhotoUrls(
    itemId: itemId,
    type: 'sebelum',
    valueFromApi: item['foto_sebelum'],
  );

  List<String> get _serverPengerjaan => asServiceItemPhotoUrls(
    itemId: itemId,
    type: 'pengerjaan',
    valueFromApi: item['foto_pengerjaan'],
  );

  List<String> get _serverSesudah => asServiceItemPhotoUrls(
    itemId: itemId,
    type: 'sesudah',
    valueFromApi: item['foto_sesudah'],
  );

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '-';
    try {
      final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = (item['ac_unit'] is Map)
        ? Map<String, dynamic>.from(item['ac_unit'] as Map)
        : <String, dynamic>{};

    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();
    final location = (ac['location'] ?? '-').toString();

    final diagnosa = (item['diagnosa'] ?? '').toString().trim();
    final tindakan = (item['tindakan'] ?? '').toString().trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Detail AC',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildAcHeader(
              context,
              name: name,
              brand: brand,
              type: type,
              capacity: capacity,
              location: location,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                _buildStatusCard(),

                const SizedBox(height: 20),

                // Timeline item (read-only)
                _buildTimelineCard(context),

                const SizedBox(height: 20),

                // Diagnosa & tindakan (read-only)
                _buildDiagnosaTindakanCard(
                  diagnosa: diagnosa,
                  tindakan: tindakan,
                ),

                const SizedBox(height: 20),

                // Foto server (read-only)
                _buildPhotoDocumentationSection(context),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcHeader(
      BuildContext context, {
        required String name,
        required String brand,
        required String type,
        required String capacity,
        required String location,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor.withValues(alpha: 0.2),
                      _statusColor.withValues(alpha: 0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Iconsax.airdrop, color: _statusColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$brand • $type',
                        style:
                        TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.speedometer,
                            color: kPrimaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kapasitas',
                              style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(capacity,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.location,
                              color: Colors.blue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Lokasi',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              Text(
                                location,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isSelesai
                  ? Iconsax.tick_circle
                  : _isDikerjakan
                  ? Iconsax.timer
                  : Iconsax.task_square,
              color: _statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Pengerjaan',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _itemStatus.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.timer, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timeline Item',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _timelineRow('Mulai', item['tanggal_mulai'], Iconsax.play_circle),
          const SizedBox(height: 10),
          _timelineRow('Selesai', item['tanggal_selesai'], Iconsax.tick_circle),
        ],
      ),
    );
  }

  Widget _timelineRow(String label, dynamic time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Text(
          _formatDateTime(time),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDiagnosaTindakanCard({
    required String diagnosa,
    required String tindakan,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.clipboard_text,
                    color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Diagnosa & Tindakan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _readonlyBox(
            title: 'Diagnosa',
            color: Colors.orange,
            text: diagnosa.isEmpty ? 'Belum ada diagnosa' : diagnosa,
            isEmpty: diagnosa.isEmpty,
          ),
          const SizedBox(height: 12),
          _readonlyBox(
            title: 'Tindakan',
            color: Colors.blue,
            text: tindakan.isEmpty ? 'Belum ada tindakan' : tindakan,
            isEmpty: tindakan.isEmpty,
          ),
        ],
      ),
    );
  }

  Widget _readonlyBox({
    required String title,
    required Color color,
    required String text,
    required bool isEmpty,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isEmpty ? Colors.grey[500] : Colors.black87,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoDocumentationSection(BuildContext context) {
    final sebelum = _serverSebelum;
    final pengerjaan = _serverPengerjaan;
    final sesudah = _serverSesudah;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.gallery,
                    color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dokumentasi Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (sebelum.isEmpty && pengerjaan.isEmpty && sesudah.isEmpty)
            _buildEmptyPhotos()
          else ...[
            if (sebelum.isNotEmpty)
              _photoCategory(context, 'Sebelum', sebelum, Colors.orange),
            if (pengerjaan.isNotEmpty) ...[
              const SizedBox(height: 14),
              _photoCategory(context, 'Pengerjaan', pengerjaan, Colors.blue),
            ],
            if (sesudah.isNotEmpty) ...[
              const SizedBox(height: 14),
              _photoCategory(context, 'Sesudah', sesudah, Colors.green),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPhotos() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Iconsax.gallery, size: 44, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text('Belum Ada Dokumentasi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Foto dokumentasi belum tersedia',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _photoCategory(
      BuildContext context, String title, List<String> photos, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text('Foto $title',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${photos.length}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length > 6 ? 6 : photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = photos[index];
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 92,
                    color: Colors.grey[200],
                    child: Image.network(
                      url,
                      headers: _authHeaders,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, p) {
                        if (p == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey[400], size: 28),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                color: Colors.black,
                child: Image.network(
                  url,
                  headers: _authHeaders,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white70, size: 50),
                  ),
                  loadingBuilder: (context, child, p) {
                    if (p == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
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
}
