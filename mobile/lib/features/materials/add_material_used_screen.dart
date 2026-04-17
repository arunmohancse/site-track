import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMaterialUsedScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? existingData;
  final String? docId;
  final String selectedDate;

  const AddMaterialUsedScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddMaterialUsedScreen> createState() => _AddMaterialUsedScreenState();
}

class _AddMaterialUsedScreenState extends State<AddMaterialUsedScreen> {
  List<Map<String, dynamic>> materials = [];

  String? selectedMaterial;
  String? selectedUnit;

  final qtyController = TextEditingController();

  Map<String, dynamic>? selectedMaterialData;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('materials_master')
        .get();

    List<Map<String, dynamic>> loadedMaterials = snapshot.docs
        .map((e) => e.data())
        .toList();

    // 🔥 Prepare variables first
    String? tempSelectedMaterial;
    String? tempSelectedUnit;
    Map<String, dynamic>? tempSelectedMaterialData;

    if (widget.existingData != null) {
      final data = widget.existingData!;

      tempSelectedMaterial = data['material'];
      tempSelectedUnit = data['unit'];
      qtyController.text = data['quantity'].toString();

      var match = loadedMaterials.where(
        (m) => m['name'] == tempSelectedMaterial,
      );

      if (match.isNotEmpty) {
        tempSelectedMaterialData = match.first;
      }
    }

    // 🔥 Single setState (clean + safe)
    setState(() {
      materials = loadedMaterials;
      selectedMaterial = tempSelectedMaterial;
      selectedUnit = tempSelectedUnit;
      selectedMaterialData = tempSelectedMaterialData;
    });
  }

  double convertToBase(double qty) {
    if (selectedUnit == selectedMaterialData!['baseUnit']) {
      return qty;
    }

    return qty * selectedMaterialData!['conversion'][selectedUnit];
  }

  Future<void> saveMaterial() async {
    double qty = double.tryParse(qtyController.text) ?? 0;
    double baseQty = convertToBase(qty);

    final data = {
      "projectId": widget.projectId,
      "material": selectedMaterial,
      "quantity": qty,
      "unit": selectedUnit,
      "baseQuantity": baseQty,
      "date": widget.selectedDate,
      "createdAt": Timestamp.now(),
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('materials_used') // 🔥 IMPORTANT
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('materials_used').add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Material Used")),
      body: Padding(
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
                  selectedMaterialData = materials.firstWhere(
                    (m) => m['name'] == value,
                  );
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

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setState(() => isSaving = true);

                      try {
                        await saveMaterial();

                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
