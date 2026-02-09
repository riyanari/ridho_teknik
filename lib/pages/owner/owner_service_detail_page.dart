import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/servis_model.dart';
import '../../providers/owner_master_provider.dart';
import '../../theme/theme.dart';

class OwnerServiceDetailPage extends StatefulWidget {
  final ServisModel service;
  final bool isReassign;
  const OwnerServiceDetailPage({super.key, required this.service, this.isReassign = false,});

  @override
  State<OwnerServiceDetailPage> createState() => _OwnerServiceDetailPageState();
}

class _OwnerServiceDetailPageState extends State<OwnerServiceDetailPage> {
  final Set<int> _selectedAcIds = {};
  int? _selectedTechnicianId;
  DateTime _tanggalDitugaskan = DateTime.now();

  /// groups: technician_id -> set(ac_unit_ids)
  final Map<int, Set<int>> _groups = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<OwnerMasterProvider>();
      await prov.fetchTechnicians();

      _prefillFromItems();
      _prefillFromServiceGlobalIfNeeded();

      if (mounted) setState(() {});
    });

  }

  bool _isAcAssigned(int acId) {
    for (final entry in _groups.entries) {
      if (entry.value.contains(acId)) return true;
    }
    return false;
  }

  int? _assignedTechIdOfAc(int acId) {
    for (final entry in _groups.entries) {
      if (entry.value.contains(acId)) return entry.key;
    }
    return null;
  }

  String _techNameById(OwnerMasterProvider prov, int techId) {
    final idx = prov.technicians.indexWhere((t) => t.id == techId);
    if (idx == -1) return 'Teknisi #$techId';
    return prov.technicians[idx].name ?? 'Teknisi #$techId';
  }

  void _prefillFromItems() {
    final items = widget.service.itemsData;

    debugPrint('itemsData length: ${items.length}');

    for (final it in items) {
      final acId = int.tryParse((it['ac_unit_id'] ?? '').toString())
          ?? int.tryParse(((it['ac_unit'] is Map) ? it['ac_unit']['id'] : '').toString())
          ?? 0;

      final techId = int.tryParse((it['technician_id'] ?? '').toString())
          ?? int.tryParse(((it['technician'] is Map) ? it['technician']['id'] : '').toString())
          ?? 0;

      if (acId > 0 && techId > 0) {
        _groups.putIfAbsent(techId, () => <int>{});
        _groups[techId]!.add(acId);
      }
    }

    // kalau mode reassign, preselect teknisi pertama yg ada di group
    if (widget.isReassign && _selectedTechnicianId == null && _groups.isNotEmpty) {
      _selectedTechnicianId = _groups.keys.first;
    }

    debugPrint('groups result: ${_groups.map((k,v)=>MapEntry(k, v.toList()))}');
  }


  void _prefillFromServiceGlobalIfNeeded() {
    // cuma untuk mode ganti teknisi
    if (!widget.isReassign) return;

    // kalau itemsData sudah ada, skip (lebih valid)
    if (_groups.isNotEmpty) return;

    final techIds = widget.service.technicianIds ?? [];
    if (techIds.isEmpty) return;

    final acList = _getAcList();
    if (acList.isEmpty) return;

    final firstTechId = techIds.first;
    final acIds = acList
        .map((e) => int.tryParse((e['id'] ?? '').toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();

    _groups[firstTechId] = acIds; // ✅ anggap semua AC berada di teknisi ini
    _selectedTechnicianId = firstTechId; // biar dropdown langsung ke teknisi sekarang
  }


  List<Map<String, dynamic>> _getAcList() {
    // PRIORITAS: itemsData -> ambil ac_unit
    final items = widget.service.itemsData;
    final fromItems = items
        .map((it) => it['ac_unit'])
        .where((u) => u is Map)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    if (fromItems.isNotEmpty) {
      // uniq by id
      final seen = <int>{};
      final uniq = <Map<String, dynamic>>[];
      for (final u in fromItems) {
        final id = int.tryParse((u['id'] ?? '').toString()) ?? 0;
        if (id > 0 && !seen.contains(id)) {
          seen.add(id);
          uniq.add(u);
        }
      }
      return uniq;
    }

    // fallback: ac_units_detail kalau ada
    final detail = widget.service.acUnitsDetail;
    if (detail.isNotEmpty) return detail;

    // fallback terakhir: single acData (kalau perbaikan)
    if (widget.service.acData != null && widget.service.acData!.isNotEmpty) {
      return [widget.service.acData!];
    }

    return [];
  }

  void _toggleSelectAll(List<Map<String, dynamic>> acList) {
    final availableIds = acList
        .map((e) => int.tryParse((e['id'] ?? '').toString()) ?? 0)
        .where((id) => id > 0)
        .where((id) => !_isAcAssigned(id)) // ✅ hanya yang belum assigned
        .toList();

    final allSelected = availableIds.isNotEmpty && availableIds.every(_selectedAcIds.contains);

    setState(() {
      if (allSelected) {
        _selectedAcIds.removeAll(availableIds);
      } else {
        _selectedAcIds
          ..removeWhere((_) => false)
          ..addAll(availableIds);
      }
    });
  }

  void _assignSelectedToTechnician() {
    if (_selectedTechnicianId == null || _selectedAcIds.isEmpty) return;

    setState(() {
      _groups.putIfAbsent(_selectedTechnicianId!, () => <int>{});
      _groups[_selectedTechnicianId!]!.addAll(_selectedAcIds);

      // optional: kalau mau auto hilangkan AC dari group teknisi lain
      // (biar 1 AC cuma boleh 1 teknisi)
      for (final entry in _groups.entries) {
        if (entry.key == _selectedTechnicianId) continue;
        entry.value.removeAll(_selectedAcIds);
      }
      _groups.removeWhere((key, value) => value.isEmpty);

      _selectedAcIds.removeWhere((id) => _isAcAssigned(id));

      _selectedAcIds.clear();
    });
  }

  void _removeAcFromGroup(int techId, int acId) {
    setState(() {
      final set = _groups[techId];
      if (set == null) return;
      set.remove(acId);
      if (set.isEmpty) _groups.remove(techId);
    });
  }

  Future<void> _submit() async {
    final prov = context.read<OwnerMasterProvider>();

    final serviceId = int.tryParse(widget.service.id) ?? 0;
    if (serviceId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service ID tidak valid'), backgroundColor: Colors.red),
      );
      return;
    }

    // build payload groups
    final groups = _groups.entries
        .map((e) => {
      "technician_id": e.key,
      "ac_unit_ids": e.value.toList(),
    })
        .where((g) => (g["ac_unit_ids"] as List).isNotEmpty)
        .toList();

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih AC lalu assign ke teknisi dulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ panggil provider method yang benar
    final ok = await prov.assignTechnicianPerAcGroups(
      serviceId,
      groups: groups,
      tanggalDitugaskan: _tanggalDitugaskan,
      isReassign: widget.isReassign,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Berhasil assign teknisi per AC' : (prov.submitError ?? 'Gagal assign teknisi')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) {
      await prov.fetchServices(useLastQuery: true);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _handleLockedAcTap(
      OwnerMasterProvider prov, {
        required int acId,
        required int fromTechId,
      }) async {
    if (_selectedTechnicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih teknisi tujuan dulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final toTechId = _selectedTechnicianId!;
    if (toTechId == fromTechId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AC ini sudah di teknisi yang sama'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final fromName = _techNameById(prov, fromTechId);
    final toName = _techNameById(prov, toTechId);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pindahkan Teknisi?'),
        content: Text('AC ini sudah di $fromName.\nPindahkan ke $toName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pindahkan'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      // remove dari teknisi lama
      _groups[fromTechId]?.remove(acId);
      if (_groups[fromTechId]?.isEmpty ?? false) {
        _groups.remove(fromTechId);
      }

      // masuk ke teknisi tujuan
      _groups.putIfAbsent(toTechId, () => <int>{});
      _groups[toTechId]!.add(acId);

      // optional: pastikan gak nyangkut di selected list
      _selectedAcIds.remove(acId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AC dipindahkan dari $fromName ke $toName'),
        backgroundColor: Colors.green,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OwnerMasterProvider>();
    final acList = _getAcList();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_2, color: kPrimaryColor),
        ),
        title: Text(
          'Detail Service',
          style: primaryTextStyle.copyWith(fontSize: 18, fontWeight: bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 12),

          _dateCard(),
          const SizedBox(height: 12),

          _assignControlsCard(prov),
          const SizedBox(height: 12),

          _acListCard(prov, acList),
          const SizedBox(height: 12),

          _groupPreviewCard(prov),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: prov.submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: prov.submitting
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text(
              'Simpan Penugasan',
              style: whiteTextStyle.copyWith(fontSize: 14, fontWeight: semiBold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignControlsCard(OwnerMasterProvider prov) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assign Teknisi per AC', style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: semiBold)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedTechnicianId,
                isExpanded: true,
                icon: const Icon(Iconsax.arrow_down_1, color: kPrimaryColor),
                hint: Text('Pilih teknisi', style: greyTextStyle),
                items: prov.technicians
                    .where((t) => (t.id ?? 0) > 0)
                    .map((t) => DropdownMenuItem<int?>(
                  value: t.id,
                  child: Text(t.name ?? 'Teknisi #${t.id}', style: primaryTextStyle),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedTechnicianId = v;
                    _selectedAcIds.clear();
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedTechnicianId == null || _selectedAcIds.isEmpty) ? null : _assignSelectedToTechnician,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Assign AC Terpilih', style: whiteTextStyle.copyWith(fontWeight: semiBold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    final s = widget.service;
    final date = s.tanggalBerkunjung != null ? DateFormat('dd MMM yyyy', 'id_ID').format(s.tanggalBerkunjung!) : '-';
    final time = s.tanggalBerkunjung != null ? DateFormat('HH:mm').format(s.tanggalBerkunjung!) : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service #${s.id}', style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: bold)),
          const SizedBox(height: 6),
          Text('${s.jenisDisplay} • ${s.statusDisplay}', style: greyTextStyle),
          const SizedBox(height: 10),
          if (widget.isReassign) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha:0.2)),
              ),
              child: Text(
                'Mode Ganti Teknisi: penugasan saat ini sudah diprefill.',
                style: greyTextStyle.copyWith(fontSize: 12),
              ),
            )
          ],
          Row(
            children: [
              const Icon(Iconsax.location, size: 16, color: kPrimaryColor),
              const SizedBox(width: 6),
              Expanded(child: Text(s.lokasiNama, style: primaryTextStyle)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Iconsax.calendar_1, size: 16, color: kPrimaryColor),
              const SizedBox(width: 6),
              Text(date, style: primaryTextStyle),
              const SizedBox(width: 12),
              const Icon(Iconsax.clock, size: 16, color: kPrimaryColor),
              const SizedBox(width: 6),
              Text(time, style: primaryTextStyle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _tanggalDitugaskan,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked == null) return;
          setState(() => _tanggalDitugaskan = picked);
        },
        child: Row(
          children: [
            const Icon(Iconsax.calendar_edit, color: kPrimaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tanggal Ditugaskan: ${DateFormat('dd MMM yyyy', 'id_ID').format(_tanggalDitugaskan)}',
                style: primaryTextStyle.copyWith(fontWeight: semiBold),
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _acListCard(OwnerMasterProvider prov, List<Map<String, dynamic>> acList) {
    if (acList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Text('Tidak ada list AC pada service ini', style: greyTextStyle),
      );
    }

    final allIds = acList
        .map((e) => int.tryParse((e['id'] ?? '').toString()) ?? 0)
        .where((id) => id > 0)
        .toList();
    final allSelected = allIds.isNotEmpty && allIds.every(_selectedAcIds.contains);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Daftar AC (${acList.length})', style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: semiBold)),
              const Spacer(),
              TextButton(
                onPressed: () => _toggleSelectAll(acList),
                child: Text(allSelected ? 'Unselect All' : 'Select All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...acList.map((ac) {
            final acId = int.tryParse((ac['id'] ?? '').toString()) ?? 0;
            final name = (ac['name'] ?? '-').toString();
            final brand = (ac['brand'] ?? '').toString();
            final type = (ac['type'] ?? '').toString();
            final cap = (ac['capacity'] ?? '').toString();

            final selected = _selectedAcIds.contains(acId);

            // ✅ LOCK jika sudah masuk group teknisi manapun
            final assignedTechId = _assignedTechIdOfAc(acId);
            final isLocked = assignedTechId != null;

            final canMove = isLocked && _selectedTechnicianId != null && _selectedTechnicianId != assignedTechId;

            return Opacity(
              opacity: isLocked ? 0.75 : 1,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected ? kPrimaryColor.withValues(alpha: 0.06) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? kPrimaryColor.withValues(alpha: 0.35) : Colors.grey[200]!,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // kalau locked, coba pindahkan
                    if (isLocked) {
                      await _handleLockedAcTap(
                        prov,
                        acId: acId,
                        fromTechId: assignedTechId,
                      );
                    }
                  },
                  child: CheckboxListTile(
                    value: selected,
                    onChanged: isLocked
                        ? null // checkbox tetap disable kalau sudah assigned
                        : (v) {
                      setState(() {
                        if (v == true) {
                          _selectedAcIds.add(acId);
                        } else {
                          _selectedAcIds.remove(acId);
                        }
                      });
                    },
                    activeColor: kPrimaryColor,
                    title: Text(
                      name,
                      style: primaryTextStyle.copyWith(fontWeight: semiBold),
                    ),
                    subtitle: Text(
                      [
                        [brand, type, cap].where((e) => e.trim().isNotEmpty).join(' • '),
                        if (isLocked)
                          'Sudah di-assign ke ${_techNameById(prov, assignedTechId)}'
                        else
                          'Belum di-assign',
                        if (canMove) 'Tap untuk pindahkan ke teknisi terpilih',
                        if (isLocked && _selectedTechnicianId == null) 'Pilih teknisi tujuan dulu untuk pindah',
                      ].where((e) => e.trim().isNotEmpty).join('\n'),
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ),
            );

          }).toList(),
        ],
      ),
    );
  }

  Widget _groupPreviewCard(OwnerMasterProvider prov) {
    if (_groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Text('Belum ada penugasan per AC.', style: greyTextStyle),
      );
    }

    // helper: map acId -> name
    final acList = _getAcList();
    final acNameById = <int, String>{};
    for (final ac in acList) {
      final id = int.tryParse((ac['id'] ?? '').toString()) ?? 0;
      if (id > 0) acNameById[id] = (ac['name'] ?? 'AC #$id').toString();
    }

    String techName(int techId) {
      final idx = prov.technicians.indexWhere((x) => x.id == techId);
      if (idx == -1) return 'Teknisi #$techId';
      return prov.technicians[idx].name ?? 'Teknisi #$techId';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Penugasan', style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: semiBold)),
          const SizedBox(height: 10),
          ..._groups.entries.map((e) {
            final techId = e.key;
            final acIds = e.value.toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(techName(techId), style: primaryTextStyle.copyWith(fontWeight: bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: acIds.map((acId) {
                      return Chip(
                        label: Text(acNameById[acId] ?? 'AC #$acId'),
                        onDeleted: () => _removeAcFromGroup(techId, acId),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
