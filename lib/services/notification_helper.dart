import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'notification_service.dart';

class NotificationHelper {
  NotificationHelper._();

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static final DatabaseReference _notifRef = _db.ref('notifikasi');
  static final DatabaseReference _anggotaRef = _db.ref('anggota');

  static Future<void> _simpan({
    required String nik,
    required String judul,
    required String pesan,
    required String tipe,
  }) async {
    final cleanNik = nik.trim();

    if (cleanNik.isEmpty || cleanNik == '-') return;

    await _notifRef.child(cleanNik).push().set({
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'status': 'belum_dibaca',
      'dibaca': false,
      'tanggal': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> pengumumanUntukSemuaAnggota({
    required String judul,
    required String isi,
  }) async {
    final snapshot = await _anggotaRef.get();

    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final Set<String> daftarNik = {};

    for (final entry in data.entries) {
      if (entry.value is Map) {
        final anggota = Map<dynamic, dynamic>.from(entry.value as Map);
        final nik = (anggota['nik'] ?? entry.key).toString().trim();

        if (nik.isNotEmpty && nik != '-') {
          daftarNik.add(nik);
        }
      }
    }

    for (final nik in daftarNik) {
      await _simpan(
        nik: nik,
        judul: 'Pengumuman Baru',
        pesan: '$judul\n\n$isi',
        tipe: 'pengumuman',
      );
    }

    await NotificationService.showLocalNotification(
      title: 'Pengumuman Baru',
      body: judul,
    );
  }

  static Future<void> pupukDisetujui({
    required String nik,
    required String jenisPupuk,
  }) async {
    const judul = 'Bantuan Pupuk Disetujui';
    final pesan =
        'Pengajuan bantuan pupuk $jenisPupuk Anda telah disetujui admin. Silakan menunggu arahan pengambilan.';

    await _simpan(nik: nik, judul: judul, pesan: pesan, tipe: 'bantuan_pupuk');

    await NotificationService.showLocalNotification(
      title: judul,
      body: 'Pengajuan bantuan pupuk $jenisPupuk telah disetujui.',
    );
  }

  static Future<void> pupukDitolak({
    required String nik,
    required String jenisPupuk,
  }) async {
    const judul = 'Bantuan Pupuk Ditolak';
    final pesan =
        'Pengajuan bantuan pupuk $jenisPupuk Anda ditolak oleh admin. Silakan cek kembali data pengajuan.';

    await _simpan(nik: nik, judul: judul, pesan: pesan, tipe: 'bantuan_pupuk');

    await NotificationService.showLocalNotification(
      title: judul,
      body: 'Pengajuan bantuan pupuk $jenisPupuk telah ditolak.',
    );
  }

  static Future<void> pupukSudahDiambil({
    required String nik,
    required String jenisPupuk,
    required String jumlahKg,
  }) async {
    const judul = 'Pupuk Sudah Diambil';
    final pesan =
        'Bantuan pupuk $jenisPupuk sebanyak $jumlahKg Kg telah ditandai sudah diambil.';

    await _simpan(nik: nik, judul: judul, pesan: pesan, tipe: 'bantuan_pupuk');

    await NotificationService.showLocalNotification(title: judul, body: pesan);
  }

  static Future<void> alatDisetujui({
    required String nik,
    required String namaAlat,
  }) async {
    const judul = 'Peminjaman Alat Disetujui';
    final pesan =
        'Pengajuan peminjaman $namaAlat telah disetujui admin. Silakan menunggu arahan pengambilan alat.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
    );

    await NotificationService.showLocalNotification(
      title: judul,
      body: 'Pengajuan peminjaman $namaAlat telah disetujui.',
    );
  }

  static Future<void> alatDitolak({
    required String nik,
    required String namaAlat,
  }) async {
    const judul = 'Peminjaman Alat Ditolak';
    final pesan =
        'Pengajuan peminjaman $namaAlat ditolak oleh admin. Silakan cek kembali data pengajuan.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
    );

    await NotificationService.showLocalNotification(
      title: judul,
      body: 'Pengajuan peminjaman $namaAlat telah ditolak.',
    );
  }

  static Future<void> alatDipinjam({
    required String nik,
    required String namaAlat,
    required int jumlah,
  }) async {
    const judul = 'Alat Sudah Dipinjam';
    final pesan =
        'Peminjaman $namaAlat sebanyak $jumlah unit telah ditandai sedang dipinjam.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
    );

    await NotificationService.showLocalNotification(title: judul, body: pesan);
  }

  static Future<void> alatDikembalikan({
    required String nik,
    required String namaAlat,
    required String pesanTambahan,
  }) async {
    const judul = 'Peminjaman Selesai';
    final pesan =
        'Alat $namaAlat telah ditandai sudah dikembalikan.$pesanTambahan';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
    );

    await NotificationService.showLocalNotification(title: judul, body: pesan);
  }

  static Future<void> anggotaDisetujui({
    required String nik,
    required String nama,
  }) async {
    const judul = 'Keanggotaan Disetujui';
    final pesan =
        'Selamat $nama, pendaftaran Anda telah disetujui sebagai anggota Kelompok Tani Desa Penataan. Silakan login menggunakan NIK Anda.';

    await _simpan(nik: nik, judul: judul, pesan: pesan, tipe: 'keanggotaan');

    await NotificationService.showLocalNotification(
      title: judul,
      body: 'Pendaftaran Anda telah disetujui.',
    );
  }

  static Future<void> anggotaDitolak({
    required String nik,
    required String nama,
  }) async {
    const judul = 'Keanggotaan Ditolak';
    final pesan =
        'Maaf $nama, pendaftaran anggota belum dapat disetujui. Silakan hubungi pengurus Kelompok Tani untuk informasi lebih lanjut.';

    await _simpan(nik: nik, judul: judul, pesan: pesan, tipe: 'keanggotaan');

    await NotificationService.showLocalNotification(
      title: judul,
      body: 'Pendaftaran Anda belum dapat disetujui.',
    );
  }
}
