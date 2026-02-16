// pages/technician/add_technician_sheet.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../providers/owner_master_provider.dart';
import '../../providers/technician_provider.dart';
import '../../theme/theme.dart';

class AddTechnicianSheet extends StatefulWidget {
  const AddTechnicianSheet({super.key});

  @override
  State<AddTechnicianSheet> createState() => _AddTechnicianSheetState();
}

class _AddTechnicianSheetState extends State<AddTechnicianSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscurePassConf = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _passConfCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email wajib diisi';
    // Optional: Uncomment untuk validasi format email
    // final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
    // if (!ok) return 'Format email tidak valid';
    return null;
  }

  String? _validateRequired(String? v, String label) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return '$label wajib diisi';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _validatePasswordConf(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Konfirmasi password wajib diisi';
    if (value != _passCtrl.text) return 'Konfirmasi password tidak sama';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passCtrl.text,
      'password_confirmation': _passConfCtrl.text,
      // 'spesialisasi' akan diisi default di backend
    };

    // Panggil OwnerMasterProvider untuk create technician
    final ownerProv = context.read<OwnerMasterProvider>();

    final created = await ownerProv.createTechnician(payload);

    if (!mounted) return;

    if (created != null) {
      // Refresh list technician di halaman utama
      context.read<TechnicianProvider>().fetchTechnicians();

      Navigator.pop(context); // tutup sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teknisi berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Error ditampilkan lewat ownerProv.submitError
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerProv = context.watch<OwnerMasterProvider>();
    final isSubmitting = ownerProv.submitting;
    final submitError = ownerProv.submitError;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Teknisi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),

              // Error message
              if (submitError != null && submitError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          submitError,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nama
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap teknisi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Iconsax.user),
                      ),
                      validator: (v) => _validateRequired(v, 'Nama'),
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'contoh@email.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Iconsax.sms),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // No. HP
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'No. HP',
                        hintText: '081234567890',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Iconsax.call),
                      ),
                      validator: (v) => _validateRequired(v, 'No. HP'),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimal 6 karakter',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Iconsax.lock),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          icon: Icon(_obscurePass ? Iconsax.eye_slash : Iconsax.eye),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),

                    // Konfirmasi Password
                    TextFormField(
                      controller: _passConfCtrl,
                      obscureText: _obscurePassConf,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        hintText: 'Ketik ulang password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Iconsax.lock_1),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassConf = !_obscurePassConf),
                          icon: Icon(_obscurePassConf ? Iconsax.eye_slash : Iconsax.eye),
                        ),
                      ),
                      validator: _validatePasswordConf,
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    const SizedBox(height: 16),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSecondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Tambah Teknisi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // // Info tambahan
                    // Center(
                    //   child: Text(
                    //     'Spesialisasi akan diisi default oleh sistem',
                    //     style: TextStyle(
                    //       fontSize: 12,
                    //       color: Colors.grey[500],
                    //       fontStyle: FontStyle.italic,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}