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

  /// Kalau endpoint foto butuh Bearer token (umumnya iya), isi token owner di sini.
  /// Kalau fotonya public, boleh null.
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
  bool _loadingToken = true;

  // Untuk animasi
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ===== DEBUG =====
  bool _debugPhoto = true;

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
      _loadingToken = false;
    });
  }


  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1) prioritas: kalau widget.token ada, pakai itu
      final argToken = (widget.token ?? '').trim();
      if (argToken.isNotEmpty) {
        setState(() {
          _token = argToken;
          _loadingToken = false;
        });
      } else {
        // 2) kalau tidak ada, ambil dari TokenStore
        await _loadToken();
      }

      _debugPrint('token length: ${(_token ?? '').trim().length}');
      _debugPrint('auth headers: $_authHeaders');

      // Cari 1 foto untuk probe (setelah token siap)
      for (final it in _service.itemsData) {
        final itemId = int.tryParse((it['id'] ?? '').toString()) ?? 0;
        if (itemId <= 0) continue;

        final urlsSebelum = _photoUrlsOfItem(it, 'sebelum');
        final urlsPengerjaan = _photoUrlsOfItem(it, 'pengerjaan');
        final urlsSesudah = _photoUrlsOfItem(it, 'sesudah');

        if (urlsSebelum.isNotEmpty) {
          _debugPrint('test itemId=$itemId type=sebelum url=${urlsSebelum.first}');
          await _probeImage(urlsSebelum.first);
          break;
        }
        if (urlsPengerjaan.isNotEmpty) {
          _debugPrint('test itemId=$itemId type=pengerjaan url=${urlsPengerjaan.first}');
          await _probeImage(urlsPengerjaan.first);
          break;
        }
        if (urlsSesudah.isNotEmpty) {
          _debugPrint('test itemId=$itemId type=sesudah url=${urlsSesudah.first}');
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

  // ==================== AUTH HEADERS ====================
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

  // ==================== HELPER FUNCTIONS ====================
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
    final items = _service.itemsData;
    for (final item in items) {
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
    final items = _service.itemsData;
    for (final item in items) {
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

  List<Map<String, dynamic>> _getAcList() {
    // Priority: itemsData -> ambil ac_unit
    final items = _service.itemsData;
    final fromItems = items
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
      return uniq;
    }

    // Fallback
    if (_service.acUnitsDetail.isNotEmpty) return _service.acUnitsDetail;
    if (_service.acData != null && _service.acData!.isNotEmpty) {
      return [_service.acData!];
    }
    return [];
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

  // ==================== FOTO ====================
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

    // DEBUG raw value
    _debugPrint('itemId=$itemId key=$key rawType=${raw.runtimeType} raw=$raw');

    // 1) Jika API kirim URL langsung (http/https), pakai langsung
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

    if (directUrls.isNotEmpty) {
      _debugPrint('itemId=$itemId type=$type directUrls=${directUrls.length} first=${directUrls.first}');
      return directUrls;
    }

    // 2) Pakai strategi helper (API media pakai index i)
    final urls = asServiceItemPhotoUrls(
      itemId: itemId,
      type: type,
      valueFromApi: raw,
    );

    if (urls.isNotEmpty) {
      _debugPrint('itemId=$itemId type=$type helperUrls=${urls.length} first=${urls.first}');
    }
    return urls;
  }

  // ==================== BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    final status = (_service.status.name).toLowerCase();
    final statusColor = _getStatusColor(status);
    final acList = _getAcList();
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
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.8),
                      ],
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
                                  _service.lokasiAlamat,
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
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
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
                        Tab(text: 'Daftar AC'),
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
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAcListTab(acList),
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

  // ==================== TAB 1: DAFTAR AC ====================
  Widget _buildAcListTab(List<Map<String, dynamic>> acList) {
    if (acList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.cpu, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Unit AC',
              style: greyTextStyle.copyWith(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada data AC pada service ini',
              style: greyTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: acList.length,
      itemBuilder: (context, index) {
        final ac = acList[index];
        final acId = int.tryParse((ac['id'] ?? '').toString()) ?? 0;
        final name = (ac['name'] ?? '-').toString();
        final brand = (ac['brand'] ?? '-').toString();
        final type = (ac['type'] ?? '-').toString();
        final capacity = (ac['capacity'] ?? '-').toString();
        final location = (ac['location'] ?? '-').toString();

        final techId = _getTechnicianIdForAc(acId);
        final itemStatus = _getItemStatus(acId);
        final statusColor = _getItemStatusColor(itemStatus);

        return GestureDetector(
          onTap: () {
            final acId = int.tryParse((ac['id'] ?? '').toString()) ?? 0;
            final item = _getItemByAcId(acId);

            if (item == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item service untuk AC ini tidak ditemukan')),
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
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.airdrop,
                    color: statusColor,
                    size: 26,
                  ),
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$brand • $type • $capacity',
                        style: greyTextStyle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Iconsax.location,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: greyTextStyle.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (techId != null) ...[
                        const SizedBox(height: 8),
                        Container(
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
                              const Icon(Iconsax.profile_2user,
                                  size: 12, color: Colors.blue),
                              const SizedBox(width: 4),
                              Consumer<OwnerMasterProvider>(
                                builder: (context, prov, _) => Text(
                                  _techNameById(prov, techId),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      },
    );
  }

  // ==================== TAB 2: TIM TEKNISI ====================
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
                  fontSize: 16, fontWeight: FontWeight.w600),
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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

  // ==================== TIMELINE CARD ====================
  Widget _buildTimelineCard() {
    final steps = [
      _TimelineStep(
        title: 'Ditugaskan',
        time: _service.tanggalDitugaskan,
        isCompleted: _service.tanggalDitugaskan != null,
      ),
      _TimelineStep(
        title: 'Dikerjakan',
        time: _service.tanggalMulai,
        isCompleted: _service.tanggalMulai != null,
      ),
      _TimelineStep(
        title: 'Selesai',
        time: _service.tanggalSelesai,
        isCompleted: _service.tanggalSelesai != null,
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
                child: const Icon(Iconsax.timer_1,
                    color: kPrimaryColor, size: 20),
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
                            ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
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
                              ? _formatDateTime(step.time!)
                              : 'Belum dimulai',
                          style: TextStyle(
                            fontSize: 13,
                            color: step.time != null
                                ? Colors.grey[600]
                                : Colors.grey[400],
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

  // ==================== DETAIL SERVICE CARD ====================
  Widget _buildServiceDetailsCard() {
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
            content: _service.catatan.isNotEmpty
                ? _service.catatan
                : 'Tidak ada keluhan',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            icon: Iconsax.key,
            title: 'Tindakan',
            content: _service.tindakan.isEmpty
                ? 'Belum ada tindakan'
                : _service.tindakan.map((e) => e.name).join(', '),
            color: Colors.blue,
          ),
          if (_service.diagnosa.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailItem(
              icon: Iconsax.clipboard_text,
              title: 'Diagnosa',
              content: _service.diagnosa,
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

  // ==================== INFO STAT ====================
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

  // ==================== DETAIL AC DIALOG ====================
  void _showAcDetailDialog(BuildContext context, Map<String, dynamic> ac) {
    final acId = int.tryParse((ac['id'] ?? '').toString()) ?? 0;
    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();
    final location = (ac['location'] ?? '-').toString();
    final serialNumber = (ac['serial_number'] ?? '-').toString();
    const condition = 'Baik';

    final techId = _getTechnicianIdForAc(acId);
    final item = _getItemByAcId(acId);
    final itemStatus = _getItemStatus(acId);
    final statusColor = _getItemStatusColor(itemStatus);

    final fotoSebelum = _photoUrlsOfItem(item, 'sebelum');
    final fotoPengerjaan = _photoUrlsOfItem(item, 'pengerjaan');
    final fotoSesudah = _photoUrlsOfItem(item, 'sesudah');

    _debugPrint('AC dialog acId=$acId itemStatus=$itemStatus '
        'sebelum=${fotoSebelum.length} pengerjaan=${fotoPengerjaan.length} sesudah=${fotoSesudah.length}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Iconsax.airdrop,
                      color: statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: primaryTextStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$brand • $type',
                          style: greyTextStyle.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
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
                      itemStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailSection(
                    title: 'Spesifikasi AC',
                    icon: Iconsax.cpu,
                    color: kPrimaryColor,
                    children: [
                      _buildInfoRow('Merk', brand, Iconsax.building),
                      _buildInfoRow('Tipe', type, Iconsax.category),
                      _buildInfoRow('Kapasitas', capacity, Iconsax.speedometer),
                      _buildInfoRow('Lokasi', location, Iconsax.location),
                      _buildInfoRow('Serial Number', serialNumber, Iconsax.barcode),
                      _buildInfoRow('Kondisi', condition, Iconsax.health),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (techId != null) ...[
                    _buildDetailSection(
                      title: 'Teknisi',
                      icon: Iconsax.profile_2user,
                      color: Colors.blue,
                      children: [
                        Consumer<OwnerMasterProvider>(
                          builder: (context, prov, _) => _buildInfoRow(
                            'Ditugaskan ke',
                            _techNameById(prov, techId),
                            Iconsax.profile_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (item != null) ...[
                    _buildDetailSection(
                      title: 'Timeline Item',
                      icon: Iconsax.timer,
                      color: Colors.orange,
                      children: [
                        _buildInfoRow(
                          'Status',
                          itemStatus.toUpperCase(),
                          Iconsax.status,
                          valueColor: statusColor,
                        ),
                        if (item['tanggal_mulai'] != null)
                          _buildInfoRow(
                            'Mulai',
                            _formatDateTime(DateTime.parse(item['tanggal_mulai'].toString())),
                            Iconsax.play_circle,
                          ),
                        if (item['tanggal_selesai'] != null)
                          _buildInfoRow(
                            'Selesai',
                            _formatDateTime(DateTime.parse(item['tanggal_selesai'].toString())),
                            Iconsax.tick_circle,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (fotoSebelum.isNotEmpty || fotoPengerjaan.isNotEmpty || fotoSesudah.isNotEmpty) ...[
                    _buildPhotoGallerySection(
                      fotoSebelum: fotoSebelum,
                      fotoPengerjaan: fotoPengerjaan,
                      fotoSesudah: fotoSesudah,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Iconsax.gallery, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Belum Ada Dokumentasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Foto dokumentasi belum tersedia',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (item != null) ...[
                    if (item['diagnosa'] != null && item['diagnosa'].toString().trim().isNotEmpty) ...[
                      _buildDetailSection(
                        title: 'Diagnosa',
                        icon: Iconsax.clipboard_text,
                        color: Colors.purple,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              item['diagnosa'].toString(),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (item['tindakan'] != null && item['tindakan'].toString().trim().isNotEmpty) ...[
                      _buildDetailSection(
                        title: 'Tindakan',
                        icon: Iconsax.key,
                        color: Colors.blue,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              item['tindakan'].toString(),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallerySection({
    required List<String> fotoSebelum,
    required List<String> fotoPengerjaan,
    required List<String> fotoSesudah,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.gallery, size: 18, color: kPrimaryColor),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dokumentasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (fotoSebelum.isNotEmpty) ...[
          _buildPhotoCategory('Sebelum Servis', fotoSebelum, Colors.orange),
          const SizedBox(height: 16),
        ],
        if (fotoPengerjaan.isNotEmpty) ...[
          _buildPhotoCategory('Proses Pengerjaan', fotoPengerjaan, Colors.blue),
          const SizedBox(height: 16),
        ],
        if (fotoSesudah.isNotEmpty) ...[
          _buildPhotoCategory('Sesudah Servis', fotoSesudah, Colors.green),
        ],
      ],
    );
  }

  Widget _buildPhotoCategory(String title, List<String> photos, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length > 5 ? 5 : photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = photos[index];
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, url),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      headers: _authHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, err, st) {
                        debugPrint('[PHOTO_DEBUG] Image error: $err');
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  color: Colors.grey[400], size: 32),
                              const SizedBox(height: 4),
                              Text('Gagal',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (photos.length > 5) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showAllPhotos(context, title, photos, color),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lihat ${photos.length} foto',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                color: Colors.black,
                child: Image.network(
                  url,
                  headers: _authHeaders,
                  fit: BoxFit.contain,
                  errorBuilder: (_, err, st) {
                    debugPrint('[PHOTO_DEBUG] Image error(full): $err');
                    return const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white70, size: 50),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllPhotos(
      BuildContext context,
      String title,
      List<String> photos,
      Color color,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Iconsax.gallery, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${photos.length} foto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final url = photos[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showFullScreenImage(context, url);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        headers: _authHeaders,
                        fit: BoxFit.cover,
                        errorBuilder: (_, err, st) {
                          debugPrint('[PHOTO_DEBUG] Image error(grid): $err');
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey[400], size: 30),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
