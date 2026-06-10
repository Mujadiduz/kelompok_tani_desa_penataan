import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final nikController = TextEditingController();
  final teleponController = TextEditingController();
  final alamatController = TextEditingController();
  final jenisKelaminController = TextEditingController();
  final petakSawahController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  final DatabaseReference database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app/",
      ).ref();

  Future<void> simpanDataAnggota() async {
    await database
        .child("calon_anggota")
        .push()
        .set({
          "nama": namaController.text,
          "nik": nikController.text,
          "telepon": teleponController.text,
          "alamat": alamatController.text,
          "jenis_kelamin": jenisKelaminController.text,
          "jumlah_petak_sawah": petakSawahController.text,
          "password": passwordController.text,
          "status": "menunggu",
          "tanggal_daftar": DateTime.now().toString(),
        })
        .timeout(const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Daftar Calon Anggota"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Isi data diri dengan benar",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            inputField("Nama Lengkap", Icons.person, namaController),
            const SizedBox(height: 12),
            inputField("NIK", Icons.badge, nikController),
            const SizedBox(height: 12),
            inputField("No Telepon", Icons.phone, teleponController),
            const SizedBox(height: 12),
            inputField("Alamat", Icons.location_on, alamatController),
            const SizedBox(height: 12),
            inputField("Jenis Kelamin", Icons.people, jenisKelaminController),
            const SizedBox(height: 12),
            inputField("Jumlah Petak Sawah",Icons.agriculture,petakSawahController,),
            const SizedBox(height: 12),
            inputField("Password", Icons.lock, passwordController),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            await simpanDataAnggota();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data berhasil dikirim"),
                              ),
                            );

                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Gagal mengirim data: $e"),
                              ),
                            );
                          }

                          setState(() {
                            isLoading = false;
                          });
                        },
                child: Text(
                  isLoading ? "Mengirim..." : "Daftar",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
