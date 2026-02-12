import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import '../../services/token_store.dart';
import '../../utils/photo_url_helper.dart';

class ServisItemAcDetailPage extends StatefulWidget {
  final String servisId;
  final Map<String, dynamic> item;

  const ServisItemAcDetailPage({
    super.key,
    required this.servisId,
    required this.item,
  });

  @override
  State<ServisItemAcDetailPage> createState() => _ServisItemAcDetailPageState();
}

class _ServisItemAcDetailPageState extends State<ServisItemAcDetailPage> {
  String? _token;
  bool _loadingToken = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final store = context.read<TokenStore>();
    String? token;
    try {
      token = await store.getToken();
    } catch (_) {
      token = null;
    }

    if (!mounted) return;
    setState(() {
      _token = token;
      _loadingToken = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final itemId = int.tryParse(item['id'].toString()) ?? 0;

    final ac = (item['ac_unit'] is Map)
        ? Map<String, dynamic>.from(item['ac_unit'])
        : <String, dynamic>{};

    final acName = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '').toString();
    final type = (ac['type'] ?? '').toString();
    final capacity = (ac['capacity'] ?? '').toString();
    final serialNumber = (ac['serial_number'] ?? '').toString();
    final itemStatus = (item['status'] ?? '').toString();
    final teknisi = item['technician'] is Map
        ? Map<String, dynamic>.from(item['technician'])
        : null;
    final teknisiName = teknisi != null ? (teknisi['name'] ?? '').toString() : 'Belum ditugaskan';

    // Diagnosa & Tindakan
    final diagnosa = (item['diagnosa'] ?? '').toString();
    final tindakanList = item['tindakan'] is List
        ? List<String>.from(item['tindakan'] as List)
        : <String>[];

    // Tanggal Mulai & Selesai
    final tanggalMulai = item['tanggal_mulai'] != null
        ? DateTime.tryParse(item['tanggal_mulai'].toString())
        : null;
    final tanggalSelesai = item['tanggal_selesai'] != null
        ? DateTime.tryParse(item['tanggal_selesai'].toString())
        : null;
    final isCompleted = itemStatus.toLowerCase() == 'selesai';

    if (_loadingToken) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildModernAppBar(acName),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if ((_token ?? '').isEmpty) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildModernAppBar(acName),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Token tidak ditemukan',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Silakan login ulang',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    // Foto
    final fotoSebelum = asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'sebelum',
      valueFromApi: item['foto_sebelum'],
    );
    final fotoPengerjaan = asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'pengerjaan',
      valueFromApi: item['foto_pengerjaan'],
    );
    final fotoSesudah = asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'sesudah',
      valueFromApi: item['foto_sesudah'],
    );
    final fotoSukuCadang = asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'suku_cadang',
      valueFromApi: item['foto_suku_cadang'],
    );

    final allPhotos = [
      if (fotoSebelum.isNotEmpty) ('Sebelum', fotoSebelum),
      if (fotoPengerjaan.isNotEmpty) ('Proses', fotoPengerjaan),
      if (fotoSesudah.isNotEmpty) ('Sesudah', fotoSesudah),
      if (fotoSukuCadang.isNotEmpty) ('Suku Cadang', fotoSukuCadang),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildModernAppBar(acName),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HERO CARD - Informasi AC
          SliverToBoxAdapter(
            child: _buildAcHeroCard(
              acName: acName,
              brand: brand,
              capacity: capacity,
              type: type,
              serialNumber: serialNumber,
              status: itemStatus,
              teknisiName: teknisiName,
            ),
          ),

          // SECTION TANGGAL PENGERJAAN - HANYA MUNCUL JIKA STATUS SELESAI
          if (isCompleted) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildTanggalPengerjaanSection(tanggalMulai, tanggalSelesai),
              ),
            ),
          ],

          // MAIN CONTENT - Diagnosa, Tindakan, Foto
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildDiagnosaSection(diagnosa),
                const SizedBox(height: 16),
                _buildTindakanSection(tindakanList),
                if (allPhotos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildModernPhotoGallery(allPhotos),
                ] else ...[
                  const SizedBox(height: 24),
                  _buildEmptyPhotoState(),
                ],
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TANGGAL PENGERJAAN
  // ============================================================
  Widget _buildTanggalPengerjaanSection(DateTime? tanggalMulai, DateTime? tanggalSelesai) {
    final hasTanggalMulai = tanggalMulai != null;
    final hasTanggalSelesai = tanggalSelesai != null;

    // Hitung durasi jika kedua tanggal tersedia
    Duration? durasi;
    if (hasTanggalMulai && hasTanggalSelesai) {
      durasi = tanggalSelesai.difference(tanggalMulai);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Waktu Pengerjaan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const Spacer(),
              if (durasi != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_bottom, size: 12, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(durasi),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline Mulai & Selesai
          Row(
            children: [
              Expanded(child: _buildTimelineItem(
                icon: Icons.play_circle_filled,
                iconColor: Colors.blue,
                title: 'Mulai Pengerjaan',
                dateTime: tanggalMulai,
                isAvailable: hasTanggalMulai,
              )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 30,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withValues(alpha: 0.5), Colors.green.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildTimelineItem(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: 'Selesai Pengerjaan',
                dateTime: tanggalSelesai,
                isAvailable: hasTanggalSelesai,
              )),
            ],
          ),

          // Info jika data tidak lengkap
          if (!hasTanggalMulai || !hasTanggalSelesai) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !hasTanggalMulai && !hasTanggalSelesai
                          ? 'Data waktu pengerjaan tidak tersedia'
                          : !hasTanggalMulai
                          ? 'Tanggal mulai tidak tersedia'
                          : 'Tanggal selesai tidak tersedia',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required DateTime? dateTime,
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          if (isAvailable && dateTime != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(dateTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_formatTime(dateTime), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 16, color: Colors.grey[200]),
                const SizedBox(height: 4),
                Container(width: 60, height: 12, color: Colors.grey[200]),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION DIAGNOSA
  // ============================================================
  Widget _buildDiagnosaSection(String diagnosa) {
    final hasDiagnosa = diagnosa.trim().isNotEmpty;

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Diagnosa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (!hasDiagnosa) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                  child: Text('Kosong', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (hasDiagnosa)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Text(diagnosa, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Tidak ada diagnosa', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      'Teknisi tidak memiliki diagnosa terhadap AC',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TINDAKAN
  // ============================================================
  Widget _buildTindakanSection(List<String> tindakanList) {
    final displayTindakan = tindakanList.map((t) {
      switch (t.toLowerCase()) {
        case 'pembersihan': return 'Pembersihan AC';
        case 'isi_freon': return 'Isi Freon';
        case 'ganti_filter': return 'Ganti Filter';
        case 'perbaikan_kompressor': return 'Perbaikan Kompressor';
        case 'perbaikan_pcb': return 'Perbaikan PCB';
        case 'ganti_kapasitor': return 'Ganti Kapasitor';
        case 'ganti_fan_motor': return 'Ganti Fan Motor';
        case 'tune_up': return 'Tune Up';
        case 'lainnya': return 'Lainnya';
        default:
          return t
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
              .join(' ');
      }
    }).toList();

    final hasTindakan = displayTindakan.isNotEmpty;

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Tindakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (hasTindakan) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${displayTindakan.length} tindakan',
                    style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                  child: Text('Kosong', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (hasTindakan)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: displayTindakan.map((tindakan) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTindakanIcon(tindakan), size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(tindakan, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blue[700])),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.build_outlined, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Tidak ada tindakan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      'Teknisi tidak menjelaskan tindakan yang dilakukan',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO CARD - INFORMASI AC
  // ============================================================
  PreferredSizeWidget _buildModernAppBar(String title) {
    return AppBar(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: IconButton(icon: const Icon(Icons.share_outlined, size: 20), onPressed: () {}),
        ),
      ],
    );
  }

  Widget _buildAcHeroCard({
    required String acName,
    required String brand,
    required String capacity,
    required String type,
    required String serialNumber,
    required String status,
    required String teknisiName,
  }) {
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.ac_unit, size: 40, color: kPrimaryColor.withValues(alpha: 0.5)),
                    if (status.toLowerCase() == 'selesai')
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
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
                    Text(acName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getStatusIcon(status), size: 14, color: statusColor),
                              const SizedBox(width: 6),
                              Text(_getStatusDisplay(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Spesifikasi Grid
          Row(
            children: [
              Expanded(child: _buildSpecItem(icon: Icons.branding_watermark, label: 'Merek', value: brand.isNotEmpty ? brand : '-')),
              Expanded(child: _buildSpecItem(icon: Icons.speed, label: 'Kapasitas', value: capacity.isNotEmpty ? capacity : '-')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSpecItem(icon: Icons.category, label: 'Tipe', value: type.isNotEmpty ? type : '-')),
            ],
          ),
          const SizedBox(height: 20),

          // Teknisi Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teknisi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(teknisiName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

  Widget _buildSpecItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DOKUMENTASI FOTO
  // ============================================================
  Widget _buildModernPhotoGallery(List<(String, List<String>)> allPhotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Dokumentasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ...allPhotos.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return _buildModernPhotoCategory(
            title: category.$1,
            photos: category.$2,
            isFirst: index == 0,
            isLast: index == allPhotos.length - 1,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildModernPhotoCategory({
    required String title,
    required List<String> photos,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: _getCategoryColor(title), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Text('Foto $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _getCategoryColor(title).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${photos.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getCategoryColor(title))),
              ),
              const Spacer(),
              if (photos.length > 4)
                TextButton(
                  onPressed: () => _showFullGallery(title, photos),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: photos.length > 8 ? 8 : photos.length,
            itemBuilder: (context, index) {
              if (index == 7 && photos.length > 8) {
                return _buildMorePhotosGridTile(photos.length - 7);
              }
              return _buildModernPhotoGridItem(photos[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoGridItem(String url, int index) {
    final token = _token!;
    return GestureDetector(
      onTap: () => _showPhotoGallery(url, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                headers: {'Authorization': 'Bearer $token', 'Accept': 'image/*'},
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.broken_image, size: 20, color: Colors.grey[400])],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent],
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

  Widget _buildMorePhotosGridTile(int remainingCount) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+$remainingCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 2),
            Text('Lainnya', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.photo_camera_back, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text('Belum Ada Dokumentasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Foto dokumentasi untuk AC ini belum tersedia', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG & MODAL
  // ============================================================
  void _showPhotoGallery(String url, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                color: Colors.black,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  headers: {'Authorization': 'Bearer $_token', 'Accept': 'image/*'},
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
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
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullGallery(String title, List<String> photos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Text('Foto $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _getCategoryColor(title).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${photos.length} foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _getCategoryColor(title))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showPhotoGallery(photos[index], index);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        headers: {'Authorization': 'Bearer $_token', 'Accept': 'image/*'},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    if (days > 0) return '$days hari $hours jam';
    if (hours > 0) return '$hours jam $minutes menit';
    return '$minutes menit';
  }

  String _formatDate(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getTindakanIcon(String tindakan) {
    if (tindakan.contains('Pembersihan')) return Icons.cleaning_services;
    if (tindakan.contains('Freon')) return Icons.ac_unit;
    if (tindakan.contains('Filter')) return Icons.filter_alt;
    if (tindakan.contains('Kompressor')) return Icons.compress;
    if (tindakan.contains('PCB')) return Icons.memory;
    if (tindakan.contains('Kapasitor')) return Icons.electrical_services;
    if (tindakan.contains('Fan Motor')) return Icons.speed;
    if (tindakan.contains('Tune Up')) return Icons.tune;
    return Icons.build;
  }

  Color _getCategoryColor(String title) {
    switch (title.toLowerCase()) {
      case 'sebelum': return Colors.orange;
      case 'proses': return Colors.blue;
      case 'sesudah': return Colors.green;
      case 'suku cadang': return Colors.purple;
      default: return kPrimaryColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_konfirmasi': return Colors.orange;
      case 'ditugaskan': return Colors.blue;
      case 'dikerjakan': return Colors.purple;
      case 'selesai': return Colors.green;
      case 'batal': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_konfirmasi': return Icons.access_time;
      case 'ditugaskan': return Icons.person_outline;
      case 'dikerjakan': return Icons.engineering;
      case 'selesai': return Icons.check_circle;
      case 'batal': return Icons.cancel;
      default: return Icons.info_outline;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_konfirmasi': return 'Menunggu Konfirmasi';
      case 'ditugaskan': return 'Ditugaskan';
      case 'dikerjakan': return 'Dikerjakan';
      case 'selesai': return 'Selesai';
      case 'batal': return 'Dibatalkan';
      default: return status;
    }
  }
}