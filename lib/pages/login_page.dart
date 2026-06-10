import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'admin_home_page.dart';
import 'register_page.dart';
import 'status_keanggotaan_page.dart';
import 'user_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nikController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("anggota");

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    if (nikController.text.trim() == "admin" &&
        passwordController.text.trim() == "admin123") {
      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
      return;
    }

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      bool loginBerhasil = false;
      String namaLogin = "";
      String nikLogin = "";

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((key, value) {
          final anggota = Map<String, dynamic>.from(value as Map);

          final nikFirebase = (anggota["nik"] ?? "").toString().trim();
          final passwordFirebase =
              (anggota["password"] ?? "").toString().trim();
          final statusFirebase =
              (anggota["status"] ?? "").toString().toLowerCase();

          if (nikFirebase == nikController.text.trim() &&
              passwordFirebase == passwordController.text.trim() &&
              statusFirebase == "aktif") {
            namaLogin = anggota["nama"] ?? "";
            nikLogin = anggota["nik"] ?? "";
            loginBerhasil = true;
          }
        });
      }

      if (loginBerhasil) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserHomePage(
              nama: namaLogin,
              nik: nikLogin,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Login gagal. Akun belum disetujui admin atau data salah.",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal login: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xffdff3df),
                  child: Icon(Icons.eco, size: 55, color: Colors.green),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Selamat Datang!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Text("Masuk untuk melanjutkan"),
                const SizedBox(height: 30),

                TextField(
                  controller: nikController,
                  keyboardType: TextInputType.text,
                  decoration: inputDecoration("NIK / Admin", Icons.badge),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: inputDecoration("Password", Icons.lock),
                ),

                const SizedBox(height: 16),

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
                    onPressed: isLoading ? null : login,
                    child: Text(
                      isLoading ? "Memeriksa..." : "Masuk",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text("atau"),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text("Daftar Calon Anggota"),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatusKeanggotaanPage(),
                      ),
                    );
                  },
                  child: const Text("Cek Status Keanggotaan"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}