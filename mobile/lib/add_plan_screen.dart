import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPlanScreen extends StatefulWidget {
  final String projectId;
  final String selectedDate;
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddPlanScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final planController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      planController.text = widget.existingData!['plan'] ?? "";
    }
  }

  Future<void> savePlan() async {
    final data = {
      "projectId": widget.projectId,
      "date": widget.selectedDate,
      "plan": planController.text,
      "createdAt": Timestamp.now(),
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('tomorrow_plan_entries')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance
          .collection('tomorrow_plan_entries')
          .add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Tomorrow Plan")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: planController,
              decoration: const InputDecoration(
                labelText: "Tomorrow Plan",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setState(() => isSaving = true);

                      try {
                        await savePlan();
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