import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/add_material_received_screen.dart';
import 'package:mobile/add_material_used_screen.dart';
import 'add_labour_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool isSubmitted = false;
  bool isLocked = true;
  bool isSubmitting = false;

  DateTime selectedDate = DateTime.now();

  String get formattedDate {
    return selectedDate.toString().substring(0, 10);
  }

  Future<void> loadSubmissionStatus() async {
    String selected = formattedDate;

    var snapshot = await FirebaseFirestore.instance
        .collection('daily_logs')
        .where('projectId', isEqualTo: widget.projectId)
        .where('date', isEqualTo: selected)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first;

      isSubmitted = data['isSubmitted'] == true;
      isLocked = data['isLocked'] == true;
    } else {
      isSubmitted = false;
      isLocked = false;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadSubmissionStatus();
  }

  Future<void> submitToday(String projectId) async {
    String selected = formattedDate;

    var query = await FirebaseFirestore.instance
        .collection('daily_logs')
        .where('projectId', isEqualTo: projectId)
        .where('date', isEqualTo: selected)
        .get();

    if (query.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('daily_logs').add({
        "projectId": projectId,
        "date": selected,
        "isSubmitted": true,
        "isLocked": true,
        "createdAt": Timestamp.now(),
      });
    } else {
      await query.docs.first.reference.update({
        "isSubmitted": true,
        "isLocked": true,
      });
    }
  }

  Future<bool> confirmSubmit() async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm Submission"),
              content: const Text(
                "Are you sure you want to submit?\n\nOnce submitted, this cannot be edited unless unlocked by admin.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false); // Cancel
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true); // Confirm
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // 🔥 Section Header with Add button
  Widget sectionTitle(String title, VoidCallback? onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName)),

      body: Column(
        children: [
          // 🔥 TOP BAR (DATE + SUBMIT)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 📅 DATE
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                      await loadSubmissionStatus();
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate ==
                                DateTime.now().toString().substring(0, 10)
                            ? "Today"
                            : formattedDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // ✅ SUBMIT
                ElevatedButton(
                  onPressed: isLocked || isSubmitting
                      ? null
                      : () async {
                          bool confirmed = await confirmSubmit();

                          if (!confirmed) return;

                          setState(() => isSubmitting = true);

                          await submitToday(projectId);
                          await loadSubmissionStatus();

                          setState(() => isSubmitting = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Day submitted")),
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isLocked
                              ? "Locked"
                              : isSubmitted
                              ? "Resubmit"
                              : "Submit",
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 🔹 LABOUR
                  sectionTitle(
                    "Labour",
                    isLocked
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddLabourScreen(projectId: projectId),
                              ),
                            );
                          },
                  ),

                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('labour_entries')
                        .where('projectId', isEqualTo: projectId)
                        .where('date', isEqualTo: formattedDate)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      var entries = snapshot.data!.docs;

                      if (entries.isEmpty) {
                        return const Text("No labour entries");
                      }

                      return Column(
                        children: entries.map((e) {
                          return Card(
                            child: ListTile(
                              title: Text(
                                "${e['typeOfWork']} - ${e['description']}",
                              ),
                              subtitle: Text(
                                "₹${e['totalAmount']} | Skilled: ${e['skilledCount']} | Helper: ${e['helperCount']}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(e['date']),
                                  if (!isLocked)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddLabourScreen(
                                              projectId: projectId,
                                              existingData: e.data(),
                                              docId: e.id,
                                            ),
                                          ),
                                        );

                                        // 🔥 refresh after returning
                                        if (result == true) {
                                          await loadSubmissionStatus();
                                          setState(() {});
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // 🔹 MATERIAL RECEIVED
                  sectionTitle(
                    "Materials Received",
                    isLocked
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddMaterialReceivedScreen(
                                  projectId: projectId,
                                  selectedDate: formattedDate,
                                ),
                              ),
                            );
                          },
                  ),

                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('materials_received')
                        .where('projectId', isEqualTo: projectId)
                        .where('date', isEqualTo: formattedDate)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      var docs = snapshot.data!.docs;

                      if (docs.isEmpty)
                        return const Text("No materials received");

                      return Column(
                        children: docs.map((e) {
                          return ListTile(
                            title: Text(e['material']),
                            subtitle: Text(
                              "${e['quantity']} ${e['unit']} (${e['baseQuantity']})",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e['date']),

                                if (!isLocked)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddMaterialReceivedScreen(
                                                projectId: projectId,
                                                selectedDate: formattedDate,
                                                existingData: e.data(),
                                                docId: e.id,
                                              ),
                                        ),
                                      );

                                      if (result == true) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // 🔹 MATERIAL USED
                  sectionTitle(
                    "Materials Used",
                    isLocked
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddMaterialUsedScreen(
                                  projectId: projectId,
                                  selectedDate: formattedDate,
                                ),
                              ),
                            );
                          },
                  ),

                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('materials_used')
                        .where('projectId', isEqualTo: projectId)
                        .where('date', isEqualTo: formattedDate)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      var docs = snapshot.data!.docs;

                      if (docs.isEmpty) return const Text("No materials used");

                      return Column(
                        children: docs.map((e) {
                          return ListTile(
                            title: Text(e['material']),
                            subtitle: Text(
                              "${e['quantity']} ${e['unit']} (${e['baseQuantity']})",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e['date']),

                                if (!isLocked)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddMaterialUsedScreen(
                                            projectId: projectId,
                                            selectedDate:
                                                formattedDate, // 🔥 important
                                            existingData: e.data(),
                                            docId: e.id,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
