import 'package:flutter/material.dart';
import 'admin_home_page.dart';
import 'register_page.dart';
import 'user_home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

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
                  controller: emailController,
                  decoration: inputDecoration("Email", Icons.email),
                ),
                const SizedBox(height: 14),

                TextField(
                  obscureText: true,
                  decoration: inputDecoration("Password", Icons.lock),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Checkbox(value: false, onChanged: (value) {}),
                    const Text("Ingat saya"),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Lupa Password?"),
                    ),
                  ],
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
                    onPressed: () {
                      if (emailController.text == "admin@gmail.com") {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminHomePage(),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserHomePage(),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Masuk",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text("atau"),
                const SizedBox(height: 20),

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
                    child: const Text("Daftar Akun Baru"),
                  ),
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
