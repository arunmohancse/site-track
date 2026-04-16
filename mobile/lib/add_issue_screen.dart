import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddIssueScreen extends StatefulWidget {
  final String projectId;
  final String selectedDate;
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddIssueScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddIssueScreen> createState() => _AddIssueScreenState();
}

class _AddIssueScreenState extends State<AddIssueScreen> {
  final issueController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      issueController.text = widget.existingData!['issue'] ?? "";
    }
  }

  Future<void> saveIssue() async {
    final data = {
      "projectId": widget.projectId,
      "date": widget.selectedDate,
      "issue": issueController.text,
      "createdAt": Timestamp.now(),
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('issues_entries')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance
          .collection('issues_entries')
          .add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Issue")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: issueController,
              decoration: const InputDecoration(
                labelText: "Issue / Delay",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                setState(() => isSaving = true);

                try {
                  await saveIssue();
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