import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _timeZone =
      'Asia/Jakarta';

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Seluruh reminder maintenance menggunakan WIB
    tz.setLocalLocation(
      tz.getLocation(
        _timeZone,
      ),
    );

    const androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) {
        final payload =
            response.payload;

        debugPrint(
          'Notification payload: $payload',
        );

        // ======================================================
        // NANTI BISA DIGUNAKAN UNTUK NAVIGASI
        //
        // contoh payload:
        //
        // maintenance:5:2026-09-27
        //
        // locationId = 5
        // tanggal service = 2026-09-27
        // ======================================================
      },
    );
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<void> requestPermission() async {
    // ==========================================================
    // ANDROID
    // ==========================================================

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.requestNotificationsPermission();

    // ==========================================================
    // IOS
    // ==========================================================

    final iosPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ============================================================
  // SCHEDULE MAINTENANCE
  //
  // LOGIKA:
  //
  // nextServiceDate = 27 Sep 2026
  //
  // reminder:
  // 20 Sep 2026
  // jam 12.00 WIB
  //
  // 1 notification untuk:
  //
  // lokasi + tanggal service
  //
  // contoh:
  //
  // 20 AC
  // Griya Mandiri
  // tanggal service 27 Sep
  //
  // = 1 notification
  //
  // ============================================================

  Future<void> scheduleMaintenanceReminder({
    required int locationId,
    required String locationName,
    required int totalAc,
    required DateTime nextServiceDate,
  }) async {
    // ==========================================================
    // VALIDASI
    // ==========================================================

    if (locationId <= 0) {
      return;
    }

    if (totalAc <= 0) {
      return;
    }

    final safeLocationName =
    locationName.trim().isEmpty
        ? 'Lokasi AC'
        : locationName.trim();

    // ==========================================================
    // NORMALISASI TANGGAL SERVICE
    //
    // kita hanya peduli:
    //
    // tahun
    // bulan
    // tanggal
    //
    // ==========================================================

    final normalizedServiceDate =
    DateTime(
      nextServiceDate.year,
      nextServiceDate.month,
      nextServiceDate.day,
    );

    // ==========================================================
    // H-7
    // ==========================================================

    final reminderDate =
    normalizedServiceDate.subtract(
      const Duration(
        days: 7,
      ),
    );

    // ==========================================================
    // WIB
    // ==========================================================

    final jakarta =
    tz.getLocation(
      _timeZone,
    );

    // ==========================================================
    // JAM 12 SIANG WIB
    // ==========================================================

    final scheduledDate =
    tz.TZDateTime(
      jakarta,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      12,
      0,
    );

    final now =
    tz.TZDateTime.now(
      jakarta,
    );

    // ==========================================================
    // JIKA WAKTU NOTIFIKASI SUDAH LEWAT
    //
    // jangan schedule ulang.
    //
    // Contoh:
    //
    // tanggal service = 27 Sep
    // H-7 = 20 Sep
    //
    // user buka aplikasi tanggal 21 Sep
    //
    // maka tidak dikirim ulang.
    //
    // ==========================================================

    if (!scheduledDate.isAfter(
      now,
    )) {
      debugPrint(
        'SKIP notif maintenance: '
            '$safeLocationName | '
            '${DateFormat('yyyy-MM-dd').format(normalizedServiceDate)} '
            'karena jadwal notif sudah lewat.',
      );

      return;
    }

    // ==========================================================
    // NOTIFICATION ID
    //
    // ID berdasarkan:
    //
    // locationId + serviceDate
    //
    // sehingga:
    //
    // lokasi 5 tanggal 27 Sep
    //
    // berbeda dengan:
    //
    // lokasi 5 tanggal 28 Sep
    //
    // ==========================================================

    final notificationId =
    _maintenanceNotificationId(
      locationId: locationId,
      serviceDate:
      normalizedServiceDate,
    );

    // ==========================================================
    // ANDROID DETAIL
    // ==========================================================

    const androidDetails =
    AndroidNotificationDetails(
      'maintenance_reminder',
      'Pengingat Servis AC',
      channelDescription:
      'Pengingat jadwal perawatan dan servis AC',
      importance:
      Importance.high,
      priority:
      Priority.high,
      enableVibration:
      true,
    );

    // ==========================================================
    // IOS DETAIL
    // ==========================================================

    const iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ==========================================================
    // FORMAT TANGGAL
    // ==========================================================

    final formattedServiceDate =
    DateFormat(
      'd MMM yyyy',
      'id_ID',
    ).format(
      normalizedServiceDate,
    );

    // ==========================================================
    // TITLE
    // ==========================================================

    const title =
        'Pengingat Servis AC';

    // ==========================================================
    // BODY
    // ==========================================================

    final body =
        '$totalAc unit AC di $safeLocationName '
        'perlu servis pada $formattedServiceDate.';

    // ==========================================================
    // PAYLOAD
    //
    // format:
    //
    // maintenance:locationId:yyyy-MM-dd
    //
    // ==========================================================

    final payload =
        'maintenance:'
        '$locationId:'
        '${DateFormat('yyyy-MM-dd').format(normalizedServiceDate)}';

    // ==========================================================
    // CANCEL JADWAL DENGAN ID SAMA
    //
    // Misalnya:
    //
    // sebelumnya 17 AC
    //
    // setelah refresh menjadi:
    //
    // 20 AC
    //
    // notif lama dibuang lalu dibuat baru.
    //
    // Jadi tetap hanya 1 notif.
    //
    // ==========================================================

    await _plugin.cancel(
      notificationId,
    );

    // ==========================================================
    // SCHEDULE NOTIFICATION
    // ==========================================================

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,

      // Untuk reminder H-7
      // tidak perlu exact alarm.
      androidScheduleMode:
      AndroidScheduleMode.inexactAllowWhileIdle,

      payload:
      payload,

      // TIDAK menggunakan:
      //
      // matchDateTimeComponents
      //
      // sehingga notif hanya sekali.
    );

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      '========================================',
    );

    debugPrint(
      'NOTIF MAINTENANCE BERHASIL DIJADWALKAN',
    );

    debugPrint(
      'notificationId : $notificationId',
    );

    debugPrint(
      'locationId     : $locationId',
    );

    debugPrint(
      'location       : $safeLocationName',
    );

    debugPrint(
      'total AC       : $totalAc',
    );

    debugPrint(
      'service date   : $formattedServiceDate',
    );

    debugPrint(
      'notification   : $scheduledDate',
    );

    debugPrint(
      'payload        : $payload',
    );

    debugPrint(
      '========================================',
    );
  }

  // ============================================================
  // CANCEL MAINTENANCE
  //
  // membatalkan notifikasi berdasarkan:
  //
  // lokasi + tanggal service
  //
  // ============================================================

  Future<void> cancelMaintenanceReminder({
    required int locationId,
    required DateTime serviceDate,
  }) async {
    final normalizedDate =
    DateTime(
      serviceDate.year,
      serviceDate.month,
      serviceDate.day,
    );

    final notificationId =
    _maintenanceNotificationId(
      locationId:
      locationId,
      serviceDate:
      normalizedDate,
    );

    await _plugin.cancel(
      notificationId,
    );

    debugPrint(
      'Cancel notification: $notificationId',
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  Future<void> cancelAll() async {
    await _plugin.cancelAll();

    debugPrint(
      'Semua notification dibatalkan.',
    );
  }

  // ============================================================
  // NOTIFICATION ID
  //
  // harus unik berdasarkan:
  //
  // location + tanggal service
  //
  // contoh:
  //
  // location = 5
  // service = 2026-09-27
  //
  // location = 5
  // service = 2026-09-28
  //
  // harus berbeda.
  //
  // ============================================================

  int _maintenanceNotificationId({
    required int locationId,
    required DateTime serviceDate,
  }) {
    // ==========================================================
    // DATE KEY
    //
    // 2026-09-27
    //
    // menjadi:
    //
    // 20260927
    //
    // ==========================================================

    final dateKey =
        serviceDate.year * 10000 +
            serviceDate.month * 100 +
            serviceDate.day;

    // ==========================================================
    // Dart/Android notification id sebaiknya tetap berada
    // dalam range integer 32-bit.
    //
    // Jadi jangan menggunakan:
    //
    // locationId * 100000000 + dateKey
    //
    // karena berpotensi terlalu besar.
    //
    // Kita buat hash deterministik sederhana.
    // ==========================================================

    var id =
        (locationId * 1000003 +
            dateKey)
            .hashCode;

    // pastikan positif
    id =
    id & 0x7fffffff;

    // hindari id test
    if (id == 999999) {
      id++;
    }

    return id;
  }

  // ============================================================
  // TEST NOTIFICATION
  //
  // muncul sekitar 10 detik setelah dipanggil.
  //
  // ============================================================

  Future<void> testNotification() async {
    final jakarta =
    tz.getLocation(
      _timeZone,
    );

    final scheduledDate =
    tz.TZDateTime.now(
      jakarta,
    ).add(
      const Duration(
        seconds: 10,
      ),
    );

    const details =
    NotificationDetails(
      android:
      AndroidNotificationDetails(
        'maintenance_test',
        'Test Notification',
        channelDescription:
        'Channel untuk testing notification',
        importance:
        Importance.high,
        priority:
        Priority.high,
        enableVibration:
        true,
      ),
      iOS:
      DarwinNotificationDetails(
        presentAlert:
        true,
        presentBadge:
        true,
        presentSound:
        true,
      ),
    );

    await _plugin.cancel(
      999999,
    );

    await _plugin.zonedSchedule(
      999999,
      'Pengingat Servis AC',
      '20 unit AC di Griya Mandiri Tanjung '
          'perlu servis 7 hari lagi.',
      scheduledDate,
      details,
      androidScheduleMode:
      AndroidScheduleMode.inexactAllowWhileIdle,
      payload:
      'maintenance_test',
    );

    debugPrint(
      'TEST notification dijadwalkan: '
          '$scheduledDate',
    );
  }

  // ============================================================
  // SHOW NOTIFICATION NOW
  //
  // Ini opsional.
  //
  // Berguna saat debugging tanpa menunggu 10 detik.
  //
  // ============================================================

  Future<void> showTestNotificationNow() async {
    const details =
    NotificationDetails(
      android:
      AndroidNotificationDetails(
        'maintenance_test',
        'Test Notification',
        channelDescription:
        'Channel untuk testing notification',
        importance:
        Importance.high,
        priority:
        Priority.high,
        enableVibration:
        true,
      ),
      iOS:
      DarwinNotificationDetails(
        presentAlert:
        true,
        presentBadge:
        true,
        presentSound:
        true,
      ),
    );

    await _plugin.show(
      999998,
      'Pengingat Servis AC',
      '20 unit AC di Griya Mandiri Tanjung '
          'akan memasuki jadwal servis.',
      details,
      payload:
      'maintenance_test_now',
    );
  }
}