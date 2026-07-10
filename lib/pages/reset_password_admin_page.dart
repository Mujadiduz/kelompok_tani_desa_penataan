import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'reset_password_proses_page.dart';

class ResetPasswordAdminPage extends StatefulWidget {
  const ResetPasswordAdminPage({super.key});

  @override
  State<ResetPasswordAdminPage> createState() => _ResetPasswordAdminPageState();
}

class _ResetPasswordAdminPageState extends State<ResetPasswordAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffF3FBF5);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE6ECE8);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference resetRef;

  @override
  void initState() {
    super.initState();
    resetRef = db.ref('reset_password');
  }

  List<Map<String, dynamic>> ambilResetList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value as Map);
              item['id_reset'] = entry.key.toString();
              return item;
            })
            .where((item) {
              final status = (item['status'] ?? '').toString().toLowerCase();
              return status == 'menunggu';
            })
            .toList();

    list.sort((a, b) {
      final tglA = (a['tanggal_pengajuan'] ?? '').toString();
      final tglB = (b['tanggal_pengajuan'] ?? '').toString();
      return tglB.compareTo(tglA);
    });

    return list;
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  String formatTanggal(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '-';

    try {
      final date = DateTime.parse(text).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = _namaBulan(date.month);
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour.$minute WIB';
    } catch (_) {
      return text;
    }
  }

  String _namaBulan(int month) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (month < 1 || month > 12) return '-';
    return bulan[month - 1];
  }

  Future<void> refreshData() async {
    await resetRef.get();
  }

  void bukaProsesReset(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ResetPasswordProsesPage(
              idReset: (item['id_reset'] ?? '').toString(),
              nik: (item['nik'] ?? '').toString(),
              nama: (item['nama'] ?? 'Anggota').toString(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: resetRef.onValue,
            builder: (context, snapshot) {
              final resetList = ambilResetList(snapshot.data?.snapshot.value);

              return RefreshIndicator(
                color: primaryGreen,
                backgroundColor: Colors.white,
                onRefresh: refreshData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  children: [
                    _header(resetList.length),
                    const SizedBox(height: 14),
                    _statusPanel(resetList.length),
                    const SizedBox(height: 14),
                    _summaryRow(resetList.length),
                    const SizedBox(height: 18),
                    _sectionTitle(
                      title: 'Permintaan Reset',
                      subtitle: '${resetList.length} permintaan menunggu',
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Column(children: List.generate(3, (_) => _loadingCard()))
                    else if (snapshot.hasError)
                      _messageState(
                        icon: Icons.error_outline_rounded,
                        title: 'Terjadi Kesalahan',
                        message: snapshot.error.toString(),
                      )
                    else if (resetList.isEmpty)
                      _emptyCard()
                    else
                      ...resetList.map((item) => _resetCard(item)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepGreen, darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 11),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.19)),
            ),
            child: const Icon(
              Icons.password_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Password',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola permintaan anggota',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _headerBadge(total),
        ],
      ),
    );
  }

  Widget _headerBadge(int total) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        total > 99 ? '99+' : total.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statusPanel(int total) {
    final aman = total == 0;
    final color = aman ? primaryGreen : orangeStatus;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          _iconBox(
            aman ? Icons.task_alt_rounded : Icons.pending_actions_outlined,
            color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aman ? 'Tidak ada permintaan' : 'Perlu diproses admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  aman
                      ? 'Semua reset password sudah selesai.'
                      : '$total anggota menunggu password baru.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(int total) {
    return Row(
      children: [
        Expanded(
          child: _summaryItem(
            title: 'Menunggu',
            value: total.toString(),
            icon: Icons.hourglass_top_rounded,
            color: orangeStatus,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _summaryItem(
            title: 'Status',
            value: total > 0 ? 'Proses' : 'Aman',
            icon: Icons.verified_outlined,
            color: total > 0 ? blueStatus : primaryGreen,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _summaryItem(
            title: 'Aksi',
            value: total > 0 ? 'Cek' : 'Selesai',
            icon: Icons.manage_search_outlined,
            color: total > 0 ? orangeStatus : primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(radius: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: value.length > 6 ? 12.5 : 17,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resetCard(Map<String, dynamic> item) {
    final nama = (item['nama'] ?? 'Anggota').toString();
    final nik = (item['nik'] ?? '-').toString();
    final tanggal = formatTanggal(item['tanggal_pengajuan']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              _avatarBox(),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sensorNik(nik),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  icon: Icons.calendar_month_outlined,
                  text: tanggal,
                  color: blueStatus,
                ),
              ),
              const SizedBox(width: 10),
              _processButton(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarBox() {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: orangeStatus.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: orangeStatus.withValues(alpha: 0.12)),
      ),
      child: const Icon(
        Icons.person_search_outlined,
        color: orangeStatus,
        size: 27,
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
      decoration: BoxDecoration(
        color: orangeStatus.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: orangeStatus.withValues(alpha: 0.12)),
      ),
      child: const Text(
        'MENUNGGU',
        style: TextStyle(
          color: orangeStatus,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _miniInfo({
  required IconData icon,
  required String text,
  required Color color,
}) {
  return Container(
    constraints: const BoxConstraints(
      minHeight: 42,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _processButton(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => bukaProsesReset(item),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: primaryGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryGreen.withValues(alpha: 0.15)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_reset_rounded, color: primaryGreen, size: 19),
            SizedBox(width: 7),
            Text(
              'Proses',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: primaryGreen,
              size: 34,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Belum Ada Permintaan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 16.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Permintaan reset password anggota akan tampil di halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 12.2,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 34),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 16.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.2,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 4,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 41,
        width: 41,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.028),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}