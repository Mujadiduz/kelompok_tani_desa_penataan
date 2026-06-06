import 'package:flutter/material.dart';
import 'pupuk_form_page.dart';

class PupukPage extends StatelessWidget {
  const PupukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            pupukCard(
              context,
              "Pupuk Urea",
              "Stok 500 Kg",
            ),

            const SizedBox(height: 15),

            pupukCard(
              context,
              "Pupuk NPK Phonska",
              "Stok 300 Kg",
            ),
          ],
        ),
      ),
    );
  }

  Widget pupukCard(
      BuildContext context,
      String nama,
      String stok,
      ) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.grass,
          color: Colors.green,
        ),
        title: Text(nama),
        subtitle: Text(stok),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PupukFormPage(
                  namaPupuk: nama,
                ),
              ),
            );
          },
          child: const Text("Pilih"),
        ),
      ),
    );
  }
}