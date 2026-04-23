import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/servis_model.dart';
import '../../providers/owner_master_provider.dart';
import '../../services/token_store.dart';
import '../../theme/theme.dart';
import '../../utils/photo_url_helper.dart';
import 'owner_ac_detail_view_page.dart';

class OwnerServiceMonitoringPage extends StatefulWidget {
  final ServisModel service;
  final String? token;

  const OwnerServiceMonitoringPage({
    super.key,
    required this.service,
    this.token,
  });

  @override
  State<OwnerServiceMonitoringPage> createState() =>
      _OwnerServiceMonitoringPageState();
}

class _OwnerServiceMonitoringPageState extends State<OwnerServiceMonitoringPage>
    with TickerProviderStateMixin {
  late ServisModel _service;
  late TabController _tabController;

  String? _token;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _debugPhoto = true;
  int? _selectedFloor;

  void _debugPrint(String msg) {
    if (_debugPhoto) debugPrint('[PHOTO_DEBUG] $msg');
  }

  Future<void> _loadToken() async {
    final store = context.read<TokenStore>();
    String? token;
    try {
      token = await store.getToken();
    } catch (_) {
      token = null;
    }
    if (!mounted) return;
    setState(() {
      _token = token;
    });
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _tabController = TabController(length: 1, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final argToken = (widget.token ?? '').trim();
      if (argToken.isNotEmpty) {
        setState(() {
          _token = argToken;
        });
      } else {
        await _loadToken();
      }

      _debugPrint('token length: ${(_token ?? '').trim().length}');
      _debugPrint('auth headers: $_authHeaders');

      for (final it in _service.itemsData) {
        final urlsSebelum = _photoUrlsOfItem(it, 'sebelum');
        final urlsPengerjaan = _photoUrlsOfItem(it, 'pengerjaan');
        final urlsSesudah = _photoUrlsOfItem(it, 'sesudah');

        if (urlsSebelum.isNotEmpty) {
          await _probeImage(urlsSebelum.first);
          break;
        }
        if (urlsPengerjaan.isNotEmpty) {
          await _probeImage(urlsPengerjaan.first);
          break;
        }
        if (urlsSesudah.isNotEmpty) {
          await _probeImage(urlsSesudah.first);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Map<String, String> get _authHeaders {
    final t = (_token ?? '').trim();
    if (t.isEmpty) return const {'Accept': 'image/*'};
    return {'Authorization': 'Bearer $t', 'Accept': 'image/*'};
  }

  Future<void> _probeImage(String url) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      _authHeaders.forEach((k, v) => req.headers.set(k, v));
      final res = await req.close();
      _debugPrint('probe status=${res.statusCode} url=$url');
      client.close(force: true);
    } catch (e) {
      _debugPrint('probe error=$e url=$url');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'dikerjakan':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'dikerjakan':
        return 'Sedang Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  String _techNameById(OwnerMasterProvider prov, int techId) {
    final idx = prov.technicians.indexWhere((t) => t.id == techId);
    if (idx == -1) return 'Teknisi #$techId';
    return prov.technicians[idx].name ?? 'Teknisi #$techId';
  }

  int? _getTechnicianIdForAc(int acId) {
    for (final item in _service.itemsData) {
      final itemAcId = int.tryParse((item['ac_unit_id'] ?? '').toString()) ?? 0;
      if (itemAcId == acId) {
        final techId =
            int.tryParse((item['technician_id'] ?? '').toString()) ?? 0;
        return techId > 0 ? techId : null;
      }
    }
    return null;
  }

  Map<String, dynamic>? _getItemByAcId(int acId) {
    for (final item in _service.itemsData) {
      final itemAcId = int.tryParse((item['ac_unit_id'] ?? '').toString()) ?? 0;
      if (itemAcId == acId) {
        return item;
      }
    }
    return null;
  }

  String _getItemStatus(int acId) {
    final item = _getItemByAcId(acId);
    if (item == null) return 'ditugaskan';
    final status = (item['status'] ?? '').toString().toLowerCase();
    return status.isEmpty ? 'ditugaskan' : status;
  }

  Color _getItemStatusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'dikerjakan':
        return Colors.purple;
      case 'ditugaskan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt);
  }

  String _lokasiAlamat() {
    final map = _service.lokasiData;
    if (map == null) return '-';
    return (map['address'] ?? '-').toString();
  }

  List<Map<String, dynamic>> _getAcList() {
    final fromItems = _service.itemsData
        .map((it) => it['ac_unit'])
        .where((u) => u is Map)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    if (fromItems.isNotEmpty) {
      final seen = <int>{};
      final uniq = <Map<String, dynamic>>[];

      for (final u in fromItems) {
        final id = int.tryParse((u['id'] ?? '').toString()) ?? 0;
        if (id > 0 && !seen.contains(id)) {
          seen.add(id);
          uniq.add(u);
        }
      }

      uniq.sort((a, b) {
        final floorA = _getFloorNumberFromAc(a);
        final floorB = _getFloorNumberFromAc(b);
        if (floorA != floorB) return floorA.compareTo(floorB);

        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      return uniq;
    }

    if (_service.acData != null && _service.acData!.isNotEmpty) {
      return [_service.acData!];
    }

    return [];
  }

  int _getFloorNumberFromAc(Map<String, dynamic> ac) {
    final room = ac['room'];
    if (room is Map) {
      final floor = room['floor'];
      if (floor is Map) {
        return int.tryParse((floor['number'] ?? 0).toString()) ?? 0;
      }
    }
    return int.tryParse((ac['lantai'] ?? 0).toString()) ?? 0;
  }

  String _getFloorLabelFromAc(Map<String, dynamic> ac) {
    final room = ac['room'];
    if (room is Map) {
      final floor = room['floor'];
      if (floor is Map) {
        final name = (floor['name'] ?? '').toString().trim();
        final number = int.tryParse((floor['number'] ?? 0).toString()) ?? 0;

        if (name.isNotEmpty) return name;
        if (number > 0) return 'Lantai $number';
      }
    }

    final lantai = int.tryParse((ac['lantai'] ?? 0).toString()) ?? 0;
    return lantai > 0 ? 'Lantai $lantai' : '-';
  }

  List<int> _extractFloorOptions(List<Map<String, dynamic>> acList) {
    final floors = acList
        .map(_getFloorNumberFromAc)
        .where((e) => e > 0)
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  int _calculateProgress() {
    final items = _service.itemsData;
    if (items.isEmpty) return 0;

    final completed = items.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == 'selesai';
    }).length;

    return (completed * 100 / items.length).round();
  }

  List<String> _photoUrlsOfItem(Map<String, dynamic>? item, String type) {
    if (item == null) return const [];
    final itemId = int.tryParse((item['id'] ?? '').toString()) ?? 0;
    if (itemId <= 0) return const [];

    final key = switch (type) {
      'sebelum' => 'foto_sebelum',
      'pengerjaan' => 'foto_pengerjaan',
      'sesudah' => 'foto_sesudah',
      _ => 'foto_sebelum',
    };

    final raw = item[key];

    List<String> directUrls = [];

    if (raw is List) {
      directUrls = raw
          .map((e) => e.toString().trim())
          .where((e) =>
      e.isNotEmpty &&
          (e.startsWith('http://') || e.startsWith('https://')))
          .toList();
    } else if (raw is String) {
      final s = raw.trim();
      if (s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'))) {
        directUrls = [s];
      } else if (s.startsWith('[')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            directUrls = decoded
                .map((e) => e.toString().trim())
                .where((e) =>
            e.isNotEmpty &&
                (e.startsWith('http://') || e.startsWith('https://')))
                .toList();
          }
        } catch (_) {}
      }
    }

    if (directUrls.isNotEmpty) return directUrls;

    return asServiceItemPhotoUrls(
      itemId: itemId,
      type: type,
      valueFromApi: raw,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (_service.status.name).toLowerCase();
    final statusColor = _getStatusColor(status);
    final acList = _getAcList();
    final floorOptions = _extractFloorOptions(acList);
    final filteredAcList = _selectedFloor == null
        ? acList
        : acList
        .where((ac) => _getFloorNumberFromAc(ac) == _selectedFloor)
        .toList();
    final progress = _calculateProgress();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: statusColor,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(Iconsax.arrow_left_2, color: Colors.grey[800]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 4),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: Icon(Iconsax.share, color: Colors.grey[800]),
                      onPressed: _showShareOptions,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status == 'selesai'
                                      ? Iconsax.tick_circle
                                      : Iconsax.timer,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getStatusDisplay(status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _service.lokasiNama,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Iconsax.location,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lokasiAlamat(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _service.jenisDisplay,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withValues(alpha: 0.1),
                                    statusColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                status == 'selesai'
                                    ? Iconsax.tick_circle
                                    : Iconsax.chart,
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Progress Pengerjaan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$progress%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey[200],
                            color: statusColor,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoStat(
                              icon: Iconsax.calendar_1,
                              label: 'Tanggal',
                              value: DateFormat('dd MMM yyyy', 'id_ID').format(
                                _service.tanggalBerkunjung ?? DateTime.now(),
                              ),
                              color: Colors.blue,
                            ),
                            _buildInfoStat(
                              icon: Iconsax.cpu,
                              label: 'Unit AC',
                              value: '${acList.length}',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        if (_service.tanggalSelesai != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Iconsax.tick_circle,
                                  size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Selesai pada: ${_formatDateTime(_service.tanggalSelesai)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (floorOptions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.building_4, color: kPrimaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: _selectedFloor,
                                isExpanded: true,
                                hint: const Text('Semua lantai'),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Semua lantai'),
                                  ),
                                  ...floorOptions.map(
                                        (floor) => DropdownMenuItem<int?>(
                                      value: floor,
                                      child: Text('Lantai $floor'),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFloor = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  _buildAcSection(filteredAcList),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: kPrimaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Tim Teknisi'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTechniciansTab(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildTimelineCard(),
                  const SizedBox(height: 20),
                  _buildServiceDetailsCard(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcSection(List<Map<String, dynamic>> acList) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: acList.isEmpty
          ? Column(
        children: [
          Icon(Iconsax.cpu, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Tidak Ada Unit AC',
            style: greyTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada AC pada lantai ini',
            style: greyTextStyle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.cpu, color: kPrimaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Daftar AC (${acList.length})',
                style: primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...acList.map((ac) => _buildAcCard(ac)).toList(),
        ],
      ),
    );
  }

  Widget _buildAcCard(Map<String, dynamic> ac) {
    final acId = int.tryParse((ac['id'] ?? '').toString()) ?? 0;
    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();
    final floorLabel = _getFloorLabelFromAc(ac);

    final techId = _getTechnicianIdForAc(acId);
    final itemStatus = _getItemStatus(acId);
    final statusColor = _getItemStatusColor(itemStatus);

    return GestureDetector(
      onTap: () {
        final item = _getItemByAcId(acId);
        if (item == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item service untuk AC ini tidak ditemukan'),
            ),
          );
          return;
        }

        final itemId = int.tryParse((item['id'] ?? '').toString()) ?? 0;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerAcDetailViewPage(
              item: item,
              itemId: itemId,
              token: _token,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Iconsax.airdrop, color: statusColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: primaryTextStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (floorLabel != '-')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            floorLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$brand • $type • $capacity',
                    style: greyTextStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          itemStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (techId != null) ...[
                        const SizedBox(width: 8),
                        Consumer<OwnerMasterProvider>(
                          builder: (context, prov, _) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.profile_2user,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _techNameById(prov, techId),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.arrow_right_3,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniciansTab() {
    final Set<int> techIds = {};
    for (final item in _service.itemsData) {
      final techId = int.tryParse((item['technician_id'] ?? '').toString()) ?? 0;
      if (techId > 0) techIds.add(techId);
    }

    if (techIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.profile_2user, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Teknisi',
              style: greyTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teknisi belum ditugaskan',
              style: greyTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Consumer<OwnerMasterProvider>(
      builder: (context, prov, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: techIds.length,
          itemBuilder: (context, index) {
            final techId = techIds.elementAt(index);
            final techName = _techNameById(prov, techId);

            int acCount = 0;
            final acNames = <String>[];

            for (final item in _service.itemsData) {
              final itemTechId =
                  int.tryParse((item['technician_id'] ?? '').toString()) ?? 0;
              if (itemTechId == techId) {
                acCount++;
                final ac = item['ac_unit'] as Map?;
                if (ac != null) {
                  acNames.add(ac['name']?.toString() ?? 'AC #$itemTechId');
                }
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.blue.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        techName.isNotEmpty ? techName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          techName,
                          style: primaryTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$acCount Unit AC',
                          style: greyTextStyle.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: acNames.take(3).map((name) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                name,
                                style: greyTextStyle.copyWith(fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                        if (acNames.length > 3) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+${acNames.length - 3} lainnya',
                            style: greyTextStyle.copyWith(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineCard() {
    final status = _service.status.name.toLowerCase();

    final isAssigned = _service.tanggalDitugaskan != null ||
        _service.tanggalMulai != null ||
        _service.tanggalSelesai != null ||
        status == 'ditugaskan' ||
        status == 'dikerjakan' ||
        status == 'selesai';

    final isWorking = _service.tanggalMulai != null ||
        _service.tanggalSelesai != null ||
        status == 'dikerjakan' ||
        status == 'selesai';

    final isFinished = _service.tanggalSelesai != null ||
        status == 'selesai';

    final steps = [
      _TimelineStep(
        title: 'Ditugaskan',
        time: _service.tanggalDitugaskan ??
            _service.tanggalMulai ??
            _service.tanggalSelesai,
        isCompleted: isAssigned,
      ),
      _TimelineStep(
        title: 'Dikerjakan',
        time: _service.tanggalMulai ?? _service.tanggalSelesai,
        isCompleted: isWorking,
      ),
      _TimelineStep(
        title: 'Selesai',
        time: _service.tanggalSelesai,
        isCompleted: isFinished,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.timer_1, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timeline Pengerjaan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.isCompleted
                              ? Colors.green
                              : Colors.grey[300],
                        ),
                        child: step.isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: steps[index + 1].isCompleted
                              ? Colors.green
                              : Colors.grey[300],
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: step.isCompleted
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.time != null
                              ? _formatDateTime(step.time)
                              : (step.isCompleted
                              ? 'Sudah diproses'
                              : 'Belum dimulai'),
                          style: TextStyle(
                            fontSize: 13,
                            color: step.time != null
                                ? Colors.grey[600]
                                : (step.isCompleted
                                ? Colors.grey[600]
                                : Colors.grey[400]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    final catatan = (_service.catatan ?? '').trim();

    final tindakan = (_service.tindakanSummary ?? '').trim().isNotEmpty
        ? (_service.tindakanSummary ?? '').trim()
        : _service.itemsData
        .map((item) => (item['tindakan'] ?? '').toString().trim())
        .where((text) => text.isNotEmpty)
        .join(', ');

    final diagnosa = (_service.diagnosa ?? '').trim().isNotEmpty
        ? (_service.diagnosa ?? '').trim()
        : _service.itemsData
        .map((item) => (item['diagnosa'] ?? '').toString().trim())
        .where((text) => text.isNotEmpty)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.document_text,
                    color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            icon: Iconsax.message_text,
            title: 'Keluhan',
            content: catatan.isNotEmpty ? catatan : 'Tidak ada keluhan',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            icon: Iconsax.key,
            title: 'Tindakan',
            content: tindakan.isNotEmpty ? tindakan : 'Belum ada tindakan',
            color: Colors.blue,
          ),
          if (diagnosa.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailItem(
              icon: Iconsax.clipboard_text,
              title: 'Diagnosa',
              content: diagnosa,
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Bagikan Informasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Pilih format laporan yang ingin dibagikan',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Iconsax.document,
                    label: 'PDF',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Fitur PDF akan segera hadir');
                    },
                  ),
                  _buildShareOption(
                    icon: Iconsax.document_text,
                    label: 'Excel',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Fitur Excel akan segera hadir');
                    },
                  ),
                  _buildShareOption(
                    icon: Iconsax.share,
                    label: 'Link',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Link sharing akan segera hadir');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final DateTime? time;
  final bool isCompleted;

  _TimelineStep({
    required this.title,
    required this.time,
    required this.isCompleted,
  });
}