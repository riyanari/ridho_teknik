import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

class AddRoomDialog extends StatefulWidget {
  final int locationId;
  final int? initialFloorNumber;

  const AddRoomDialog({
    super.key,
    required this.locationId,
    this.initialFloorNumber,
  });

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _codeC = TextEditingController();

  bool _saving = false;
  String? _error;

  int? _selectedFloorId;
  int? _selectedFloorNumber;

  List<Map<String, dynamic>> _floors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFloors();
    });
  }

  Future<void> _loadFloors() async {
    try {
      final provider = context.read<OwnerMasterProvider>();
      final floors = await provider.fetchFloors();

      if (!mounted) return;

      setState(() {
        _floors = floors;
      });

      if (widget.initialFloorNumber != null) {
        final matched = _floors.where(
              (e) => (e['number'] as int?) == widget.initialFloorNumber,
        );

        if (matched.isNotEmpty) {
          final floor = matched.first;
          setState(() {
            _selectedFloorId = floor['id'] as int?;
            _selectedFloorNumber = floor['number'] as int?;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data lantai';
      });
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _codeC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFloorId == null) {
      setState(() {
        _error = 'Pilih lantai terlebih dahulu';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final provider = context.read<OwnerMasterProvider>();

      final newRoom = await provider.createRoom(widget.locationId, {
        'name': _nameC.text.trim(),
        'floor_id': _selectedFloorId,
        if (_codeC.text.trim().isNotEmpty) 'code': _codeC.text.trim(),
      });

      if (!mounted) return;

      if (newRoom != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ruangan berhasil ditambahkan')),
        );
      } else {
        setState(() {
          _error = provider.submitError ?? 'Gagal menambahkan ruangan.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final floors = _floors;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Tambah Ruangan Baru'),
      content: SizedBox(
        width: double.maxFinite,
        child: floors.isEmpty
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
              ),
              child: const Text(
                'Belum ada data lantai yang bisa dipilih.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        )
            : Form(
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
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<int>(
                  initialValue: _selectedFloorId,
                  decoration: InputDecoration(
                    labelText: 'Pilih Lantai',
                    prefixIcon: const Icon(Iconsax.building),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: floors.map((floor) {
                    final id = floor['id'] as int;
                    final number = floor['number'] as int? ?? 0;
                    final name = (floor['name'] ?? '').toString();

                    final label = name.isNotEmpty
                        ? name
                        : (number > 0 ? name : 'Tanpa nama');

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                    final selected = floors.where(
                          (e) => e['id'] == value,
                    );

                    setState(() {
                      _selectedFloorId = value;
                      _selectedFloorNumber = selected.isNotEmpty
                          ? selected.first['number'] as int?
                          : null;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Lantai wajib dipilih';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameC,
                  textInputAction: TextInputAction.next,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Nama Ruangan',
                    hintText: 'Contoh: Kasir, Meeting, Server',
                    prefixIcon: const Icon(Iconsax.home_2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama ruangan wajib diisi';
                    }
                    if (v.trim().length < 2) {
                      return 'Minimal 2 karakter';
                    }
                    if (v.trim().length > 255) {
                      return 'Maksimal 255 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeC,
                  textInputAction: TextInputAction.done,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Kode Ruangan (opsional)',
                    hintText: 'Contoh: RM-01',
                    prefixIcon: const Icon(Iconsax.code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().length > 100) {
                      return 'Maksimal 100 karakter';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _saving ? null : _submit(),
                ),
                if (_selectedFloorNumber != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.building_4,
                          size: 16,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ruangan akan dibuat di Lantai $_selectedFloorNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
          onPressed: floors.isEmpty || _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}