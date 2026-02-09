import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../models/servis_model.dart';
import '../../theme/theme.dart';

class TeknisiTaskDetailPage extends StatelessWidget {
  const TeknisiTaskDetailPage({
    super.key,
    required this.servis,
  });

  final ServisModel servis;

  String _statusKey() => servis.status.name.toLowerCase();

  Color _statusColor(String status) {
    switch (status) {
      case 'ditugaskan':
        return Colors.blue;
      case 'dikerjakan':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ditugaskan':
        return 'Ditugaskan';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ditugaskan':
        return Iconsax.task_square;
      case 'dikerjakan':
        return Iconsax.timer;
      case 'selesai':
        return Iconsax.tick_circle;
      default:
        return Iconsax.activity;
    }
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM y • HH:mm', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusKey();
    final statusColor = _statusColor(status);
    final isSelesai = status == 'selesai';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Detail Tugas',
          style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: semiBold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          _headerCard(statusColor, status),
          const SizedBox(height: 14),

          _sectionCard(
            child: Column(
              children: [
                _rowInfo(icon: Iconsax.building_3, title: 'Lokasi', value: servis.lokasiNama),
                const SizedBox(height: 12),

                if (!isSelesai) ...[
                  _rowInfo(icon: Iconsax.location, title: 'Alamat', value: servis.lokasiAlamat),
                  const SizedBox(height: 12),
                ],

                _rowInfo(icon: Iconsax.category, title: 'Jenis Servis', value: servis.jenisDisplay),
                const SizedBox(height: 12),
                _rowInfo(
                  icon: Iconsax.cpu,
                  title: 'Jumlah AC',
                  value: '${_jumlahAcDisplay(servis)} unit',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _sectionCard(
            title: 'Waktu',
            child: Column(
              children: [
                _rowInfo(
                  icon: Iconsax.calendar_1,
                  title: 'Tanggal Ditugaskan',
                  value: _fmtDateTime(servis.tanggalDitugaskan),
                ),
                const SizedBox(height: 12),
                _rowInfo(
                  icon: Iconsax.calendar_tick,
                  title: 'Tanggal Berkunjung',
                  value: _fmtDateTime(servis.tanggalBerkunjung),
                ),
                const SizedBox(height: 12),
                _rowInfo(icon: Iconsax.play_circle, title: 'Mulai', value: _fmtDateTime(servis.tanggalMulai)),
                const SizedBox(height: 12),
                _rowInfo(icon: Iconsax.tick_circle, title: 'Selesai', value: _fmtDateTime(servis.tanggalSelesai)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _sectionCard(
            title: 'Unit AC',
            child: _buildAcSection(context),
          ),

          const SizedBox(height: 14),

          _sectionCard(
            title: 'Keluhan & Tindakan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _textBlock(
                  icon: Iconsax.message_text,
                  title: 'Keluhan / Catatan Client',
                  value: servis.catatan.trim().isEmpty ? '-' : servis.catatan,
                ),
                const SizedBox(height: 12),
                _textBlock(
                  icon: Iconsax.note_text,
                  title: 'Tindakan',
                  value: servis.tindakan.isEmpty ? 'Belum ada tindakan' : servis.tindakan.map((e) => e.name).join(', '),
                ),
                const SizedBox(height: 12),
                if (servis.diagnosa.trim().isNotEmpty)
                  _textBlock(icon: Iconsax.clipboard_text, title: 'Diagnosa', value: servis.diagnosa),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (servis.technicianNames.isNotEmpty) ...[
            _sectionCard(
              title: 'Teknisi',
              child: _rowInfo(
                icon: Iconsax.profile_2user,
                title: 'Tim',
                value: servis.techniciansNamesDisplay,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _jumlahAcDisplay(ServisModel s) {
    if (s.jumlahAc != null && s.jumlahAc! > 0) return '${s.jumlahAc}';
    if (s.acUnitsNames.isNotEmpty) return '${s.acUnitsNames.length}';
    return '-';
  }

  Widget _headerCard(Color statusColor, String status) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha:0.12), statusColor.withValues(alpha:0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha:0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha:0.12), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Icon(_statusIcon(status), color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servis.lokasiNama, style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: semiBold)),
                const SizedBox(height: 6),
                Text('ID: ${servis.id}', style: greyTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha:0.25)),
            ),
            child: Text(
              _statusLabel(status),
              style: primaryTextStyle.copyWith(fontSize: 11, fontWeight: bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: semiBold)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _rowInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: greyTextStyle.copyWith(fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: semiBold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textBlock({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: greyTextStyle.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                Text(value, style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: semiBold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // AC SECTION: acUnitsDetail -> itemsData.ac_unit -> acData
  // =========================

  Widget _buildAcSection(BuildContext context) {
    final List<Map<String, dynamic>> list = [];

    // 1) ac_units_detail
    if (servis.acUnitsDetail.isNotEmpty) {
      list.addAll(servis.acUnitsDetail);
    }

    // 2) itemsData[].ac_unit
    if (list.isEmpty && servis.itemsData.isNotEmpty) {
      final fromItems = servis.itemsData
          .map((it) => it['ac_unit'])
          .where((u) => u is Map)
          .map((u) => Map<String, dynamic>.from(u as Map))
          .toList();
      if (fromItems.isNotEmpty) list.addAll(fromItems);
    }

    // 3) acData single
    if (list.isEmpty && servis.acData != null) {
      list.add(Map<String, dynamic>.from(servis.acData!));
    }

    if (list.isEmpty) return Text('-', style: greyTextStyle);

    return Column(children: list.map((ac) => _acCard(context, ac)).toList());
  }

  Widget _acCard(BuildContext context, Map<String, dynamic> ac) {
    final id = (ac['id'] ?? '').toString();
    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final cap = (ac['capacity'] ?? '-').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.airdrop, color: kPrimaryColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: primaryTextStyle.copyWith(fontWeight: semiBold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('$brand • $type • $cap', style: greyTextStyle.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              if (id.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha:0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimaryColor.withValues(alpha:0.15)),
                  ),
                  child: Text(
                    '#$id',
                    style: primaryTextStyle.copyWith(fontSize: 10, fontWeight: bold, color: kPrimaryColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAcDetail(context, ac),
                icon: const Icon(Iconsax.document_text, size: 16),
                label: const Text('Detail'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: BorderSide(color: kPrimaryColor.withValues(alpha:0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAcHistory(context, ac),
                icon: const Icon(Iconsax.refresh, size: 16),
                label: const Text('Riwayat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: BorderSide(color: Colors.indigo.withValues(alpha:0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAcActions(context, ac),
                icon: const Icon(Iconsax.more, size: 16),
                label: const Text('Kerjakan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAcDetail(BuildContext context, Map<String, dynamic> ac) {
    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final cap = (ac['capacity'] ?? '-').toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name, style: primaryTextStyle.copyWith(fontWeight: semiBold)),
        content: Text('Brand: $brand\nType: $type\nKapasitas: $cap', style: primaryTextStyle),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _showAcHistory(BuildContext context, Map<String, dynamic> ac) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TODO: buka halaman Riwayat AC')));
  }

  void _showAcActions(BuildContext context, Map<String, dynamic> ac) {
    final acName = (ac['name'] ?? '-').toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aksi untuk $acName', style: primaryTextStyle.copyWith(fontWeight: semiBold)),
                const SizedBox(height: 12),
                _actionTile(
                  icon: Iconsax.camera,
                  title: 'Upload Foto Sebelum',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _actionTile(
                  icon: Iconsax.gallery,
                  title: 'Upload Foto Pengerjaan',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _actionTile(
                  icon: Iconsax.tick_circle,
                  title: 'Upload Foto Sesudah',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha:0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: kPrimaryColor, size: 20),
      ),
      title: Text(title, style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: semiBold)),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18),
      onTap: onTap,
    );
  }
}
