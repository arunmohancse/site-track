import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/add_work_progress_screen.dart';
import 'package:mobile/add_work_qty_screen.dart';
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

  DateTime selectedDate = DateTime.now();

  String get formattedDate => selectedDate.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    loadSubmissionStatus();
  }

  Future<void> loadSubmissionStatus() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('daily_logs')
        .where('projectId', isEqualTo: widget.projectId)
        .where('date', isEqualTo: formattedDate)
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

  // 🔥 Reusable Card
  Widget _buildListCard({
    required String title,
    required String subtitle,
    required String date,
    VoidCallback? onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(date, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            if (!isLocked && onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }

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
          // 📅 DATE
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
                      setState(() => selectedDate = picked);
                      await loadSubmissionStatus();
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 6),

                      // ✅ FIX: show Today
                      Text(
                        formattedDate ==
                                DateTime.now().toIso8601String().substring(
                                  0,
                                  10,
                                )
                            ? "Today"
                            : formattedDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // ✅ SUBMIT BUTTON BACK
                ElevatedButton(
                  onPressed: isLocked
                      ? null
                      : () async {
                          bool confirmed =
                              await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Confirm Submission"),
                                  content: const Text(
                                    "Once submitted, it will be locked.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Confirm"),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (!confirmed) return;

                          await FirebaseFirestore.instance
                              .collection('daily_logs')
                              .add({
                                "projectId": widget.projectId,
                                "date": formattedDate,
                                "isSubmitted": true,
                                "isLocked": true,
                                "createdAt": Timestamp.now(),
                              });

                          await loadSubmissionStatus();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Day submitted")),
                          );
                        },
                  child: Text(
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

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// 🔹 LABOUR
                  sectionTitle(
                    "Labour",
                    isLocked
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddLabourScreen(projectId: projectId),
                            ),
                          ),
                  ),
                  _buildStream(
                    'labour_entries',
                    (e) => _buildListCard(
                      title: "${e['typeOfWork']} - ${e['description']}",
                      subtitle:
                          "₹${e['totalAmount']} | Skilled: ${e['skilledCount']} | Helper: ${e['helperCount']}",
                      date: e['date'],
                      onEdit: () => _openLabourEdit(e),
                    ),
                  ),

                  /// 🔹 MATERIAL RECEIVED
                  sectionTitle(
                    "Materials Received",
                    isLocked
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMaterialReceivedScreen(
                                projectId: projectId,
                                selectedDate: formattedDate,
                              ),
                            ),
                          ),
                  ),
                  _buildStream(
                    'materials_received',
                    (e) => _buildListCard(
                      title: e['material'],
                      subtitle:
                          "${e['quantity']} ${e['unit']} (${e['baseQuantity']})",
                      date: e['date'],
                      onEdit: () => _openMaterialReceivedEdit(e),
                    ),
                  ),

                  /// 🔹 MATERIAL USED
                  sectionTitle(
                    "Materials Used",
                    isLocked
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMaterialUsedScreen(
                                projectId: projectId,
                                selectedDate: formattedDate,
                              ),
                            ),
                          ),
                  ),
                  _buildStream(
                    'materials_used',
                    (e) => _buildListCard(
                      title: e['material'],
                      subtitle:
                          "${e['quantity']} ${e['unit']} (${e['baseQuantity']})",
                      date: e['date'],
                      onEdit: () => _openMaterialUsedEdit(e),
                    ),
                  ),

                  /// 🔹 WORK QTY
                  sectionTitle(
                    "Qty of Work",
                    isLocked
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddWorkQtyScreen(
                                projectId: projectId,
                                selectedDate: formattedDate,
                              ),
                            ),
                          ),
                  ),
                  _buildStream(
                    'work_qty_entries',
                    (e) => _buildListCard(
                      title: "${e['typeOfWork']} - ${e['description']}",
                      subtitle:
                          "Planned: ${e['plannedQty']} ${e['unit']}\nActual: ${e['actualQty']} ${e['unit']}",
                      date: e['date'],
                      onEdit: () => _openWorkQtyEdit(e),
                    ),
                  ),

                  /// 🔹 WORK PROGRESS
                  sectionTitle(
                    "Work Progress",
                    isLocked
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddWorkProgressScreen(
                                projectId: projectId,
                                selectedDate: formattedDate,
                              ),
                            ),
                          ),
                  ),
                  _buildStream(
                    'work_progress_entries',
                    (e) => _buildListCard(
                      title: "${e['typeOfWork']} - ${e['description']}",
                      subtitle: "Progress: ${e['progress']}%\n${e['remarks']}",
                      date: e['date'],
                      onEdit: () => _openWorkProgressEdit(e),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStream(
    String collection,
    Widget Function(QueryDocumentSnapshot e) builder,
  ) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('projectId', isEqualTo: widget.projectId)
          .where('date', isEqualTo: formattedDate)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(),
          );
        }

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No data"),
          );
        }

        return Column(children: docs.map(builder).toList());
      },
    );
  }

  // 🔥 EDIT HELPERS (FIXED CASTING)

  void _openLabourEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLabourScreen(
          projectId: widget.projectId,
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }

  void _openMaterialReceivedEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaterialReceivedScreen(
          projectId: widget.projectId,
          selectedDate: formattedDate,
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }

  void _openMaterialUsedEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaterialUsedScreen(
          projectId: widget.projectId,
          selectedDate: formattedDate,
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }

  void _openWorkQtyEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddWorkQtyScreen(
          projectId: widget.projectId,
          selectedDate: e['date'],
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }

  void _openWorkProgressEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddWorkProgressScreen(
          projectId: widget.projectId,
          selectedDate: e['date'],
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }
}
