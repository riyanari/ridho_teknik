import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/custom_app_bar.dart';
import '../../models/client_record.dart';
import '../../theme/theme.dart';
import 'data/clients_data.dart';
class ArsipPage extends StatefulWidget {
  const ArsipPage({super.key});

  @override
  State<ArsipPage> createState() => _ArsipPageState();
}

class _ArsipPageState extends State<ArsipPage> {
  final TextEditingController _searchC = TextEditingController();
  String _query = '';
  String _filterKeluhan = 'Semua';

  List<String> get _keluhanOptions {
    final set = <String>{'Semua'};
    for (final c in clientsDummy) {
      for (final k in c.complaints) {
        set.add(k.type);
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b)); // rapi
    // Pastikan 'Semua' tetap di depan
    if (list.remove('Semua')) list.insert(0, 'Semua');
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = clientsDummy.where((c) {
      final matchQuery = c.matchesQuery(_query);
      final matchKeluhan = c.matchesFilter(_filterKeluhan);
      return matchQuery && matchKeluhan;
    }).toList();

    final totalKeluhan = filtered.fold<int>(0, (sum, c) => sum + c.complaints.length);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: CustomAppBar("Arsip"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            children: [
              // Search
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: TextField(
                  controller: _searchC,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    icon: Icon(Iconsax.search_normal, color: kPrimaryColor),
                    hintText: 'Cari nama / alamat / keluhan...',
                    hintStyle: greyTextStyle.copyWith(fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Counter + Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _pill('${filtered.length} Client', kPrimaryColor),
                      _pill('$totalKeluhan Keluhan', kSecondaryColor),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _keluhanOptions.contains(_filterKeluhan) ? _filterKeluhan : 'Semua',
                        items: _keluhanOptions
                            .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e, style: primaryTextStyle.copyWith(fontSize: 12)),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _filterKeluhan = v ?? 'Semua'),
                        icon: const Icon(Iconsax.arrow_down_1, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return _ClientCard(
                      data: c,
                      onOpenMaps: () => _openMaps(c.mapsQuery, c.address),
                      onOpenWA: () => _openWhatsApp(c.whatsapp, 'Halo ${c.name}, terkait layanan AC.'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: primaryTextStyle.copyWith(fontSize: 12, fontWeight: medium, color: color),
      ),
    );
  }

  Future<void> _openMaps(String query, String fallbackAddress) async {
    final q = Uri.encodeComponent(query.isNotEmpty ? query : fallbackAddress);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp(String phone, String message) async {
    final normalized = _normalizeIndoPhone(phone);
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$normalized?text=$text');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _normalizeIndoPhone(String phone) {
    var p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('0')) return '62${p.substring(1)}';
    if (p.startsWith('62')) return p;
    return '62$p';
  }
}

class _ClientCard extends StatelessWidget {
  final ClientRecord data;
  final VoidCallback onOpenMaps;
  final VoidCallback onOpenWA;

  const _ClientCard({
    required this.data,
    required this.onOpenMaps,
    required this.onOpenWA,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama + Aksi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.personalcard, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.name,
                  style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: semiBold),
                ),
              ),
              _ActionPill(icon: Iconsax.map, label: 'Maps', color: kBoxMenuDarkBlueColor, onTap: onOpenMaps),
              const SizedBox(width: 8),
              _ActionPill(icon: Iconsax.message, label: 'WA', color: kBoxMenuGreenColor, onTap: onOpenWA),
            ],
          ),
          const SizedBox(height: 10),

          // Alamat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.location, size: 16, color: kPrimaryColor),
              const SizedBox(width: 6),
              Expanded(child: Text(data.address, style: greyTextStyle.copyWith(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 10),

          // Keluhan – chips ringkas
          Wrap(
            spacing: 6,
            runSpacing: -6,
            children: data.complaints.map((k) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kSecondaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.info_circle, size: 12),
                    const SizedBox(width: 4),
                    Text(k.title, style: primaryTextStyle.copyWith(fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // List detail keluhan
          Column(
            children: data.complaints.map((k) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 2),
                    Icon(Iconsax.calendar_1, size: 14, color: kSecondaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [
                          if (k.date != null)
                            '${k.date!.day.toString().padLeft(2, '0')}/${k.date!.month.toString().padLeft(2, '0')}/${k.date!.year}',
                          k.title,
                          if (k.notes.isNotEmpty) '— ${k.notes}',
                        ].where((e) => e.isNotEmpty).join(' · '),
                        style: greyTextStyle.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Nomor WA
          Row(
            children: [
              Icon(Iconsax.call_calling, size: 16, color: kBoxMenuGreenColor),
              const SizedBox(width: 6),
              Text(data.whatsapp, style: greyTextStyle.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
