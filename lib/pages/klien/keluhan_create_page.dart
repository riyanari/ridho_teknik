// lib/pages/klien/keluhan_create_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import tambahan untuk initializeDateFormatting
import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_servis_provider.dart';
import '../../theme/theme.dart';

class KeluhanCreatePage extends StatefulWidget {
  final AcModel ac;
  final LokasiModel lokasi;
  const KeluhanCreatePage({super.key, required this.ac, required this.lokasi});

  @override
  State<KeluhanCreatePage> createState() => _KeluhanCreatePageState();
}

class _KeluhanCreatePageState extends State<KeluhanCreatePage> {
  final TextEditingController _keluhanController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  String _priority = 'sedang';
  final List<File> _fotoKeluhan = [];
  final ImagePicker _picker = ImagePicker();
  DateTime? _selectedDate;
  bool _isDateFormattingInitialized = false;

  // Priority options
  final List<Map<String, dynamic>> priorityOptions = [
    {'value': 'rendah', 'label': 'Rendah', 'color': Colors.green, 'icon': Icons.low_priority},
    {'value': 'sedang', 'label': 'Sedang', 'color': Colors.orange, 'icon': Icons.priority_high},
    {'value': 'tinggi', 'label': 'Tinggi', 'color': Colors.red, 'icon': Icons.warning},
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi date formatting
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      // Inisialisasi date formatting untuk locale Indonesia
      await initializeDateFormatting('id_ID');
      setState(() {
        _isDateFormattingInitialized = true;
      });

      // Set tanggal default setelah formatting diinisialisasi
      _selectedDate = DateTime.now().add(const Duration(days: 3));
      _tanggalController.text = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate!);
    } catch (e) {
      print('Error initializing date formatting: $e');
      // Fallback ke format tanggal sederhana jika inisialisasi gagal
      _selectedDate = DateTime.now().add(const Duration(days: 3));
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    _catatanController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!_isDateFormattingInitialized) {
      _showSnackBar('Sedang memuat data tanggal...', Colors.orange);
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)), // Minimal besok
      lastDate: DateTime.now().add(const Duration(days: 30)), // Maksimal 30 hari ke depan
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(picked);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (_fotoKeluhan.length >= 5) {
      _showSnackBar('Maksimal 5 foto keluhan', Colors.orange);
      return;
    }

    // Show modern bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan drag indicator
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Sumber Foto',
                      style: primaryTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: kGreyColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Camera Option
                    _buildOptionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'Ambil Foto',
                      subtitle: 'Ambil foto menggunakan kamera',
                      color: kPrimaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Gallery Option
                    _buildOptionCard(
                      icon: Icons.photo_library_rounded,
                      title: 'Pilih dari Galeri',
                      subtitle: 'Pilih foto dari galeri perangkat',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),

              // Cancel Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kGreyColor,
                      side: BorderSide(color: kGreyColor.withValues(alpha:0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Batal',
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kGreyColor,
                      ),
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

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha:0.1), width: 1.5),
          ),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha:0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        setState(() {
          _fotoKeluhan.add(File(image.path));
        });

        if (_fotoKeluhan.length >= 5) {
          _showSnackBar('Maksimal 5 foto telah tercapai', Colors.orange);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Gagal mengambil gambar: $e', Colors.red);
    }
  }

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Foto', style: primaryTextStyle.copyWith(fontWeight: bold)),
        content: Text('Apakah Anda yakin ingin menghapus foto ini?', style: primaryTextStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: kGreyColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _fotoKeluhan.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPerbaikan() async {
    if (_keluhanController.text.trim().isEmpty) {
      _showSnackBar('Keluhan harus diisi', kBoxMenuRedColor);
      return;
    }

    if (_keluhanController.text.trim().length < 10) {
      _showSnackBar('Keluhan minimal 10 karakter', kBoxMenuRedColor);
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Silakan pilih tanggal kunjungan', kBoxMenuRedColor);
      return;
    }

    final provider = Provider.of<ClientServisProvider>(context, listen: false);

    try {
      // Format tanggal untuk API
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // Panggil provider untuk request perbaikan (dengan parameter tanggal)
      await provider.requestPerbaikan(
        locationId: widget.lokasi.id,
        acUnitId: widget.ac.id,
        keluhan: _keluhanController.text.trim(),
        priority: _priority,
        tanggalBerkunjung: formattedDate, // Tambahkan tanggal kunjungan
        fotoKeluhan: _fotoKeluhan.isNotEmpty ? _fotoKeluhan : null,
      );

      _showSnackBar('Permintaan perbaikan berhasil dikirim!', kBoxMenuGreenColor);

      // Kembali ke halaman sebelumnya
      Navigator.pop(context, true);

    } catch (e) {
      if (provider.submitPerbaikanError != null) {
        _showSnackBar(provider.submitPerbaikanError!, Colors.red);
      } else {
        _showSnackBar('Gagal mengirim permintaan: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: whiteTextStyle),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildFotoGrid() {
    if (_fotoKeluhan.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Foto Keluhan:', style: primaryTextStyle.copyWith(fontWeight: bold)),
            Text(
              '${_fotoKeluhan.length}/5',
              style: greyTextStyle.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _fotoKeluhan.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGreyColor.withValues(alpha:0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  children: [
                    // Foto
                    Positioned.fill(
                      child: Image.file(
                        _fotoKeluhan[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: kGreyColor.withValues(alpha:0.1),
                            child: Icon(Icons.broken_image, color: kGreyColor),
                          );
                        },
                      ),
                    ),

                    // Overlay gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha:0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Nomor urut
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: whiteTextStyle.copyWith(
                            fontSize: 12,
                            fontWeight: bold,
                          ),
                        ),
                      ),
                    ),

                    // Tombol hapus
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (_fotoKeluhan.length < 5)
          Text(
            'Ketuk foto untuk menghapus',
            style: greyTextStyle.copyWith(fontSize: 12, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientServisProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Perbaikan AC'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                _buildHeaderInfo(),
                const SizedBox(height: 24),

                // Form Perbaikan
                _buildPerbaikanForm(),
                const SizedBox(height: 24),

                // Tombol Submit
                _buildSubmitButton(provider),
                const SizedBox(height: 24),

                // Info Proses
                _buildProcessInfo(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Loading overlay untuk inisialisasi date formatting
          if (!_isDateFormattingInitialized)
            Container(
              color: Colors.black.withValues(alpha:0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Menyiapkan formulir...',
                      style: whiteTextStyle,
                    ),
                  ],
                ),
              ),
            ),

          // Loading overlay untuk submit
          if (provider.submittingPerbaikan && _isDateFormattingInitialized)
            Container(
              color: Colors.black.withValues(alpha:0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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

  Widget _buildPerbaikanForm() {
    // Tampilkan loading jika date formatting belum diinisialisasi
    if (!_isDateFormattingInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Perbaikan',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Isi form berikut untuk mengajukan perbaikan AC',
          style: greyTextStyle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Keluhan
        Text('Keluhan*', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        TextField(
          controller: _keluhanController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Jelaskan keluhan secara detail...\nContoh: AC tidak dingin sejak 2 hari yang lalu, suara berisik dari unit outdoor, ada kebocoran air, dll.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kGreyColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kPrimaryColor),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),

        // Tanggal Kunjungan
        Text('Tanggal Kunjungan*', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tanggalController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Pilih tanggal kunjungan teknisi',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kGreyColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: kPrimaryColor),
            ),
            suffixIcon: IconButton(
              onPressed: _selectDate,
              icon: Icon(Icons.calendar_today, color: kPrimaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          onTap: _selectDate,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: kGreyColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Teknisi akan datang pada tanggal yang dipilih. Anda akan dihubungi untuk konfirmasi waktu.',
                style: greyTextStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Prioritas
        Text('Tingkat Prioritas', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: priorityOptions.map((option) {
            final isSelected = _priority == option['value'];
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option['icon'],
                    size: 12,
                    color: isSelected ? Colors.white : option['color'],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : option['color'],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _priority = option['value']),
              selectedColor: option['color'],
              backgroundColor: (option['color'] as Color).withValues(alpha:0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? option['color'] as Color
                      : (option['color'] as Color).withValues(alpha:0.3),
                  width: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Foto
        Text('Foto Keluhan', style: primaryTextStyle.copyWith(fontWeight: medium)),
        const SizedBox(height: 8),
        Text(
          'Unggah foto untuk membantu teknisi memahami masalah (maks. 5 foto)',
          style: greyTextStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Tombol tambah foto dengan opsi kamera/galeri
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _fotoKeluhan.length >= 5 ? null : _showImageSourceDialog,
            icon: Icon(
              Icons.add_a_photo,
              color: _fotoKeluhan.length >= 5 ? kGreyColor : kPrimaryColor,
              size: 20,
            ),
            label: Text(
              _fotoKeluhan.isEmpty ?
              'Tambah Foto' :
              'Tambah Foto Lain (${_fotoKeluhan.length}/5)',
              style: primaryTextStyle.copyWith(
                color: _fotoKeluhan.length >= 5 ? kGreyColor : kPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
              side: BorderSide(
                color: _fotoKeluhan.length >= 5
                    ? kGreyColor.withValues(alpha:0.3)
                    : kPrimaryColor,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
        ),
        _buildFotoGrid(),
      ],
    );
  }

  Widget _buildSubmitButton(ClientServisProvider provider) {
    // Jangan tampilkan tombol jika date formatting belum diinisialisasi
    if (!_isDateFormattingInitialized) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultRadius),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: provider.submittingPerbaikan ? null : _submitPerbaikan,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            elevation: 0,
          ),
          child: provider.submittingPerbaikan
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, size: 20),
              const SizedBox(width: 12),
              Text(
                'Ajukan Perbaikan',
                style: whiteTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessInfo() {
    // Jangan tampilkan jika date formatting belum diinisialisasi
    if (!_isDateFormattingInitialized) {
      return const SizedBox();
    }

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
              Icon(Icons.info_rounded, color: kBoxMenuLightBlueColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Proses Setelah Pengajuan',
                  style: primaryTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProcessStep(
            icon: Icons.send,
            title: 'Pengajuan Dikirim',
            description: 'Permintaan perbaikan Anda akan masuk ke sistem',
          ),
          _buildProcessStep(
            icon: Icons.calendar_today,
            title: 'Konfirmasi Jadwal',
            description: 'Teknisi akan menghubungi Anda untuk konfirmasi waktu kunjungan',
          ),
          _buildProcessStep(
            icon: Icons.admin_panel_settings,
            title: 'Review oleh Admin',
            description: 'Admin akan meninjau dan menugaskan teknisi',
          ),
          _buildProcessStep(
            icon: Icons.engineering,
            title: 'Kunjungan Teknisi',
            description: 'Teknisi akan datang ke lokasi sesuai jadwal',
          ),
          _buildProcessStep(
            icon: Icons.build,
            title: 'Proses Perbaikan',
            description: 'Teknisi akan melakukan diagnosis dan perbaikan',
          ),
          _buildProcessStep(
            icon: Icons.check_circle,
            title: 'Selesai & Konfirmasi',
            description: 'Setelah selesai, teknisi akan meminta konfirmasi Anda',
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBoxMenuLightBlueColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
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
                    fontWeight: FontWeight.w600,
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
}