// lib/pages/klien/cuci_ac_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/ac_model.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:ridho_teknik/providers/client_servis_provider.dart';

class CuciAcPage extends StatefulWidget {
  final LokasiModel lokasi;
  final List<AcModel> acList;

  const CuciAcPage({
    super.key,
    required this.lokasi,
    required this.acList,
  });

  @override
  State<CuciAcPage> createState() => _CuciAcPageState();
}

class _CuciAcPageState extends State<CuciAcPage> {
  final TextEditingController _catatanController = TextEditingController();
  DateTime _preferredDate = DateTime.now();
  TimeOfDay _preferredTime = TimeOfDay.now();

  bool _semuaAc = true;
  List<int> _selectedAcIds = [];

  @override
  void initState() {
    super.initState();

    // Default: pilih semua AC (convert id String -> int)
    _selectedAcIds = widget.acList
        .map((ac) => int.tryParse(ac.id))
        .whereType<int>()
        .toList();

    _semuaAc = _selectedAcIds.length == widget.acList.length;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _preferredDate) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _preferredTime) {
      setState(() {
        _preferredTime = picked;
      });
    }
  }

  void _toggleAcSelection(int acId) {
    setState(() {
      if (_selectedAcIds.contains(acId)) {
        _selectedAcIds.remove(acId);
      } else {
        _selectedAcIds.add(acId);
      }

      _semuaAc = _selectedAcIds.length == widget.acList.length;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_semuaAc) {
        _selectedAcIds.clear();
      } else {
        _selectedAcIds = widget.acList
            .map((ac) => int.tryParse(ac.id))
            .whereType<int>()
            .toList();
      }
      _semuaAc = !_semuaAc;
    });
  }

  Future<void> _submitRequest(BuildContext context) async {
    if (_selectedAcIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih minimal 1 AC untuk dicuci'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Akses provider
    final provider = Provider.of<ClientServisProvider>(context, listen: false);

    try {
      print('Submitting cuci AC request...');

      // Format tanggal_berkunjung untuk API (format Y-m-d H:i:s)
      final tanggalBerkunjung = DateTime(
        _preferredDate.year,
        _preferredDate.month,
        _preferredDate.day,
        _preferredTime.hour,
        _preferredTime.minute,
      );

      // Format ke string untuk API
      final tanggalBerkunjungStr = tanggalBerkunjung.toIso8601String();

      // Panggil method requestCuci dari provider dengan tanggal_berkunjung
      await provider.requestCuci(
        locationId: widget.lokasi.id,
        semuaAc: _semuaAc,
        acUnits: !_semuaAc ? _selectedAcIds : null,
        catatan: _catatanController.text.isNotEmpty
            ? _catatanController.text
            : null,
        tanggalBerkunjung: tanggalBerkunjungStr, // Kirim tanggal berkunjung
      );

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permintaan cuci AC berhasil dikirim!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Kembali ke halaman sebelumnya setelah delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, true); // Return true untuk refresh data
      });

    } catch (e) {
      print('Error submitting request: $e');

      // Tampilkan error dari provider jika ada
      if (provider.submitError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.submitError!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Akses provider untuk state loading
    final provider = Provider.of<ClientServisProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Request Cuci AC'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Informasi Lokasi
              _buildLocationCard(),
              const SizedBox(height: 20),

              // Pilihan AC
              _buildAcSelectionCard(),
              const SizedBox(height: 20),

              // Tanggal & Waktu
              _buildDateTimeCard(),
              const SizedBox(height: 20),

              // Catatan Tambahan
              _buildNoteCard(),
              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(provider),
              const SizedBox(height: 20),
            ],
          ),

          // Loading overlay saat submit
          if (provider.submittingCuci)
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

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.lokasi.nama,
                    style: primaryTextStyle.copyWith(fontWeight: bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.lokasi.alamat,
              style: greyTextStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.ac_unit, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${widget.acList.length} AC tersedia',
                  style: primaryTextStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20,20,20,0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.ac_unit,
                  color: kPrimaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pemilihan AC',
                    style: primaryTextStyle.copyWith(
                      fontWeight: bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: kPrimaryColor.withValues(alpha:0.1),
                  label: Text(
                    '${_selectedAcIds.length}/${widget.acList.length}',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih unit AC yang ingin dicuci',
              style: greyTextStyle.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Quick selection buttons - hanya tombol "Semua" yang bisa toggle
            Container(
              alignment: Alignment.centerLeft,
              child: _buildQuickSelectButton(
                label: _semuaAc ? 'Semua Dipilih' : 'Pilih Semua',
                icon: _semuaAc ? Icons.check_box : Icons.check_box_outline_blank,
                isActive: _semuaAc,
                onTap: _toggleSelectAll, // Tombol toggle langsung panggil method
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // AC List dengan search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cari AC...',
                      style: greyTextStyle.copyWith(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${widget.acList.length} unit',
                    style: greyTextStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List AC
            SizedBox(
              height: 280,
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: widget.acList.length,
                itemBuilder: (context, index) {
                  final ac = widget.acList[index];
                  final acId = int.tryParse(ac.id);
                  final isSelected = acId != null && _selectedAcIds.contains(acId);

                  return _buildAcListItem(ac, isSelected, acId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? kPrimaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha:0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : kPrimaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : kPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcListItem(AcModel ac, bool isSelected, int? acId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? kPrimaryColor : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: acId != null ? () => _toggleAcSelection(acId) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox dengan border biru saat dipilih
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                      : null,
                ),

                const SizedBox(width: 12),

                // AC Icon - warna biru saat dipilih
                // Container(
                //   width: 40,
                //   height: 40,
                //   decoration: BoxDecoration(
                //     color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   child: Icon(
                //     Icons.ac_unit,
                //     size: 22,
                //     color: isSelected ? Colors.white : Colors.grey.shade600,
                //   ),
                // ),
                //
                // const SizedBox(width: 12),

                // AC Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ac.nama,
                        style: primaryTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected ? kPrimaryColor : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildTag(
                            text: ac.merk,
                            bg: isSelected ? kPrimaryColor.withValues(alpha:0.1) : Colors.grey.shade100,
                            border: isSelected ? kPrimaryColor.withValues(alpha:0.3) : null,
                            fg: isSelected ? kPrimaryColor : Colors.grey.shade700,
                          ),
                          _buildTag(
                            text: ac.type,
                            bg: Colors.blue.shade50,
                            border: isSelected ? Colors.blue.shade300.withValues(alpha:0.3) : null,
                            fg: isSelected ? Colors.blue.shade800 : Colors.blue.shade700,
                          ),
                          _buildTag(
                            text: ac.kapasitas,
                            bg: kPrimaryColor.withValues(alpha:isSelected ? 0.2 : 0.1),
                            border: isSelected ? kPrimaryColor.withValues(alpha:0.4) : null,
                            fg: kPrimaryColor,
                            bold: true,
                          ),

                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.ac_unit,
                    size: 22,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),

                // // Status indicator - biru saat dipilih
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: isSelected ? kPrimaryColor.withValues(alpha:0.1) : Colors.grey.shade100,
                //     borderRadius: BorderRadius.circular(20),
                //     border: Border.all(
                //       color: isSelected ? kPrimaryColor.withValues(alpha:0.3) : Colors.transparent,
                //     ),
                //   ),
                //   child: Text(
                //     isSelected ? 'Dipilih' : 'Tersedia',
                //     style: TextStyle(
                //       color: isSelected ? kPrimaryColor : Colors.grey.shade600,
                //       fontSize: 11,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color bg,
    Color? border,
    required Color fg,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu Kunjungan (Preferensi)',
              style: primaryTextStyle.copyWith(fontWeight: bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal', style: greyTextStyle.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: kPrimaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}',
                                style: primaryTextStyle,
                              ),
                            ],
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
                      Text('Waktu', style: greyTextStyle.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: kPrimaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _preferredTime.format(context),
                                style: primaryTextStyle,
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
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan Tambahan (Opsional)',
              style: primaryTextStyle.copyWith(fontWeight: bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: AC perlu dibersihkan secara menyeluruh, ada jamur, dll.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ClientServisProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.submittingCuci ? null : () => _submitRequest(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: provider.submittingCuci
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'KIRIM PERMINTAAN CUCI AC',
          style: whiteTextStyle.copyWith(fontWeight: bold),
        ),
      ),
    );
  }
}