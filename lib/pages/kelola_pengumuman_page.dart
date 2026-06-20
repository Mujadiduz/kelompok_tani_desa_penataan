import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class KelolaPengumumanPage extends StatefulWidget {
  const KelolaPengumumanPage({super.key});

  @override
  State<KelolaPengumumanPage> createState() => _KelolaPengumumanPageState();
}

class _KelolaPengumumanPageState extends State<KelolaPengumumanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color redColor = Color(0xffDC2626);
  static const Color orangeColor = Color(0xffF59E0B);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference pengumumanRef;

  @override
  void initState() {
    super.initState();
    pengumumanRef = db.ref('pengumuman');
  }

  List<Map<String, dynamic>> ambilPengumuman(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries.where((entry) => entry.value is Map).map((entry) {
          final item = Map<String, dynamic>.from(entry.value);
          item['id'] = entry.key.toString();
          return item;
        }).toList();

    list.sort((a, b) {
      final waktuA = _nilaiWaktu(a);
      final waktuB = _nilaiWaktu(b);
      return waktuB.compareTo(waktuA);
    });

    return list;
  }

  int _nilaiWaktu(Map<String, dynamic> item) {
    final createdAt = item['created_at'];

    if (createdAt is int) return createdAt;
    if (createdAt is double) return createdAt.toInt();

    final tanggal = (item['tanggal'] ?? '').toString();
    final parsed = DateTime.tryParse(tanggal);

    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String tanggalHariIni() {
    final now = DateTime.now();
    final bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  Future<void> simpanPengumuman({
    String? id,
    required String judul,
    required String isi,
    required String status,
  }) async {
    final data = {
      'judul': judul.trim(),
      'isi': isi.trim(),
      'tanggal': tanggalHariIni(),
      'status': status,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (id == null) {
      await pengumumanRef.push().set(data);
    } else {
      await pengumumanRef.child(id).update({
        'judul': judul.trim(),
        'isi': isi.trim(),
        'status': status,
      });
    }
  }

  Future<void> ubahStatus(String id, String statusSekarang) async {
    final statusBaru = statusSekarang == 'aktif' ? 'nonaktif' : 'aktif';
    await pengumumanRef.child(id).update({'status': statusBaru});

    if (!mounted) return;
    _showSnackBar('Status pengumuman berhasil diperbarui.');
  }

  Future<void> hapusPengumuman(String id) async {
    await pengumumanRef.child(id).remove();

    if (!mounted) return;
    _showSnackBar('Pengumuman berhasil dihapus.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(message),
      ),
    );
  }

  void bukaForm({Map<String, dynamic>? item}) {
    final judulController = TextEditingController(
      text: item?['judul']?.toString() ?? '',
    );
    final isiController = TextEditingController(
      text: item?['isi']?.toString() ?? '',
    );

    String status = item?['status']?.toString() ?? 'aktif';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xffD1D5DB),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        item == null ? 'Tambah Pengumuman' : 'Edit Pengumuman',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pengumuman aktif akan tampil di halaman utama pengguna.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _inputField(
                        controller: judulController,
                        label: 'Judul Pengumuman',
                        hint: 'Contoh: Jadwal Pembagian Pupuk',
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: isiController,
                        label: 'Isi Pengumuman',
                        hint: 'Tulis isi pengumuman desa...',
                        icon: Icons.notes_rounded,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _statusOption(
                              title: 'Aktif',
                              selected: status == 'aktif',
                              color: primaryGreen,
                              onTap: () {
                                setModalState(() => status = 'aktif');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statusOption(
                              title: 'Nonaktif',
                              selected: status == 'nonaktif',
                              color: orangeColor,
                              onTap: () {
                                setModalState(() => status = 'nonaktif');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            if (judulController.text.trim().isEmpty ||
                                isiController.text.trim().isEmpty) {
                              _showSnackBar('Judul dan isi wajib diisi.');
                              return;
                            }

                            final navigator = Navigator.of(context);

                            await simpanPengumuman(
                              id: item?['id']?.toString(),
                              judul: judulController.text,
                              isi: isiController.text,
                              status: status,
                            );

                            if (!mounted) return;

                            navigator.pop();

                            _showSnackBar(
                              item == null
                                  ? 'Pengumuman berhasil ditambahkan.'
                                  : 'Pengumuman berhasil diperbarui.',
                            );
                          },
                          child: Text(
                            item == null
                                ? 'Simpan Pengumuman'
                                : 'Update Pengumuman',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryGreen),
            filled: true,
            fillColor: backgroundColor,
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xffE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xffE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: primaryGreen, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusOption({
    required String title,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : const Color(0xffE5E7EB)),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? color : textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  void konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Hapus Pengumuman?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Data pengumuman yang dihapus tidak dapat dikembalikan.',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await hapusPengumuman(id);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () => bukaForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: pengumumanRef.onValue,
                builder: (context, snapshot) {
                  final list = ambilPengumuman(snapshot.data?.snapshot.value);

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }

                  if (list.isEmpty) {
                    return _emptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _pengumumanCard(list[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kelola Pengumuman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tambah dan atur pengumuman desa yang akan tampil di halaman utama pengguna.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: primaryGreen,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Pengumuman',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan tambahkan pengumuman baru agar informasi penting dapat dibaca oleh anggota.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => bukaForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Tambah Pengumuman',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pengumumanCard(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final judul = (item['judul'] ?? '-').toString();
    final isi = (item['isi'] ?? '-').toString();
    final tanggal = (item['tanggal'] ?? '-').toString();
    final status = (item['status'] ?? 'nonaktif').toString().toLowerCase();
    final aktif = status == 'aktif';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      aktif
                          ? primaryGreen.withValues(alpha: 0.12)
                          : orangeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  aktif ? Icons.campaign_rounded : Icons.visibility_off_rounded,
                  color: aktif ? primaryGreen : orangeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isi,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: textGrey.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tanggal,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  title: aktif ? 'Nonaktifkan' : 'Aktifkan',
                  icon:
                      aktif
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                  color: aktif ? orangeColor : primaryGreen,
                  onTap: () => ubahStatus(id, status),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  title: 'Edit',
                  icon: Icons.edit_rounded,
                  color: blueColor,
                  onTap: () => bukaForm(item: item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  title: 'Hapus',
                  icon: Icons.delete_rounded,
                  color: redColor,
                  onTap: () => konfirmasiHapus(id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const Color blueColor = Color(0xff2563EB);

  Widget _statusBadge(String status) {
    final aktif = status == 'aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            aktif
                ? primaryGreen.withValues(alpha: 0.12)
                : orangeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        aktif ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: aktif ? primaryGreen : orangeColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
