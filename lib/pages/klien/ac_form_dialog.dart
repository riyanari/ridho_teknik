// lib/pages/klien/ac_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/ac_model.dart';
import '../../theme/theme.dart';

class AcFormDialog extends StatefulWidget {
  final AcModel? initial;
  final String lokasiId;
  const AcFormDialog({super.key, this.initial, required this.lokasiId});

  @override
  State<AcFormDialog> createState() => _AcFormDialogState();
}

class _AcFormDialogState extends State<AcFormDialog> {
  late final TextEditingController _namaController;
  late final TextEditingController _merkController;
  late final TextEditingController _typeController;
  late final TextEditingController _kapasitasController;

  final List<String> _merkOptions = [
    'Daikin',
    'Panasonic',
    'LG',
    'Samsung',
    'Sharp',
    'Toshiba',
    'Mitsubishi',
    'Polytron',
    'Gree',
    'Aqua',
    'Lainnya'
  ];

  final List<String> _typeOptions = [
    'Split',
    'Window',
    'Cassette',
    'Floor Standing',
    'Ducted',
    'Portable',
    'Central',
    'Lainnya'
  ];

  final List<String> _kapasitasOptions = [
    '0.5 PK',
    '0.75 PK',
    '1 PK',
    '1.5 PK',
    '2 PK',
    '2.5 PK',
    '3 PK',
    '4 PK',
    '5 PK',
    'Lainnya'
  ];

  String? _selectedMerk;
  String? _selectedType;
  String? _selectedKapasitas;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initial?.nama ?? '');
    _merkController = TextEditingController(text: widget.initial?.merk ?? '');
    _typeController = TextEditingController(text: widget.initial?.type ?? '');
    _kapasitasController = TextEditingController(text: widget.initial?.kapasitas ?? '');

    // Set nilai awal untuk dropdown
    _selectedMerk = widget.initial?.merk;
    _selectedType = widget.initial?.type;
    _selectedKapasitas = widget.initial?.kapasitas;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _merkController.dispose();
    _typeController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_namaController.text.trim().isEmpty) {
      _showError('Nama AC tidak boleh kosong');
      return;
    }

    final merk = _selectedMerk ?? _merkController.text.trim();
    final type = _selectedType ?? _typeController.text.trim();
    final kapasitas = _selectedKapasitas ?? _kapasitasController.text.trim();

    if (merk.isEmpty) {
      _showError('Merk AC tidak boleh kosong');
      return;
    }

    if (type.isEmpty) {
      _showError('Type AC tidak boleh kosong');
      return;
    }

    if (kapasitas.isEmpty) {
      _showError('Kapasitas AC tidak boleh kosong');
      return;
    }

    final ac = AcModel(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      lokasiId: widget.lokasiId,
      nama: _namaController.text.trim(),
      merk: merk,
      type: type,
      kapasitas: kapasitas,
      terakhirService: widget.initial?.terakhirService ?? DateTime.now(),
    );

    Navigator.pop(context, ac);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: whiteTextStyle),
        backgroundColor: kBoxMenuRedColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama AC
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama AC*',
                      hintText: 'Contoh: AC Ruang Tamu, AC Kamar Utama, dll.',
                      prefixIcon: Icons.description_rounded,
                    ),
                    const SizedBox(height: 20),

                    // Merk AC (Dropdown atau Input)
                    _buildMerkSection(),
                    const SizedBox(height: 20),

                    // Type AC (Dropdown atau Input)
                    _buildTypeSection(),
                    const SizedBox(height: 20),

                    // Kapasitas AC (Dropdown atau Input)
                    _buildKapasitasSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kSecondaryColor.withValues(alpha:0.1), kSecondaryColor.withValues(alpha:0.2)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.ac_unit_rounded,
            color: kSecondaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.initial == null ? 'Tambah AC Baru' : 'Edit AC',
          style: primaryTextStyle.copyWith(
            fontSize: 20,
            fontWeight: bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close_rounded,
            color: kGreyColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: greyTextStyle,
            prefixIcon: Icon(prefixIcon, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kGreyColor.withValues(alpha:0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kGreyColor.withValues(alpha:0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kPrimaryColor, width: 2),
            ),
            filled: true,
            fillColor: kBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merk AC*',
          style: primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown Merk
        Container(
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreyColor.withValues(alpha:0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMerk,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: kPrimaryColor),
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Pilih Merk', style: greyTextStyle),
              ),
              items: [
                ..._merkOptions.map((merk) {
                  return DropdownMenuItem(
                    value: merk,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(merk, style: primaryTextStyle),
                    ),
                  );
                }),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Lainnya...', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'custom') {
                    _selectedMerk = null;
                    _merkController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  } else {
                    _selectedMerk = value;
                    _merkController.text = value ?? '';
                  }
                });
              },
            ),
          ),
        ),

        // Input custom jika memilih "Lainnya"
        if (_selectedMerk == null && (_merkController.text.isNotEmpty || _merkController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildTextField(
              controller: _merkController,
              label: 'Masukkan Merk Lain',
              hintText: 'Contoh: Merk lokal, import, dll.',
              prefixIcon: Icons.branding_watermark_rounded,
            ),
          ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type AC*',
          style: primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown Type
        Container(
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreyColor.withValues(alpha:0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: kPrimaryColor),
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Pilih Type', style: greyTextStyle),
              ),
              items: [
                ..._typeOptions.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(type, style: primaryTextStyle),
                    ),
                  );
                }),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Lainnya...', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'custom') {
                    _selectedType = null;
                    _typeController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  } else {
                    _selectedType = value;
                    _typeController.text = value ?? '';
                  }
                });
              },
            ),
          ),
        ),

        // Input custom jika memilih "Lainnya"
        if (_selectedType == null && (_typeController.text.isNotEmpty || _typeController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildTextField(
              controller: _typeController,
              label: 'Masukkan Type Lain',
              hintText: 'Contoh: Inverter, Non-Inverter, dll.',
              prefixIcon: Icons.build_rounded,
            ),
          ),
      ],
    );
  }

  Widget _buildKapasitasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kapasitas AC*',
          style: primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown Kapasitas
        Container(
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreyColor.withValues(alpha:0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedKapasitas,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: kPrimaryColor),
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Pilih Kapasitas', style: greyTextStyle),
              ),
              items: [
                ..._kapasitasOptions.map((kapasitas) {
                  return DropdownMenuItem(
                    value: kapasitas,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(kapasitas, style: primaryTextStyle),
                    ),
                  );
                }),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Lainnya...', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'custom') {
                    _selectedKapasitas = null;
                    _kapasitasController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  } else {
                    _selectedKapasitas = value;
                    _kapasitasController.text = value ?? '';
                  }
                });
              },
            ),
          ),
        ),

        // Input custom jika memilih "Lainnya"
        if (_selectedKapasitas == null && (_kapasitasController.text.isNotEmpty || _kapasitasController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildTextField(
              controller: _kapasitasController,
              label: 'Masukkan Kapasitas Lain',
              hintText: 'Contoh: 9000 BTU, 12000 BTU, dll.',
              prefixIcon: Icons.bolt_rounded,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: kGreyColor.withValues(alpha:0.5)),
            ),
            child: Text(
              'Batal',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: medium,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              widget.initial == null ? 'Simpan' : 'Update',
              style: whiteTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}