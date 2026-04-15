import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWorkQtyScreen extends StatefulWidget {
  final String projectId;
  final String selectedDate; // ✅ required
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddWorkQtyScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddWorkQtyScreen> createState() => _AddWorkQtyScreenState();
}

class _AddWorkQtyScreenState extends State<AddWorkQtyScreen> {
  String? selectedType;
  String? selectedDescription;

  List<Map<String, dynamic>> workTypes = [];

  final plannedController = TextEditingController();
  final actualController = TextEditingController();
  final remarksController = TextEditingController();

  bool isSaving = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWorkTypes();
  }

  Future<void> loadWorkTypes() async {
    var snapshot =
    await FirebaseFirestore.instance.collection('work_types').get();

    List<Map<String, dynamic>> loaded =
    snapshot.docs.map((e) => e.data()).toList();

    String? tempType;
    String? tempDesc;

    if (widget.existingData != null) {
      final data = widget.existingData!;

      tempType = data['typeOfWork'];
      tempDesc = data['description'];

      plannedController.text = data['plannedQty'].toString();
      actualController.text = data['actualQty'].toString();
      remarksController.text = data['remarks'] ?? "";
    }

    setState(() {
      workTypes = loaded;
      selectedType = tempType;
      selectedDescription = tempDesc;
      isLoading = false;
    });
  }

  Future<void> saveWorkQty() async {
    double planned = double.tryParse(plannedController.text) ?? 0;
    double actual = double.tryParse(actualController.text) ?? 0;

    DateTime selected = DateTime.parse(widget.selectedDate);

    final data = {
      "projectId": widget.projectId,
      "typeOfWork": selectedType,
      "description": selectedDescription,
      "plannedQty": planned,
      "actualQty": actual,
      "pendingQty": planned - actual,
      "unit": "sqft",
      "remarks": remarksController.text,

      // ✅ IMPORTANT: same as labour screen
      "date": widget.selectedDate,

      // ✅ for sorting
      "createdAt": Timestamp.fromDate(selected),
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('work_qty_entries')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance
          .collection('work_qty_entries')
          .add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId != null ? "Edit Work Qty" : "Add Work Qty"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 TYPE DROPDOWN
            DropdownButtonFormField<String>(
              hint: const Text("Select Type of Work"),
              value: selectedType,
              items: workTypes.map((w) {
                return DropdownMenuItem<String>(
                  value: w['name'],
                  child: Text(w['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                  selectedDescription = null;
                });
              },
            ),

            const SizedBox(height: 10),

            // 🔹 DESCRIPTION DROPDOWN
            DropdownButtonFormField<String>(
              hint: const Text("Select Description"),
              value: selectedDescription,
              items: selectedType == null
                  ? []
                  : workTypes
                  .firstWhere((t) => t['name'] == selectedType)[
              'descriptions']
                  .map<DropdownMenuItem<String>>((desc) {
                return DropdownMenuItem<String>(
                  value: desc,
                  child: Text(desc),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDescription = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // 🔹 PLANNED QTY
            TextField(
              controller: plannedController,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: "Planned Qty"),
            ),

            const SizedBox(height: 10),

            // 🔹 ACTUAL QTY
            TextField(
              controller: actualController,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: "Actual Qty"),
            ),

            const SizedBox(height: 10),

            // 🔹 REMARKS
            TextField(
              controller: remarksController,
              decoration:
              const InputDecoration(labelText: "Remarks"),
            ),

            const SizedBox(height: 20),

            // 🔹 SAVE BUTTON
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                setState(() => isSaving = true);

                try {
                  await saveWorkQty();
                  Navigator.pop(context, true);
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
                child:
                CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}