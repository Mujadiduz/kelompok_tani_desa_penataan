import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationHelper {
  NotificationHelper._();

  static const String _databaseUrl =
      'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app';

  static final FirebaseDatabase _db =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _databaseUrl,
  );

  static final DatabaseReference _notifRef =
      _db.ref('notifikasi');

  static final DatabaseReference _adminNotifRef =
      _db.ref('notifikasi_admin');

  static final DatabaseReference _anggotaRef =
      _db.ref('anggota');

  static String _cleanText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  static String _safeKey(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (cleaned.isEmpty) {
      return 'notifikasi';
    }

    return cleaned.length > 90
        ? cleaned.substring(0, 90)
        : cleaned;
  }

  static int _stableHash(String value) {
    int hash = 0x811C9DC5;

    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    return hash;
  }

  static String _buildEventKey({
    required String target,
    required String tipe,
    required String judul,
    required String pesan,
    String? eventId,
  }) {
    final cleanEventId = _cleanText(eventId);

    if (cleanEventId.isNotEmpty) {
      return _safeKey(
        '${tipe}_$cleanEventId',
      );
    }

    /*
     * Fallback anti-duplikat selama lima menit.
     * Ini mencegah satu tombol/proses yang terpanggil dua kali
     * membuat dua notifikasi identik.
     *
     * Untuk anti-duplikat paling kuat, kirim eventId berupa
     * ID pengajuan, NIK pendaftaran, atau ID pengumuman.
     */
    final bucket =
        DateTime.now().millisecondsSinceEpoch ~/
        const Duration(minutes: 5).inMilliseconds;

    final fingerprint = _stableHash(
      '$target|$tipe|$judul|$pesan|$bucket',
    );

    return _safeKey(
      '${tipe}_${bucket}_$fingerprint',
    );
  }

  static Map<String, dynamic> _notificationData({
    required String eventKey,
    required String judul,
    required String pesan,
    required String tipe,
    String? sumberId,
    String? nik,
  }) {
    final now = DateTime.now();

    return {
      'event_id': eventKey,
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'status': 'belum_dibaca',
      'dibaca': false,
      'tanggal': now.toIso8601String(),
      'timestamp': now.millisecondsSinceEpoch,
      if (_cleanText(sumberId).isNotEmpty)
        'sumber_id': _cleanText(sumberId),
      if (_cleanText(nik).isNotEmpty)
        'nik': _cleanText(nik),
    };
  }

  static Future<void> _writeOnce({
    required DatabaseReference reference,
    required Map<String, dynamic> data,
  }) async {
    await reference.runTransaction(
      (currentValue) {
        /*
         * Jika event yang sama sudah ada, transaksi dibatalkan.
         * Dengan begitu satu event tidak dapat membuat notifikasi
         * berulang pada node yang sama.
         */
        if (currentValue != null) {
          return Transaction.abort();
        }

        return Transaction.success(data);
      },
      applyLocally: false,
    ).timeout(
      const Duration(seconds: 10),
    );
  }

  static Future<void> _simpan({
    required String nik,
    required String judul,
    required String pesan,
    required String tipe,
    String? eventId,
    String? sumberId,
  }) async {
    final cleanNik = _cleanText(nik);

    if (cleanNik.isEmpty || cleanNik == '-') {
      return;
    }

    final eventKey = _buildEventKey(
      target: cleanNik,
      tipe: tipe,
      judul: judul,
      pesan: pesan,
      eventId: eventId,
    );

    final data = _notificationData(
      eventKey: eventKey,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      sumberId: sumberId ?? eventId,
      nik: cleanNik,
    );

    await _writeOnce(
      reference: _notifRef
          .child(cleanNik)
          .child(eventKey),
      data: data,
    );
  }

  static Future<void> _simpanAdmin({
    required String judul,
    required String pesan,
    required String tipe,
    String? nik,
    String? eventId,
    String? sumberId,
  }) async {
    final eventKey = _buildEventKey(
      target: 'admin',
      tipe: tipe,
      judul: judul,
      pesan: pesan,
      eventId: eventId,
    );

    final data = _notificationData(
      eventKey: eventKey,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      sumberId: sumberId ?? eventId,
      nik: nik,
    );

    await _writeOnce(
      reference: _adminNotifRef.child(eventKey),
      data: data,
    );
  }

  // =========================================================
  // NOTIFIKASI UNTUK ADMIN
  // Panggil sesudah proses penulisan data utama berhasil.
  // =========================================================

  static Future<void> calonAnggotaUntukAdmin({
    required String nik,
    required String nama,
    String? eventId,
  }) async {
    await _simpanAdmin(
      judul: 'Pendaftaran Anggota Baru',
      pesan:
          '$nama mengirim pendaftaran anggota dengan NIK $nik.',
      tipe: 'pendaftaran_anggota',
      nik: nik,
      eventId: eventId ?? nik,
      sumberId: eventId ?? nik,
    );
  }

  static Future<void> pengajuanPupukUntukAdmin({
    required String nik,
    required String nama,
    required String jenisPupuk,
    String jumlahKg = '',
    String? eventId,
  }) async {
    final jumlah = _cleanText(jumlahKg);

    await _simpanAdmin(
      judul: 'Pengajuan Bantuan Pupuk Baru',
      pesan: jumlah.isEmpty
          ? '$nama mengajukan bantuan pupuk $jenisPupuk.'
          : '$nama mengajukan bantuan pupuk '
              '$jenisPupuk sebanyak $jumlah Kg.',
      tipe: 'pengajuan_bantuan_pupuk',
      nik: nik,
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> peminjamanAlatUntukAdmin({
    required String nik,
    required String nama,
    required String namaAlat,
    int jumlah = 1,
    String tanggalPinjam = '',
    String tanggalKembali = '',
    String? eventId,
  }) async {
    final mulai = _cleanText(tanggalPinjam);
    final selesai = _cleanText(tanggalKembali);

    String tanggalText = '';

    if (mulai.isNotEmpty && selesai.isNotEmpty) {
      tanggalText = ' pada $mulai sampai $selesai';
    } else if (mulai.isNotEmpty) {
      tanggalText = ' pada $mulai';
    }

    await _simpanAdmin(
      judul: 'Pengajuan Peminjaman Alat Baru',
      pesan:
          '$nama mengajukan $namaAlat sebanyak '
          '$jumlah unit$tanggalText.',
      tipe: 'pengajuan_peminjaman_alat',
      nik: nik,
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> resetPasswordUntukAdmin({
    required String nik,
    required String nama,
    String? eventId,
  }) async {
    await _simpanAdmin(
      judul: 'Permintaan Reset Password',
      pesan:
          '$nama dengan NIK $nik mengirim permintaan '
          'reset password.',
      tipe: 'reset_password',
      nik: nik,
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> notifikasiAdminUmum({
    required String judul,
    required String pesan,
    required String tipe,
    String nik = '',
    String? eventId,
    String? sumberId,
  }) async {
    await _simpanAdmin(
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      nik: nik,
      eventId: eventId,
      sumberId: sumberId,
    );
  }

  // =========================================================
  // NOTIFIKASI UNTUK USER
  // Signature lama tetap kompatibel.
  // =========================================================

  static Future<void> pengumumanUntukSemuaAnggota({
    required String judul,
    required String isi,
    String? eventId,
  }) async {
    final snapshot = await _anggotaRef.get().timeout(
      const Duration(seconds: 12),
    );

    if (!snapshot.exists ||
        snapshot.value == null ||
        snapshot.value is! Map) {
      return;
    }

    final data = Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final Set<String> daftarNik = {};

    for (final entry in data.entries) {
      if (entry.value is! Map) {
        continue;
      }

      final anggota = Map<dynamic, dynamic>.from(
        entry.value as Map,
      );

      final nik = _cleanText(
        anggota['nik'] ?? entry.key,
      );

      if (nik.isNotEmpty && nik != '-') {
        daftarNik.add(nik);
      }
    }

    /*
     * Ditulis berurutan agar tidak membanjiri koneksi Firebase.
     */
    for (final nik in daftarNik) {
      await _simpan(
        nik: nik,
        judul: 'Pengumuman Baru',
        pesan: '$judul\n\n$isi',
        tipe: 'pengumuman',
        eventId: eventId,
        sumberId: eventId,
      );
    }
  }

  static Future<void> pupukDisetujui({
    required String nik,
    required String jenisPupuk,
    String? eventId,
  }) async {
    const judul = 'Bantuan Pupuk Disetujui';

    final pesan =
        'Pengajuan bantuan pupuk $jenisPupuk Anda telah '
        'disetujui admin. Silakan menunggu arahan pengambilan.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'bantuan_pupuk',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> pupukDitolak({
    required String nik,
    required String jenisPupuk,
    String? eventId,
  }) async {
    const judul = 'Bantuan Pupuk Ditolak';

    final pesan =
        'Pengajuan bantuan pupuk $jenisPupuk Anda ditolak '
        'oleh admin. Silakan cek kembali data pengajuan.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'bantuan_pupuk',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> pupukSudahDiambil({
    required String nik,
    required String jenisPupuk,
    required String jumlahKg,
    String? eventId,
  }) async {
    const judul = 'Pupuk Sudah Diambil';

    final pesan =
        'Bantuan pupuk $jenisPupuk sebanyak $jumlahKg Kg '
        'telah ditandai sudah diambil.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'bantuan_pupuk',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> alatDisetujui({
    required String nik,
    required String namaAlat,
    String? eventId,
  }) async {
    const judul = 'Peminjaman Alat Disetujui';

    final pesan =
        'Pengajuan peminjaman $namaAlat telah disetujui '
        'admin. Silakan menunggu arahan pengambilan alat.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> alatDitolak({
    required String nik,
    required String namaAlat,
    String? eventId,
  }) async {
    const judul = 'Peminjaman Alat Ditolak';

    final pesan =
        'Pengajuan peminjaman $namaAlat ditolak oleh admin. '
        'Silakan cek kembali data pengajuan.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> alatDipinjam({
    required String nik,
    required String namaAlat,
    required int jumlah,
    String? eventId,
  }) async {
    const judul = 'Alat Sudah Dipinjam';

    final pesan =
        'Peminjaman $namaAlat sebanyak $jumlah unit telah '
        'ditandai sedang dipinjam.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> alatDikembalikan({
    required String nik,
    required String namaAlat,
    required String pesanTambahan,
    String? eventId,
  }) async {
    const judul = 'Peminjaman Selesai';

    final pesan =
        'Alat $namaAlat telah ditandai sudah '
        'dikembalikan.$pesanTambahan';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'peminjaman_alat',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> anggotaDisetujui({
    required String nik,
    required String nama,
    String? eventId,
  }) async {
    const judul = 'Keanggotaan Disetujui';

    final pesan =
        'Selamat $nama, pendaftaran Anda telah disetujui '
        'sebagai anggota Kelompok Tani Desa Penataan. '
        'Silakan login menggunakan NIK Anda.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'keanggotaan',
      eventId: eventId ?? nik,
      sumberId: eventId ?? nik,
    );
  }

  static Future<void> anggotaDitolak({
    required String nik,
    required String nama,
    String? eventId,
  }) async {
    const judul = 'Keanggotaan Ditolak';

    final pesan =
        'Maaf $nama, pendaftaran anggota belum dapat '
        'disetujui. Silakan hubungi pengurus Kelompok Tani '
        'untuk informasi lebih lanjut.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'keanggotaan',
      eventId: eventId ?? nik,
      sumberId: eventId ?? nik,
    );
  }

  static Future<void> passwordBerhasilDireset({
    required String nik,
    required String passwordBaru,
    String? eventId,
  }) async {
    const judul = 'Password Berhasil Direset';

    final pesan =
        'Password sementara Anda adalah: $passwordBaru. '
        'Silakan login dan segera ubah password Anda '
        'melalui menu Profil.';

    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: 'reset_password',
      eventId: eventId,
      sumberId: eventId,
    );
  }

  static Future<void> notifikasiUserUmum({
    required String nik,
    required String judul,
    required String pesan,
    required String tipe,
    String? eventId,
    String? sumberId,
  }) async {
    await _simpan(
      nik: nik,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      eventId: eventId,
      sumberId: sumberId,
    );
  }
}