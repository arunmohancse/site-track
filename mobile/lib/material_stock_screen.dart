import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialStockScreen extends StatelessWidget {
  final String projectId;

  const MaterialStockScreen({super.key, required this.projectId});

  Future<Map<String, double>> calculateStock() async {
    Map<String, double> stock = {};

    // 🔹 Get received
    var receivedSnapshot = await FirebaseFirestore.instance
        .collection('materials_received')
        .where('projectId', isEqualTo: projectId)
        .get();

    for (var doc in receivedSnapshot.docs) {
      String material = doc['material'];
      double qty = (doc['baseQuantity'] ?? 0).toDouble();

      stock[material] = (stock[material] ?? 0) + qty;
    }

    // 🔹 Subtract used
    var usedSnapshot = await FirebaseFirestore.instance
        .collection('materials_used')
        .where('projectId', isEqualTo: projectId)
        .get();

    for (var doc in usedSnapshot.docs) {
      String material = doc['material'];
      double qty = (doc['baseQuantity'] ?? 0).toDouble();

      stock[material] = (stock[material] ?? 0) - qty;
    }

    return stock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Material Stock")),
      body: FutureBuilder(
        future: calculateStock(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var stock = snapshot.data!;

          if (stock.isEmpty) {
            return const Center(child: Text("No data"));
          }

          return ListView(
            children: stock.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.toStringAsFixed(2)),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
