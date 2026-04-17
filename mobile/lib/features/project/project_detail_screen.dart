// 🔥 FINAL: SAME STRUCTURE (Your Original Style) + FIXES APPLIED

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/features/issues/add_issue_screen.dart';
import 'package:mobile/features/labour/add_labour_screen.dart';
import 'package:mobile/features/materials/add_material_received_screen.dart';
import 'package:mobile/features/materials/add_material_used_screen.dart';
import 'package:mobile/features/photos/add_photo_screen.dart';
import 'package:mobile/features/plan/add_plan_screen.dart';
import 'package:mobile/features/requests/add_material_request_screen.dart';
import 'package:mobile/features/work/add_work_progress_screen.dart';
import 'package:mobile/features/work/add_work_qty_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  final bool isReadOnly;
  final String? initialDate;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.isReadOnly = false,
    this.initialDate,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool isSubmitted = false;
  bool isLocked = false;

  DateTime selectedDate = DateTime.now();

  String get formattedDate => selectedDate.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();

    if (widget.initialDate != null) {
      selectedDate = DateTime.parse(widget.initialDate!);
    }

    loadSubmissionStatus();
  }

  bool get isViewOnly => widget.isReadOnly;

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

  Future<void> _deleteItem(String collection, String docId) async {
    if (isLocked) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Do you want to delete?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
  }

  Widget _buildListCard({
    required String title,
    required String subtitle,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLocked && !isViewOnly && onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            if (!isLocked && !isViewOnly && onEdit != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
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
          if (!isLocked && !isViewOnly)
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
          /// DATE + SUBMIT
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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

                      /// 🔥 THIS IS THE FIX
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
                if (!isViewOnly)
                  ElevatedButton(
                    onPressed: isLocked
                        ? null
                        : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Submit"),
                          content: const Text(
                              "Are you sure you want to submit? You cannot edit after this."),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text("Submit"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      // 👉 your original logic (unchanged)
                      await FirebaseFirestore.instance
                          .collection('daily_logs')
                          .doc("${widget.projectId}_$formattedDate")
                          .set({
                        "projectId": widget.projectId,
                        "date": formattedDate,
                        "isSubmitted": true,
                        "isLocked": true,
                      });

                      await loadSubmissionStatus();
                    },
                    child: Text(isLocked ? "Locked" : "Submit"),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// LABOUR
                  sectionTitle(
                    "Labour",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddLabourScreen(
                          projectId: projectId,
                          selectedDate: formattedDate,
                        ),
                      ),
                    ),
                  ),
                  _buildStream(
                    'labour_entries',
                    (e) => _buildListCard(
                      title: "${e['typeOfWork']} - ${e['description']}",
                      subtitle: "₹${e['totalAmount']}",
                      onEdit: () => _openLabourEdit(e),
                      onDelete: () => _deleteItem('labour_entries', e.id),
                    ),
                  ),

                  /// MATERIAL USED
                  sectionTitle(
                    "Materials Used",
                    () => Navigator.push(
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
                      subtitle: "${e['quantity']}",
                      onEdit: () => _openMaterialUsedEdit(e),
                      onDelete: () => _deleteItem('materials_used', e.id),
                    ),
                  ),

                  /// 🔹 MATERIAL RECEIVED
                  sectionTitle(
                    "Materials Received",
                    (isLocked || isViewOnly)
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
                      onEdit: isViewOnly
                          ? null
                          : () => _openMaterialReceivedEdit(e),
                      onDelete: isViewOnly
                          ? null
                          : () => _deleteItem('materials_received', e.id),
                    ),
                  ),

                  /// 🔹 MATERIAL REQUESTS
                  sectionTitle(
                    "Material Requests",
                    (isLocked || isViewOnly)
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMaterialRequestScreen(
                          projectId: projectId,
                          selectedDate: formattedDate,
                        ),
                      ),
                    ),
                  ),

                  _buildStream(
                    'material_requests',
                        (e) => _buildListCard(
                      title: e['request'],
                      subtitle: "",
                      onEdit: isViewOnly
                          ? null
                          : () => _openMaterialRequestEdit(e),
                      onDelete: isViewOnly
                          ? null
                          : () => _deleteItem('material_requests', e.id),
                    ),
                  ),

                  sectionTitle(
                    "Work Quantity",
                    (isLocked || isViewOnly)
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
                      title: e['typeOfWork'],
                      subtitle: "${e['unit']}",
                      onEdit: isViewOnly
                          ? null
                          : () => _openWorkQtyEdit(e),
                      onDelete: isViewOnly
                          ? null
                          : () => _deleteItem('work_qty_entries', e.id),
                    ),
                  ),

                  sectionTitle(
                    "Work Progress",
                    (isLocked || isViewOnly)
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
                      title: e['typeOfWork'],
                      subtitle: e['remarks'] ?? "",
                      onEdit: isViewOnly
                          ? null
                          : () => _openWorkProgressEdit(e),
                      onDelete: isViewOnly
                          ? null
                          : () => _deleteItem('work_progress_entries', e.id),
                    ),
                  ),

                  /// ISSUES
                  sectionTitle(
                    "Issues",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddIssueScreen(
                          projectId: projectId,
                          selectedDate: formattedDate,
                        ),
                      ),
                    ),
                  ),
                  _buildStream(
                    'issues_entries',
                    (e) => _buildListCard(
                      title: e['issue'],
                      subtitle: "",
                      onEdit: () => _openIssueEdit(e),
                      onDelete: () => _deleteItem('issues_entries', e.id),
                    ),
                  ),

                  /// PLAN
                  sectionTitle(
                    "Plan",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPlanScreen(
                          projectId: projectId,
                          selectedDate: formattedDate,
                        ),
                      ),
                    ),
                  ),
                  _buildStream(
                    'tomorrow_plan_entries',
                    (e) => _buildListCard(
                      title: e['plan'],
                      subtitle: "",
                      onEdit: () => _openPlanEdit(e),
                      onDelete: () =>
                          _deleteItem('tomorrow_plan_entries', e.id),
                    ),
                  ),

                  sectionTitle(
                    "Site Photos",
                    isLocked
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPhotoScreen(
                                  projectId: projectId,
                                  selectedDate: formattedDate,
                                ),
                              ),
                            );

                            if (result == true) setState(() {});
                          },
                  ),

                  _buildPhotoStream(),
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
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Text("No data");

        return Column(children: docs.map(builder).toList());
      },
    );
  }

  /// 🔥 EDIT HELPERS (UNCHANGED PATTERN)

  void _openLabourEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLabourScreen(
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

  void _openMaterialRequestEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaterialRequestScreen(
          projectId: widget.projectId,
          selectedDate: formattedDate,
          existingData: e.data(),
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
          selectedDate: formattedDate,
          existingData: e.data(),
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
          selectedDate: formattedDate,
          existingData: e.data(),
          docId: e.id,
        ),
      ),
    );
  }

  void _openIssueEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddIssueScreen(
          projectId: widget.projectId,
          selectedDate: e['date'],
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }

  void _openPlanEdit(e) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlanScreen(
          projectId: widget.projectId,
          selectedDate: e['date'],
          existingData: e.data() as Map<String, dynamic>,
          docId: e.id,
        ),
      ),
    );
  }

  Widget _buildPhotoStream() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('site_photos')
          .where('projectId', isEqualTo: widget.projectId)
          .where('date', isEqualTo: formattedDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No photos"),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemBuilder: (context, index) {
            var e = docs[index];

            return Stack(
              children: [
                Image.network(
                  e['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

                if (!isLocked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _deleteItem('site_photos', e.id),
                      child: Container(
                        color: Colors.black54,
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
