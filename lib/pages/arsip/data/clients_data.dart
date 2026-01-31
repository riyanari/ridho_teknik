import '../../../models/client_record.dart';
import '../../../models/complaint_record.dart';

final List<ClientRecord> clientsDummy = [
  ClientRecord(
    name: 'Bapak Ahmad Rizki',
    address: 'Jl. Mawar No. 12, Tebet, Jakarta Selatan',
    whatsapp: '08123456789',
    mapsQuery: '-6.2315,106.8451',
    complaints: [
      ComplaintRecord(title: 'AC tidak dingin', date: DateTime(2025, 10, 2)),
      ComplaintRecord(title: 'Bocor air indoor', date: DateTime(2025, 10, 10)),
    ],
  ),
  ClientRecord(
    name: 'Ibu Sari Dewi',
    address: 'Perumahan Griya Asri Blok C5, Bekasi',
    whatsapp: '08129876543',
    mapsQuery: 'Perumahan Griya Asri C5 Bekasi',
    complaints: [
      ComplaintRecord(
        title: 'Maintenance bulanan',
        date: DateTime(2025, 9, 28),
      ),
    ],
  ),
  ClientRecord(
    name: 'PT. Maju Jaya Abadi',
    address: 'Jl. Gatot Subroto No. 7, Jakarta Selatan',
    whatsapp: '081511223344',
    mapsQuery: 'Jl. Gatot Subroto No.7 Jakarta Selatan',
    complaints: [
      ComplaintRecord(title: 'Central AC error'),
      ComplaintRecord(title: 'Ganti freon', date: DateTime(2025, 10, 11)),
    ],
  ),
  ClientRecord(
    name: 'Hotel Grand Palace',
    address: 'Jl. Sudirman No. 456, Jakarta',
    whatsapp: '081355667788',
    mapsQuery: 'Hotel Grand Palace Jakarta',
    complaints: [
      ComplaintRecord(title: 'Central AC error', date: DateTime(2025, 10, 11)),
    ],
  ),
  ClientRecord(
    name: 'Bapak Budi Santoso',
    address: 'Jl. Merdeka No. 123, Jakarta Pusat',
    whatsapp: '081212341234',
    mapsQuery: 'Jl. Merdeka No.123 Jakarta Pusat',
    complaints: [
      ComplaintRecord(title: 'Cuci AC', date: DateTime(2025, 10, 11)),
    ],
  ),
  ClientRecord(
    name: 'Ibu Ani Wijaya',
    address: 'Depok, Pancoran Mas',
    whatsapp: '082233445566',
    mapsQuery: 'Pancoran Mas Depok',
    complaints: [
      ComplaintRecord(title: 'Instalasi AC baru', date: DateTime(2025, 10, 11)),
    ],
  ),
  ClientRecord(
    name: 'Kantor PT. Sejahtera',
    address: 'Kuningan City Lt. 15, Jakarta Selatan',
    whatsapp: '081377788899',
    mapsQuery: 'Kuningan City Jakarta',
    complaints: [
      ComplaintRecord(
        title: 'Troubleshoot kompresor',
        date: DateTime(2025, 10, 11),
      ),
    ],
  ),
  ClientRecord(
    name: 'Ruko Harmoni',
    address: 'Harmoni, Jakarta Pusat',
    whatsapp: '081234000999',
    mapsQuery: 'Harmoni Jakarta Pusat',
    complaints: [
      ComplaintRecord(title: 'Ganti freon', date: DateTime(2025, 10, 11)),
    ],
  ),
];
