// lib/pages/klien/lokasi_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/lokasi_model.dart';
import '../../theme/theme.dart';

class LokasiFormDialog extends StatefulWidget {
  final LokasiModel? initial;
  const LokasiFormDialog({super.key, this.initial});

  @override
  State<LokasiFormDialog> createState() => _LokasiFormDialogState();
}

class _LokasiFormDialogState extends State<LokasiFormDialog> {
  late final TextEditingController namaC;
  late final TextEditingController alamatC;
  final _formKey = GlobalKey<FormState>();
  final _namaFocus = FocusNode();
  final _alamatFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    namaC = TextEditingController(text: widget.initial?.nama ?? '');
    alamatC = TextEditingController(text: widget.initial?.alamat ?? '');
  }

  @override
  void dispose() {
    namaC.dispose();
    alamatC.dispose();
    _namaFocus.dispose();
    _alamatFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: defaultMargin,
          right: defaultMargin,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.initial == null ? 'Tambah Lokasi Baru' : 'Edit Lokasi',
                    style: primaryTextStyle.copyWith(fontSize: 18, fontWeight: bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: kGreyColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.initial == null
                    ? 'Tambahkan lokasi baru untuk manajemen AC'
                    : 'Perbarui informasi lokasi',
                style: greyTextStyle.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: namaC,
                focusNode: _namaFocus,
                decoration: InputDecoration(
                  labelText: 'Nama Lokasi',
                  labelStyle: greyTextStyle,
                  prefixIcon: Icon(Icons.business_rounded, color: kPrimaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kGreyColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kGreyColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: kBackgroundColor,
                ),
                style: primaryTextStyle,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama lokasi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: alamatC,
                focusNode: _alamatFocus,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap',
                  labelStyle: greyTextStyle,
                  prefixIcon: Icon(Icons.location_city_rounded, color: kPrimaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kGreyColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kGreyColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: kBackgroundColor,
                ),
                style: primaryTextStyle,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                        side: BorderSide(color: kGreyColor),
                      ),
                      child: Text('Batal', style: blackTextStyle.copyWith(fontWeight: medium)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final id = widget.initial?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString();
                          Navigator.pop(
                            context,
                            LokasiModel(
                              id: id,
                              nama: namaC.text.trim(),
                              alamat: alamatC.text.trim(),
                              jumlahAC: widget.initial?.jumlahAC ?? 0,
                              lastService: widget.initial?.lastService ?? DateTime.now(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        widget.initial == null ? 'Simpan' : 'Update',
                        style: whiteTextStyle.copyWith(fontWeight: bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}