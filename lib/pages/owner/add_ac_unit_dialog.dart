import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ridho_teknik/models/ac_brand_model.dart';
import 'package:ridho_teknik/models/ac_capacity_model.dart';
import 'package:ridho_teknik/models/ac_series_model.dart';
import 'package:ridho_teknik/models/ac_type_model.dart';
import 'package:ridho_teknik/providers/ac_master_provider.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

class AddAcUnitDialog extends StatefulWidget {
  final int roomId;

  const AddAcUnitDialog({
    super.key,
    required this.roomId,
  });

  @override
  State<AddAcUnitDialog> createState() => _AddAcUnitDialogState();
}

class _AddAcUnitDialogState extends State<AddAcUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();

  DateTime? _lastService;
  bool _saving = false;
  String? _error;

  int? _selectedBrandId;
  int? _selectedTypeId;
  int? _selectedSeriesId;
  int? _selectedCapacityId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final masterProv = context.read<AcMasterProvider>();
      masterProv.clearData();
      await masterProv.fetchFormOptions();
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _pickLastService() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastService ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal terakhir service',
    );

    if (picked == null) return;
    if (!mounted) return;

    setState(() {
      _lastService = picked;
    });
  }

  Future<void> _onBrandChanged(int? brandId) async {
    setState(() {
      _selectedBrandId = brandId;
      _selectedTypeId = null;
      _selectedSeriesId = null;
      _selectedCapacityId = null;
      _error = null;
    });

    if (brandId == null) return;

    final masterProv = context.read<AcMasterProvider>();
    masterProv.setSelectedBrand(brandId);
    await masterProv.fetchFormOptions(brandId: brandId);
  }

  Future<void> _onTypeChanged(int? typeId) async {
    setState(() {
      _selectedTypeId = typeId;
      _selectedSeriesId = null;
      _selectedCapacityId = null;
      _error = null;
    });

    final brandId = _selectedBrandId;
    if (brandId == null) return;

    final masterProv = context.read<AcMasterProvider>();
    masterProv.setSelectedType(typeId);

    await masterProv.fetchFormOptions(
      brandId: brandId,
      typeId: typeId,
    );
  }

  void _onSeriesChanged(int? seriesId, List<AcSeriesModel> seriesList) {
    final selected = seriesList.cast<AcSeriesModel?>().firstWhere(
          (e) => e?.id == seriesId,
      orElse: () => null,
    );

    setState(() {
      _selectedSeriesId = seriesId;
      _selectedCapacityId = selected?.capacityId;
      _error = null;
    });

    context.read<AcMasterProvider>().setSelectedSeries(seriesId);
    context.read<AcMasterProvider>().setSelectedCapacity(selected?.capacityId);
  }

  void _onCapacityChanged(int? capacityId) {
    setState(() {
      _selectedCapacityId = capacityId;
      _error = null;
    });

    context.read<AcMasterProvider>().setSelectedCapacity(capacityId);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final masterProv = context.read<AcMasterProvider>();
    final ownerProv = context.read<OwnerMasterProvider>();

    final AcBrandModel? selectedBrand = masterProv.brands.cast<AcBrandModel?>().firstWhere(
          (e) => e?.id == _selectedBrandId,
      orElse: () => null,
    );

    final AcTypeModel? selectedType = masterProv.types.cast<AcTypeModel?>().firstWhere(
          (e) => e?.id == _selectedTypeId,
      orElse: () => null,
    );

    final AcSeriesModel? selectedSeries = masterProv.series.cast<AcSeriesModel?>().firstWhere(
          (e) => e?.id == _selectedSeriesId,
      orElse: () => null,
    );

    final AcCapacityModel? selectedCapacity =
    masterProv.capacities.cast<AcCapacityModel?>().firstWhere(
          (e) => e?.id == _selectedCapacityId,
      orElse: () => null,
    );

    if (selectedBrand == null) {
      setState(() => _error = 'Merk wajib dipilih');
      return;
    }

    if (selectedType == null) {
      setState(() => _error = 'Tipe wajib dipilih');
      return;
    }

    if (selectedSeries == null) {
      setState(() => _error = 'Seri wajib dipilih');
      return;
    }

    if (selectedCapacity == null) {
      setState(() => _error = 'Kapasitas wajib dipilih');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final typeValue = '${selectedType.name}/${selectedSeries.series}';

      final payload = <String, dynamic>{
        'room_id': widget.roomId,
        'name': _nameC.text.trim(),
        'brand': selectedBrand.name,
        'type': typeValue,
        'capacity': selectedCapacity.name,
        if (_lastService != null)
          'last_service': DateFormat('yyyy-MM-dd').format(_lastService!),
      };

      final newAc = await ownerProv.createAcUnit(payload);

      if (!mounted) return;

      if (newAc != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Unit AC berhasil ditambahkan')),
        );
      } else {
        setState(() {
          _error = ownerProv.submitError ?? 'Gagal menambahkan unit AC.';
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastServiceText = _lastService == null
        ? 'Opsional'
        : DateFormat('dd/MM/yyyy').format(_lastService!);

    return Consumer<AcMasterProvider>(
      builder: (context, masterProv, _) {
        final brands = masterProv.brands;
        final types = masterProv.types;
        final series = masterProv.series;
        final capacities = masterProv.capacities;

        final loadingMaster = masterProv.isLoading && !_saving;
        final masterError = masterProv.error;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

                    if (masterError != null && masterError.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          masterError,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: _nameC,
                      textInputAction: TextInputAction.next,
                      enabled: !_saving,
                      decoration: _inputDecoration(
                        label: 'Nama Unit AC',
                        hint: 'Contoh: AC Ruang Meeting',
                        icon: Iconsax.cpu,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama AC wajib diisi';
                        }
                        if (v.trim().length < 3) {
                          return 'Minimal 3 karakter';
                        }
                        if (v.trim().length > 255) {
                          return 'Maksimal 255 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: _selectedBrandId,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Merk',
                        icon: Iconsax.tag,
                        hint: loadingMaster ? 'Memuat merk...' : null,
                      ),
                      items: brands
                          .map(
                            (brand) => DropdownMenuItem<int>(
                          value: brand.id,
                          child: Text(brand.name),
                        ),
                      )
                          .toList(),
                      onChanged: (_saving || loadingMaster)
                          ? null
                          : (value) => _onBrandChanged(value),
                      validator: (value) {
                        if (value == null) return 'Merk wajib dipilih';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: _selectedTypeId,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Tipe',
                        icon: Iconsax.box,
                        hint: _selectedBrandId == null
                            ? 'Pilih merk terlebih dahulu'
                            : (loadingMaster ? 'Memuat tipe...' : null),
                      ),
                      items: types
                          .map(
                            (type) => DropdownMenuItem<int>(
                          value: type.id,
                          child: Text(type.name),
                        ),
                      )
                          .toList(),
                      onChanged: (_saving || loadingMaster || _selectedBrandId == null)
                          ? null
                          : (value) => _onTypeChanged(value),
                      validator: (value) {
                        if (value == null) return 'Tipe wajib dipilih';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: _selectedSeriesId,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Seri',
                        icon: Iconsax.code,
                        hint: _selectedTypeId == null
                            ? 'Pilih tipe terlebih dahulu'
                            : (loadingMaster ? 'Memuat seri...' : null),
                      ),
                      items: series
                          .map(
                            (seri) => DropdownMenuItem<int>(
                          value: seri.id,
                          child: Text(seri.series),
                        ),
                      )
                          .toList(),
                      onChanged: (_saving || loadingMaster || _selectedTypeId == null)
                          ? null
                          : (value) => _onSeriesChanged(value, series),
                      validator: (value) {
                        if (value == null) return 'Seri wajib dipilih';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: _selectedCapacityId,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Kapasitas',
                        icon: Iconsax.flash_1,
                        hint: _selectedTypeId == null
                            ? 'Pilih tipe terlebih dahulu'
                            : (loadingMaster ? 'Memuat kapasitas...' : null),
                      ),
                      items: capacities
                          .map(
                            (cap) => DropdownMenuItem<int>(
                          value: cap.id,
                          child: Text(cap.name),
                        ),
                      )
                          .toList(),
                      onChanged: (_saving || loadingMaster || capacities.isEmpty)
                          ? null
                          : (value) => _onCapacityChanged(value),
                      validator: (value) {
                        if (value == null) return 'Kapasitas wajib dipilih';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _saving ? null : _pickLastService,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
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
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _lastService = null),
                                icon: const Icon(Iconsax.close_circle),
                                color: Colors.grey,
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedTypeId != null && _selectedSeriesId != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final selectedType = types.cast<AcTypeModel?>().firstWhere(
                                (e) => e?.id == _selectedTypeId,
                            orElse: () => null,
                          );
                          final selectedSeries = series.cast<AcSeriesModel?>().firstWhere(
                                (e) => e?.id == _selectedSeriesId,
                            orElse: () => null,
                          );

                          final preview = selectedType == null || selectedSeries == null
                              ? '-'
                              : '${selectedType.name}/${selectedSeries.series}';

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Iconsax.info_circle,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Type tersimpan: $preview',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
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
              onPressed: (_saving || loadingMaster) ? null : _submit,
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
      },
    );
  }
}