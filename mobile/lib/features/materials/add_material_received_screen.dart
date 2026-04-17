import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMaterialReceivedScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? existingData;
  final String? docId;
  final String selectedDate;

  const AddMaterialReceivedScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddMaterialReceivedScreen> createState() =>
      _AddMaterialReceivedScreenState();
}

class _AddMaterialReceivedScreenState extends State<AddMaterialReceivedScreen> {
  List<Map<String, dynamic>> materials = [];

  String? selectedMaterial;
  String? selectedUnit;

  final qtyController = TextEditingController();

  final amountController = TextEditingController();

  Map<String, dynamic>? selectedMaterialData;

  bool isSaving = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMaterials(); // 🔥 correct place
  }

  Future<void> loadMaterials() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('materials_master')
        .get();

    materials = snapshot.docs.map((e) => e.data()).toList();

    // 🔥 Prefill AFTER materials load
    if (widget.existingData != null) {
      final data = widget.existingData!;

      selectedMaterial = data['material'];
      selectedUnit = data['unit'];
      qtyController.text = data['quantity'].toString();
      amountController.text = (data['totalAmount'] ?? 0).toString();

      var match = materials.where((m) => m['name'] == selectedMaterial);

      if (match.isNotEmpty) {
        selectedMaterialData = match.first;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  double convertToBase(double qty) {
    if (selectedMaterialData == null) return qty;

    if (selectedUnit == selectedMaterialData!['baseUnit']) {
      return qty;
    }

    return qty * (selectedMaterialData!['conversion'][selectedUnit] ?? 1);
  }

  Future<void> saveMaterial() async {
    double qty = double.tryParse(qtyController.text) ?? 0;
    double baseQty = convertToBase(qty);
    final totalAmount = double.tryParse(amountController.text) ?? 0;

    final data = {
      "projectId": widget.projectId,
      "material": selectedMaterial,
      "quantity": qty,
      "unit": selectedUnit,
      "baseQuantity": baseQty,
      "date": widget.selectedDate,
      "createdAt": Timestamp.now(),
      "totalAmount": totalAmount,
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('materials_received')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance
          .collection('materials_received')
          .add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Material Received")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 🔥 loading
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Material"),
                    value: selectedMaterial,
                    items: materials.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['name'],
                        child: Text(m['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMaterial = value;

                        var match = materials.where((m) => m['name'] == value);

                        if (match.isNotEmpty) {
                          selectedMaterialData = match.first;
                        }

                        selectedUnit = null;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    hint: const Text("Select Unit"),
                    value: selectedUnit,
                    items: selectedMaterialData == null
                        ? []
                        : (selectedMaterialData!['allowedUnits'] as List)
                              .map<DropdownMenuItem<String>>((u) {
                                return DropdownMenuItem<String>(
                                  value: u,
                                  child: Text(u),
                                );
                              })
                              .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUnit = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quantity"),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Total Amount"),
                  ),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setState(() => isSaving = true);

                            try {
                              await saveMaterial();

                              Navigator.pop(context, true); // 🔥 FIXED
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            } finally {
                              setState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Save"),
                  ),
                ],
              ),
            ),
    );
  }
}
