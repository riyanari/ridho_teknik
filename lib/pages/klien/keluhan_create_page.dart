// lib/pages/klien/keluhan_create_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ac_model.dart';
import '../../models/keluhan_model.dart';
import '../../models/lokasi_model.dart';
import '../../theme/theme.dart';

class KeluhanCreatePage extends StatefulWidget {
  final AcModel ac;
  final LokasiModel lokasi;
  const KeluhanCreatePage({super.key, required this.ac, required this.lokasi});

  @override
  State<KeluhanCreatePage> createState() => _KeluhanCreatePageState();
}

class _KeluhanCreatePageState extends State<KeluhanCreatePage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  Prioritas _prioritas = Prioritas.sedang;
  final List<String> _fotoKeluhan = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _fotoKeluhan.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _fotoKeluhan.removeAt(index);
    });
  }

  void _submitKeluhan() {
    if (_judulController.text.trim().isEmpty) {
      _showSnackBar('Judul keluhan harus diisi', kBoxMenuRedColor);
      return;
    }

    if (_deskripsiController.text.trim().isEmpty) {
      _showSnackBar('Deskripsi keluhan harus diisi', kBoxMenuRedColor);
      return;
    }

    // Simulasi: Pilih servicer otomatis berdasarkan prioritas
    String? assignedServicerId;
    if (_prioritas == Prioritas.darurat || _prioritas == Prioritas.tinggi) {
      assignedServicerId = 'S1'; // Servicer khusus darurat
    }

    final keluhan = KeluhanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lokasiId: widget.lokasi.id,
      acId: widget.ac.id,
      judul: _judulController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      status: KeluhanStatus.diajukan, // Otomatis status "Diajukan"
      prioritas: _prioritas,
      tanggalDiajukan: DateTime.now(),
      assignedTo: assignedServicerId, // Bisa null, nanti di-assign admin
      catatanServicer: null, // Akan diisi servicer nanti
      fotoKeluhan: _fotoKeluhan,
    );

    // TODO: Simpan ke database/local storage
    print('Keluhan dibuat: ${keluhan.judul}');

    _showSnackBar('Keluhan berhasil diajukan!', kBoxMenuGreenColor);

    // Navigasi kembali dengan data
    Navigator.pop(context, keluhan);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: whiteTextStyle),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFotoGrid() {
    if (_fotoKeluhan.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Foto Keluhan:', style: primaryTextStyle.copyWith(fontWeight: bold)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _fotoKeluhan.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_fotoKeluhan[index] as dynamic),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Keluhan'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            _buildHeaderInfo(),
            const SizedBox(height: 24),

            // Form Keluhan
            _buildKeluhanForm(),
            const SizedBox(height: 24),

            // Tombol Submit
            _buildSubmitButton(),
            const SizedBox(height: 24),

            // Info Proses
            _buildProcessInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                  color: kPrimaryColor.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lokasi.nama,
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lokasi.alamat,
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: kGreyColor.withValues(alpha:0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.ac_unit, color: kSecondaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ac.nama,
                      style: primaryTextStyle.copyWith(fontWeight: medium),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.ac.merk} • ${widget.ac.type} • ${widget.ac.kapasitas}',
                      style: greyTextStyle.copyWith(fontSize: 12),
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

  Widget _buildKeluhanForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Keluhan',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Isi form berikut untuk mengajukan keluhan',
          style: greyTextStyle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Judul
        Text('Judul Keluhan*', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        TextField(
          controller: _judulController,
          decoration: InputDecoration(
            hintText: 'Contoh: AC tidak dingin, AC berisik, dll.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kGreyColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Deskripsi
        Text('Deskripsi Keluhan*', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        TextField(
          controller: _deskripsiController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Jelaskan keluhan secara detail...\nContoh: AC tidak dingin sejak 2 hari yang lalu, suara berisik dari unit outdoor, dll.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kGreyColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Prioritas
        Text('Tingkat Prioritas', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Prioritas.values.map((prioritas) {
            final isSelected = _prioritas == prioritas;
            return ChoiceChip(
              label: Text(
                _getPrioritasText(prioritas),
                style: TextStyle(
                  color: isSelected ? Colors.white : _getPrioritasColor(prioritas),
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _prioritas = prioritas),
              selectedColor: _getPrioritasColor(prioritas),
              backgroundColor: _getPrioritasColor(prioritas).withValues(alpha:0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? _getPrioritasColor(prioritas)
                      : _getPrioritasColor(prioritas).withValues(alpha:0.3),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Foto
        Text('Foto Pendukung', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        Text(
          'Unggah foto untuk membantu teknisi memahami masalah (maks. 5 foto)',
          style: greyTextStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _fotoKeluhan.length >= 5
              ? null
              : _pickImage,
          icon: Icon(
            Icons.add_photo_alternate,
            color: _fotoKeluhan.length >= 5 ? kGreyColor : kPrimaryColor,
          ),
          label: Text(
            'Tambah Foto (${_fotoKeluhan.length}/5)',
            style: primaryTextStyle.copyWith(
              color: _fotoKeluhan.length >= 5 ? kGreyColor : kPrimaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            side: BorderSide(
              color: _fotoKeluhan.length >= 5
                  ? kGreyColor.withValues(alpha:0.5)
                  : kPrimaryColor,
            ),
          ),
        ),
        _buildFotoGrid(),
        const SizedBox(height: 16),

        // Catatan Tambahan
        Text('Catatan Tambahan', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        TextField(
          controller: _catatanController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan lain jika diperlukan...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kGreyColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitKeluhan,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send_rounded, size: 20),
          const SizedBox(width: 12),
          Text(
            'Ajukan Keluhan',
            style: whiteTextStyle.copyWith(
              fontSize: 16,
              fontWeight: bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBoxMenuLightBlueColor.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBoxMenuLightBlueColor.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: kBoxMenuLightBlueColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Proses Setelah Pengajuan',
                style: primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProcessStep(
            number: 1,
            title: 'Keluhan Diajukan',
            description: 'Keluhan Anda akan masuk ke sistem dengan status "Diajukan"',
          ),
          _buildProcessStep(
            number: 2,
            title: 'Review oleh Admin',
            description: 'Admin akan meninjau dan menugaskan teknisi yang sesuai',
          ),
          _buildProcessStep(
            number: 3,
            title: 'Penugasan Teknisi',
            description: 'Teknisi akan menghubungi Anda untuk konfirmasi jadwal',
          ),
          _buildProcessStep(
            number: 4,
            title: 'Proses Perbaikan',
            description: 'Teknisi akan datang ke lokasi untuk melakukan perbaikan',
          ),
          _buildProcessStep(
            number: 5,
            title: 'Selesai',
            description: 'Setelah perbaikan selesai, status akan berubah menjadi "Selesai"',
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep({
    required int number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kBoxMenuLightBlueColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: whiteTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: bold,
                ),
              ),
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
                    fontSize: 14,
                    fontWeight: medium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPrioritasText(Prioritas prioritas) {
    switch (prioritas) {
      case Prioritas.rendah:
        return 'Rendah';
      case Prioritas.sedang:
        return 'Sedang';
      case Prioritas.tinggi:
        return 'Tinggi';
      case Prioritas.darurat:
        return 'Darurat';
    }
  }

  Color _getPrioritasColor(Prioritas prioritas) {
    switch (prioritas) {
      case Prioritas.rendah:
        return Colors.green;
      case Prioritas.sedang:
        return Colors.orange;
      case Prioritas.tinggi:
        return Colors.red;
      case Prioritas.darurat:
        return Colors.red[900]!;
    }
  }
}