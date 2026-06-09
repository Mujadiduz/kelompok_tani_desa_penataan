import 'package:flutter/material.dart';

class JadwalAlatAdminPage extends StatelessWidget {
  const JadwalAlatAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f2ff),
      appBar: AppBar(
        title: const Text("Jadwal & Ketersediaan Alat"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              items: const [
                DropdownMenuItem(value: "Traktor", child: Text("Traktor")),
                DropdownMenuItem(
                  value: "Hand Sprayer",
                  child: Text("Hand Sprayer"),
                ),
                DropdownMenuItem(
                  value: "Cangkul Mesin",
                  child: Text("Cangkul Mesin"),
                ),
              ],
              onChanged: (value) {},
              decoration: const InputDecoration(labelText: "Pilih Alat"),
            ),

            const SizedBox(height: 20),

            const Text(
              "Juni 2026",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                itemCount: 30,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
