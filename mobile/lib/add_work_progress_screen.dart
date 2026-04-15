import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddWorkProgressScreen extends StatefulWidget {
  final String projectId;
  final String selectedDate;
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddWorkProgressScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddWorkProgressScreen> createState() =>
      _AddWorkProgressScreenState();
}

class _AddWorkProgressScreenState extends State<AddWorkProgressScreen> {
  String? selectedType;
  String? selectedDescription;

  List<Map<String, dynamic>> workTypes = [];

  final progressController = TextEditingController();
  final remarksController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadWorkTypes();
  }

  Future<void> loadWorkTypes() async {
    var snapshot =
    await FirebaseFirestore.instance.collection('work_types').get();

    var loaded = snapshot.docs.map((e) => e.data()).toList();

    if (widget.existingData != null) {
      final data = widget.existingData!;

      selectedType = data['typeOfWork'];
      selectedDescription = data['description'];
      progressController.text = data['progress'].toString();
      remarksController.text = data['remarks'] ?? "";
    }

    setState(() {
      workTypes = loaded;
      isLoading = false;
    });
  }

  Future<void> saveProgress() async {
    int progress = int.tryParse(progressController.text) ?? 0;

    final data = {
      "projectId": widget.projectId,
      "date": widget.selectedDate,
      "typeOfWork": selectedType,
      "description": selectedDescription,
      "progress": progress,
      "remarks": remarksController.text,
      "createdAt": Timestamp.now(),
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('work_progress_entries')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance
          .collection('work_progress_entries')
          .add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId != null
            ? "Edit Work Progress"
            : "Add Work Progress"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              hint: const Text("Type of Work"),
              value: selectedType,
              items: workTypes.map<DropdownMenuItem<String>>((w) {
                return DropdownMenuItem<String>(
                  value: w['name'] as String,
                  child: Text(w['name']),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedType = v;
                  selectedDescription = null;
                });
              },
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              hint: const Text("Description"),
              value: selectedDescription,
              items: selectedType == null
                  ? []
                  : workTypes
                  .firstWhere((t) => t['name'] == selectedType)['descriptions']
                  .map<DropdownMenuItem<String>>((d) {
                return DropdownMenuItem<String>(
                  value: d as String,
                  child: Text(d),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedDescription = v;
                });
              },
            ),

            const SizedBox(height: 10),

            TextField(
              controller: progressController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Progress (%)",
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: remarksController,
              decoration:
              const InputDecoration(labelText: "Remarks"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                setState(() => isSaving = true);

                await saveProgress();

                Navigator.pop(context, true);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}