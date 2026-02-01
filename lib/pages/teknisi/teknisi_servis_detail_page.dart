// lib/pages/teknisi/teknisi_servis_detail_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ac_model.dart';
import '../../models/keluhan_model.dart';
import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';
import '../../models/teknisi_model.dart';
import '../../theme/theme.dart';
import 'package:ridho_teknik/extensions/servis_extensions.dart';

class TeknisiServisDetailPage extends StatefulWidget {
  final TeknisiModel teknisi;
  final LokasiModel lokasi;
  final AcModel ac;
  final KeluhanModel? keluhan;
  final ServisModel servis;

  const TeknisiServisDetailPage({
    super.key,
    required this.teknisi,
    required this.lokasi,
    required this.ac,
    required this.keluhan,
    required this.servis,
  });

  @override
  State<TeknisiServisDetailPage> createState() => _TeknisiServisDetailPageState();
}

class _TeknisiServisDetailPageState extends State<TeknisiServisDetailPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _diagnosaController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _biayaServisController = TextEditingController();
  final TextEditingController _biayaSukuCadangController = TextEditingController();

  List<File> _fotoSebelum = [];
  List<File> _fotoSesudah = [];
  List<File> _fotoSukuCadang = [];
  List<TindakanServis> _selectedTindakan = [];
  ServisStatus _currentStatus = ServisStatus.ditugaskan;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.servis.status;
    _selectedTindakan = widget.servis.tindakan;
    _diagnosaController.text = widget.servis.diagnosa;
    _catatanController.text = widget.servis.catatan;
    _biayaServisController.text = widget.servis.biayaServis.toString();
    _biayaSukuCadangController.text = widget.servis.biayaSukuCadang.toString();
  }

  @override
  void dispose() {
    _diagnosaController.dispose();
    _catatanController.dispose();
    _biayaServisController.dispose();
    _biayaSukuCadangController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(List<File> targetList) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        targetList.add(File(image.path));
      });
    }
  }

  void _removeImage(List<File> targetList, int index) {
    setState(() {
      targetList.removeAt(index);
    });
  }

  void _updateStatus(ServisStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });

    // Logika untuk status tertentu
    if (newStatus == ServisStatus.dalamPerjalanan) {
      _showSnackBar('Status diperbarui: Dalam Perjalanan');
    } else if (newStatus == ServisStatus.tibaDiLokasi) {
      _showSnackBar('Status diperbarui: Tiba di Lokasi');
    } else if (newStatus == ServisStatus.menungguKonfirmasi) {
      _showSnackBar('Laporan dikirim, menunggu konfirmasi owner');
    }
  }

  void _toggleTindakan(TindakanServis tindakan) {
    setState(() {
      if (_selectedTindakan.contains(tindakan)) {
        _selectedTindakan.remove(tindakan);
      } else {
        _selectedTindakan.add(tindakan);
      }
    });
  }

  void _kirimLaporan() {
    if (_selectedTindakan.isEmpty) {
      _showSnackBar('Pilih minimal satu tindakan servis', kBoxMenuRedColor);
      return;
    }

    if (_diagnosaController.text.trim().isEmpty) {
      _showSnackBar('Diagnosa tidak boleh kosong', kBoxMenuRedColor);
      return;
    }

    if (_fotoSebelum.isEmpty) {
      _showSnackBar('Foto kondisi sebelum servis diperlukan', kBoxMenuRedColor);
      return;
    }

    // Simulasi pengiriman laporan
    _updateStatus(ServisStatus.menungguKonfirmasi);

    _showSnackBar(
      'Laporan berhasil dikirim! Menunggu konfirmasi owner CVRT',
      kBoxMenuGreenColor,
    );
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: whiteTextStyle),
        backgroundColor: color ?? kPrimaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildImageGrid(List<File> images, String title, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: bold,
          ),
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreyColor.withValues(alpha:0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_rounded,
                  size: 40,
                  color: kGreyColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada foto',
                  style: greyTextStyle,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(images, index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('Tambah Foto'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<bool> _confirmBackStatus({
    required ServisStatus from,
    required ServisStatus to,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: Text(
            'Anda akan mengubah status dari "${from.text}" ke "${to.text}".\n'
                'Perubahan mundur bisa mempengaruhi laporan. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Ubah'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showInfo(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: whiteTextStyle),
        backgroundColor: color ?? kPrimaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<TindakanServis> get _tindakanByJenis {
    switch (widget.servis.jenis) {
      case JenisPenanganan.cuciAc:
        return const [
          TindakanServis.pembersihan,
          TindakanServis.gantiFilter,
          TindakanServis.tuneUp,
          TindakanServis.lainnya,
        ];

      case JenisPenanganan.perbaikanAc:
        return const [
          TindakanServis.perbaikanKompressor,
          TindakanServis.perbaikanPCB,
          TindakanServis.gantiKapasitor,
          TindakanServis.gantiFanMotor,
          TindakanServis.isiFreon,
          TindakanServis.gantiFilter,
          TindakanServis.lainnya,
        ];

      case JenisPenanganan.instalasi:
        return const [
          // belum ada enum khusus instalasi? pakai yang paling mendekati dulu
          TindakanServis.isiFreon,
          TindakanServis.tuneUp,
          TindakanServis.lainnya,
        ];
    }
  }


  List<ServisStatus> get _stepperStatuses {
    switch (widget.servis.jenis) {
      case JenisPenanganan.cuciAc:
        return [
          ServisStatus.ditugaskan,
          ServisStatus.dalamPerjalanan,
          ServisStatus.tibaDiLokasi,
          ServisStatus.sedangDiperiksa,       // bisa ganti jadi "Sedang Dikerjakan"
          ServisStatus.menungguKonfirmasi,
          ServisStatus.selesai,
        ];

      case JenisPenanganan.perbaikanAc:
        return [
          ServisStatus.ditugaskan,
          ServisStatus.dalamPerjalanan,
          ServisStatus.tibaDiLokasi,
          ServisStatus.sedangDiperiksa,
          ServisStatus.dalamPerbaikan,
          ServisStatus.menungguSukuCadang,
          ServisStatus.menungguKonfirmasi,
          ServisStatus.selesai,
        ];

      case JenisPenanganan.instalasi:
        return [
          ServisStatus.ditugaskan,
          ServisStatus.dalamPerjalanan,
          ServisStatus.tibaDiLokasi,
          ServisStatus.dalamPerbaikan,        // bisa kamu artikan "Pemasangan"
          ServisStatus.menungguKonfirmasi,
          ServisStatus.selesai,
        ];
    }
  }

  Widget _buildStatusStepper() {
    final stepperStatuses = _stepperStatuses;

    final currentIndex = stepperStatuses.indexOf(_currentStatus);
    final safeCurrentIndex = currentIndex == -1 ? 0 : currentIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(16,16,16,0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Servis',
            style: primaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 4,
              childAspectRatio: 1.1,
            ),
            itemCount: stepperStatuses.length,
            itemBuilder: (context, i) {
              final status = stepperStatuses[i];
              final isActive = i <= safeCurrentIndex;
              final isCurrent = i == safeCurrentIndex;

              final canTap = (_currentStatus != ServisStatus.selesai &&
                  _currentStatus != ServisStatus.ditolak) &&
                  (i == safeCurrentIndex || i == safeCurrentIndex + 1);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final targetIndex = i;

                      // kalau sudah selesai / ditolak, tidak boleh ubah apa-apa
                      if (_currentStatus == ServisStatus.selesai ||
                          _currentStatus == ServisStatus.ditolak) {
                        _showInfo('Status sudah final, tidak bisa diubah', kBoxMenuRedColor);
                        return;
                      }

                      // klik status yang sama -> tidak perlu apa-apa
                      if (targetIndex == safeCurrentIndex) return;

                      // ====== ATURAN NAIK (FORWARD) ======
                      if (targetIndex > safeCurrentIndex) {
                        // hanya boleh naik 1 langkah (anti loncat)
                        if (targetIndex != safeCurrentIndex + 1) {
                          _showInfo('Tidak bisa loncat status. Naikkan satu per satu.', kBoxMenuRedColor);
                          return;
                        }
                        _updateStatus(status);
                        return;
                      }

                      // ====== ATURAN TURUN (BACKWARD) ======
                      if (targetIndex < safeCurrentIndex) {
                        final ok = await _confirmBackStatus(
                          from: _currentStatus,
                          to: status,
                        );
                        if (!ok) return;

                        _updateStatus(status);
                        _showInfo('Status berhasil dikembalikan', kBoxMenuGreenColor);
                        return;
                      }
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive ? status.color : Colors.grey[200],
                        shape: BoxShape.circle,
                        border: isCurrent ? Border.all(color: status.color, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.shortText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: primaryTextStyle.copyWith(
                      fontSize: 9,
                      fontWeight: isCurrent ? bold : regular,
                      color: isActive ? status.color : Colors.grey,
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildTindakanSection() {
    final allTindakan = _tindakanByJenis;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tindakan Servis',
            style: primaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allTindakan.map((tindakan) {
              final isSelected = _selectedTindakan.contains(tindakan);
              return FilterChip(
                label: Text(_getTindakanText(tindakan)),
                selected: isSelected,
                onSelected: (_) => _toggleTindakan(tindakan),
                selectedColor: kPrimaryColor,
                backgroundColor: kBackgroundColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : kPrimaryColor,
                ),
              );
            }).toList(),
          ),
        ],
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

  Widget _buildBiayaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biaya Servis',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _biayaServisController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Biaya Jasa',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _biayaSukuCadangController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Biaya Sparepart',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimaryColor.withValues(alpha:0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Biaya',
                  style: primaryTextStyle.copyWith(fontWeight: bold),
                ),
                Text(
                  'Rp ${_calculateTotalBiaya()}',
                  style: primaryTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalBiaya() {
    try {
      final biayaServis = double.tryParse(_biayaServisController.text) ?? 0;
      final biayaSukuCadang = double.tryParse(_biayaSukuCadangController.text) ?? 0;
      return (biayaServis + biayaSukuCadang).toInt().toString();
    } catch (e) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Detail Servis', style: titleWhiteTextStyle.copyWith(fontSize: 18)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentStatus == ServisStatus.menungguKonfirmasi)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {},
              tooltip: 'Menunggu Konfirmasi',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Lokasi & AC
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lokasi.nama,
                          style: primaryTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      widget.lokasi.alamat,
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: kGreyColor.withValues(alpha:0.2)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.ac_unit_rounded, color: kSecondaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.ac.nama,
                          style: primaryTextStyle.copyWith(fontWeight: medium),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      '${widget.ac.merk} • ${widget.ac.type} • ${widget.ac.kapasitas}',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Stepper
            _buildStatusStepper(),
            const SizedBox(height: 16),

            // Tindakan Section
            _buildTindakanSection(),
            const SizedBox(height: 16),

            // Foto Sebelum
            _buildImageGrid(
              _fotoSebelum,
              'Foto Kondisi Sebelum Servis',
                  () => _pickImage(_fotoSebelum),
            ),

            // Diagnosa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diagnosa & Catatan',
                    style: primaryTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diagnosaController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Diagnosa Masalah',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Catatan Tambahan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Biaya Section
            // _buildBiayaSection(),
            // const SizedBox(height: 16),

            // Foto Suku Cadang
            _buildImageGrid(
              _fotoSukuCadang,
              'Foto Suku Cadang Diganti',
                  () => _pickImage(_fotoSukuCadang),
            ),

            // Foto Sesudah
            _buildImageGrid(
              _fotoSesudah,
              'Foto Kondisi Setelah Servis',
                  () => _pickImage(_fotoSesudah),
            ),

            // Tombol Kirim Laporan
            if (_currentStatus.index >= ServisStatus.sedangDiperiksa.index &&
                _currentStatus.index < ServisStatus.menungguKonfirmasi.index)
              ElevatedButton(
                onPressed: _kirimLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Kirim Laporan ke Owner',
                      style: whiteTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}