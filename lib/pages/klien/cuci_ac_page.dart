// lib/pages/klien/cuci_ac_page.dart
import 'package:flutter/material.dart';
import 'package:ridho_teknik/models/ac_model.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/theme/theme.dart';

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

  void _submitRequest() {
    // TODO: Implement API call untuk cuci AC
    // Kirim permintaan cuci AC untuk semua AC di lokasi ini

    print('Submitting cuci AC request for:');
    print('Lokasi: ${widget.lokasi.id} - ${widget.lokasi.nama}');
    print('Jumlah AC: ${widget.acList.length}');
    print('AC IDs: ${widget.acList.map((ac) => ac.id).toList()}');
    print('Tanggal: $_preferredDate');
    print('Waktu: $_preferredTime');
    print('Catatan: ${_catatanController.text}');

    // Simulasi sukses
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permintaan cuci AC berhasil dikirim!'),
        backgroundColor: Colors.green,
      ),
    );

    // Kembali ke halaman sebelumnya setelah delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Cuci AC'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informasi Lokasi
          Card(
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
                        '${widget.acList.length} AC akan dicuci',
                        style: primaryTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Daftar AC yang akan dicuci
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AC yang akan dicuci:',
                    style: primaryTextStyle.copyWith(fontWeight: bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: widget.acList.length,
                      itemBuilder: (context, index) {
                        final ac = widget.acList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor.withValues(alpha:0.1),
                            child: Icon(Icons.ac_unit, size: 20, color: kPrimaryColor),
                          ),
                          title: Text(ac.nama, style: primaryTextStyle),
                          subtitle: Text(
                            '${ac.merk} • ${ac.type} • ${ac.kapasitas}',
                            style: greyTextStyle.copyWith(fontSize: 12),
                          ),
                          trailing: Icon(Icons.check_circle, color: Colors.green),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tanggal & Waktu
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu Kunjungan',
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
          ),
          const SizedBox(height: 20),

          // Catatan Tambahan
          Card(
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
          ),
          const SizedBox(height: 30),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Text(
                'KIRIM PERMINTAAN CUCI AC',
                style: whiteTextStyle.copyWith(fontWeight: bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}