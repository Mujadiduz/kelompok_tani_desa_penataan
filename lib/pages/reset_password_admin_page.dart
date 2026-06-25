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
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);

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
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: resetRef.onValue,
            builder: (context, snapshot) {
              final resetList = ambilResetList(snapshot.data?.snapshot.value);

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingView();
              }

              return RefreshIndicator(
                color: primaryGreen,
                onRefresh: refreshData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    _summaryCard(resetList.length),
                    const SizedBox(height: 16),
                    if (resetList.isEmpty)
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

  Widget _loadingView() {
    return const Center(child: CircularProgressIndicator(color: primaryGreen));
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
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
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola permintaan reset anggota.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: orangeStatus.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: orangeStatus,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total Permintaan Menunggu',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Permintaan reset password akan muncul otomatis di halaman ini.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12.4,
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

  Widget _resetCard(Map<String, dynamic> item) {
    final nama = (item['nama'] ?? 'Anggota').toString();
    final nik = (item['nik'] ?? '-').toString();
    final tanggal = formatTanggal(item['tanggal_pengajuan']);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: orangeStatus.withValues(alpha: 0.13),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: orangeStatus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 14),
          _detailBox(
            children: [
              _detailRow(
                icon: Icons.badge_rounded,
                label: 'NIK',
                value: sensorNik(nik),
              ),
              _detailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Tanggal',
                value: tanggal,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => bukaProsesReset(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.password_rounded),
              label: const Text(
                'Proses Reset Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: orangeStatus.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: orangeStatus.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'Menunggu',
        style: TextStyle(
          color: orangeStatus,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _detailBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 24),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: primaryGreen,
            size: 54,
          ),
          SizedBox(height: 13),
          Text(
            'Belum Ada Permintaan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Semua permintaan reset password sudah diproses atau belum ada anggota yang mengajukan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
