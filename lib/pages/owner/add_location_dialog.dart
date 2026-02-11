import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../providers/owner_master_provider.dart';
import '../../theme/theme.dart';

class AddLocationDialog extends StatefulWidget {
  final int clientId;
  const AddLocationDialog({super.key, required this.clientId});

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameC = TextEditingController();
  final _addressC = TextEditingController();

  // optional fields
  final _latC = TextEditingController();
  final _lngC = TextEditingController();
  final _placeIdC = TextEditingController();
  final _gmapsUrlC = TextEditingController();

  bool _saving = false;
  String? _error;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _nameC.dispose();
    _addressC.dispose();
    _latC.dispose();
    _lngC.dispose();
    _placeIdC.dispose();
    _gmapsUrlC.dispose();
    super.dispose();
  }

  double? _asDouble(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.')); // jaga-jaga user pakai koma
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final prov = context.read<OwnerMasterProvider>();

      final lat = _asDouble(_latC.text);
      final lng = _asDouble(_lngC.text);

      final body = <String, dynamic>{
        'client_id': widget.clientId,
        'name': _nameC.text.trim(),
        'address': _addressC.text.trim(),
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
        if (_placeIdC.text.trim().isNotEmpty) 'place_id': _placeIdC.text.trim(),
        if (_gmapsUrlC.text.trim().isNotEmpty) 'gmaps_url': _gmapsUrlC.text.trim(),
      };

      final newLoc = await prov.createLocation(body);

      if (!mounted) return;

      if (newLoc != null) {
        await prov.fetchLocations(clientId: widget.clientId);

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Lokasi berhasil ditambahkan')),
        );
      } else {
        setState(() {
          final msg = prov.error; // nullable
          _error = (msg != null && msg.isNotEmpty) ? msg : 'Gagal menambahkan lokasi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tambah Lokasi Baru'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // name
                TextFormField(
                  controller: _nameC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nama Lokasi',
                    hintText: 'Contoh: Kantor PT Maju Jaya',
                    prefixIcon: const Icon(Iconsax.location),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama lokasi wajib diisi';
                    if (v.trim().length < 3) return 'Minimal 3 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // address
                TextFormField(
                  controller: _addressC,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    hintText: 'Contoh: Gedung Graha Lt. 8, Jakarta Selatan',
                    prefixIcon: const Icon(Iconsax.map),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Alamat wajib diisi';
                    if (v.trim().length < 8) return 'Alamat terlalu pendek';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // advanced toggle
                InkWell(
                  onTap: _saving ? null : () => setState(() => _showAdvanced = !_showAdvanced),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.gps, size: 18, color: kPrimaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _showAdvanced ? 'Sembunyikan data Maps' : 'Isi data Maps (opsional)',
                            style: primaryTextStyle.copyWith(fontSize: 12, fontWeight: medium),
                          ),
                        ),
                        Icon(
                          _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        )
                      ],
                    ),
                  ),
                ),

                if (_showAdvanced) ...[
                  const SizedBox(height: 12),

                  // latitude & longitude
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            hintText: '-6.2279000',
                            prefixIcon: const Icon(Iconsax.location_tick),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            final d = _asDouble(v ?? '');
                            if ((v ?? '').trim().isEmpty) return null; // optional
                            if (d == null) return 'Latitude tidak valid';
                            if (d < -90 || d > 90) return 'Range -90..90';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lngC,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            hintText: '106.8105000',
                            prefixIcon: const Icon(Iconsax.location_tick),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            final d = _asDouble(v ?? '');
                            if ((v ?? '').trim().isEmpty) return null; // optional
                            if (d == null) return 'Longitude tidak valid';
                            if (d < -180 || d > 180) return 'Range -180..180';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // place_id
                  TextFormField(
                    controller: _placeIdC,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Place ID (opsional)',
                      hintText: 'ChIJ...',
                      prefixIcon: const Icon(Iconsax.building_3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // gmaps_url
                  TextFormField(
                    controller: _gmapsUrlC,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Google Maps URL (opsional)',
                      hintText: 'https://maps.google.com/?q=...',
                      prefixIcon: const Icon(Iconsax.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onFieldSubmitted: (_) => _saving ? null : _submit(),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return null;
                      final ok = t.startsWith('http://') || t.startsWith('https://');
                      if (!ok) return 'URL harus diawali http/https';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
