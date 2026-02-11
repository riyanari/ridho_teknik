import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

class AddAcUnitDialog extends StatefulWidget {
  final int locationId;

  const AddAcUnitDialog({super.key, required this.locationId});

  @override
  State<AddAcUnitDialog> createState() => _AddAcUnitDialogState();
}

class _AddAcUnitDialogState extends State<AddAcUnitDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameC = TextEditingController();
  final _brandC = TextEditingController();
  final _typeC = TextEditingController();
  final _capacityC = TextEditingController();
  DateTime? _lastService; // nullable sesuai backend

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameC.dispose();
    _brandC.dispose();
    _typeC.dispose();
    _capacityC.dispose();
    super.dispose();
  }

  Future<void> _pickLastService() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastService ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now.add(const Duration(days: 365)), // boleh future kalau kamu mau
      helpText: 'Pilih tanggal terakhir service',
    );

    if (picked == null) return;

    if (!mounted) return;
    setState(() => _lastService = picked);
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

      final payload = <String, dynamic>{
        'location_id': widget.locationId,
        'name': _nameC.text.trim(),
        if (_brandC.text.trim().isNotEmpty) 'brand': _brandC.text.trim(),
        if (_typeC.text.trim().isNotEmpty) 'type': _typeC.text.trim(),
        if (_capacityC.text.trim().isNotEmpty) 'capacity': _capacityC.text.trim(),
        if (_lastService != null) 'last_service': DateFormat('yyyy-MM-dd').format(_lastService!),
      };

      final newAc = await prov.createAcUnit(payload);

      if (!mounted) return;

      if (newAc != null) {
        Navigator.pop(context, true); // return true biar caller bisa refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Unit AC berhasil ditambahkan')),
        );
      } else {
        setState(() {
          _error = prov.submitError ?? 'Gagal menambahkan unit AC.';
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
    final lastServiceText = _lastService == null
        ? 'Opsional'
        : DateFormat('dd/MM/yyyy').format(_lastService!);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tambah Unit AC Baru'),
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

                TextFormField(
                  controller: _nameC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nama Unit AC',
                    hintText: 'Contoh: AC Ruang Meeting',
                    prefixIcon: const Icon(Iconsax.cpu),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama AC wajib diisi';
                    if (v.trim().length < 3) return 'Minimal 3 karakter';
                    if (v.trim().length > 255) return 'Maksimal 255 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _brandC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Merk (opsional)',
                    hintText: 'Contoh: Daikin',
                    prefixIcon: const Icon(Iconsax.tag),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().length > 100) return 'Maksimal 100 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _typeC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Type (opsional)',
                    hintText: 'Contoh: Split / Cassette',
                    prefixIcon: const Icon(Iconsax.box),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().length > 100) return 'Maksimal 100 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _capacityC,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Kapasitas (opsional)',
                    hintText: 'Contoh: 1 PK / 2 PK',
                    prefixIcon: const Icon(Iconsax.flash_1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().length > 50) return 'Maksimal 50 karakter';
                    return null;
                  },
                  onFieldSubmitted: (_) => _saving ? null : _submit(),
                ),
                const SizedBox(height: 12),

                // Last service picker (opsional)
                InkWell(
                  onTap: _saving ? null : _pickLastService,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.calendar_1),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Terakhir Service: $lastServiceText',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        if (_lastService != null)
                          IconButton(
                            onPressed: _saving ? null : () => setState(() => _lastService = null),
                            icon: const Icon(Iconsax.close_circle),
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ),
                ),
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
