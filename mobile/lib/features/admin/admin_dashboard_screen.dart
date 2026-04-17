import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/features/project/project_detail_screen.dart'; // 🔥 NEW

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? selectedProjectId;
  DateTime selectedDate = DateTime.now();

  List<QueryDocumentSnapshot> projects = [];

  bool isLoading = true;

  double totalCost = 0;
  double labourCost = 0;
  double materialCost = 0;

  int issuesCount = 0;
  int requestsCount = 0;

  String get formattedDate => selectedDate.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    loadProjects();
    loadDashboard();
  }

  Future<void> loadProjects() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('projects')
        .get();

    setState(() {
      projects = snapshot.docs;
    });
  }

  Future<void> loadDashboard() async {
    setState(() => isLoading = true);

    try {
      Query expenseQuery = FirebaseFirestore.instance
          .collection('expenses')
          .where('date', isEqualTo: formattedDate);

      if (selectedProjectId != null) {
        expenseQuery = expenseQuery.where(
          'projectId',
          isEqualTo: selectedProjectId,
        );
      }

      var expenseSnapshot = await expenseQuery.get();

      double tCost = 0;
      double lCost = 0;
      double mCost = 0;

      for (var doc in expenseSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        tCost += (data['totalCost'] ?? 0).toDouble();
        lCost += (data['labourCost'] ?? 0).toDouble();
        mCost += (data['materialCost'] ?? 0).toDouble();
      }

      Query issueQuery = FirebaseFirestore.instance
          .collection('issues_entries')
          .where('date', isEqualTo: formattedDate);

      if (selectedProjectId != null) {
        issueQuery = issueQuery.where(
          'projectId',
          isEqualTo: selectedProjectId,
        );
      }

      var issues = await issueQuery.get();

      Query requestQuery = FirebaseFirestore.instance
          .collection('material_requests')
          .where('date', isEqualTo: formattedDate);

      if (selectedProjectId != null) {
        requestQuery = requestQuery.where(
          'projectId',
          isEqualTo: selectedProjectId,
        );
      }

      var requests = await requestQuery.get();

      setState(() {
        totalCost = tCost;
        labourCost = lCost;
        materialCost = mCost;
        issuesCount = issues.docs.length;
        requestsCount = requests.docs.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }

    await loadProjectBreakdown();
  }

  List<Map<String, dynamic>> projectBreakdown = [];

  Future<void> loadProjectBreakdown() async {
    List<Map<String, dynamic>> result = [];

    List<QueryDocumentSnapshot> filteredProjects = selectedProjectId == null
        ? projects
        : projects.where((p) => p.id == selectedProjectId).toList();

    for (var project in filteredProjects) {
      String projectId = project.id;

      var expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('projectId', isEqualTo: projectId)
          .where('date', isEqualTo: formattedDate)
          .get();

      double totalCost = 0;
      double labourCost = 0;
      double materialCost = 0;

      for (var doc in expenseSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        totalCost += (data['totalCost'] ?? 0).toDouble();
        labourCost += (data['labourCost'] ?? 0).toDouble();
        materialCost += (data['materialCost'] ?? 0).toDouble();
      }

      var issuesSnapshot = await FirebaseFirestore.instance
          .collection('issues_entries')
          .where('projectId', isEqualTo: projectId)
          .where('date', isEqualTo: formattedDate)
          .get();

      result.add({
        "name": project['name'],
        "cost": totalCost,
        "labour": labourCost,
        "material": materialCost,
        "issues": issuesSnapshot.docs.length,
        "id": projectId,
      });
    }

    setState(() {
      projectBreakdown = result;
    });
  }

  Widget _card(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12)),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedProjectId,
            hint: const Text("All Projects"),
            items: [
              const DropdownMenuItem(value: null, child: Text("All Projects")),
              ...projects.map(
                (p) => DropdownMenuItem(value: p.id, child: Text(p['name'])),
              ),
            ],
            onChanged: (val) {
              setState(() => selectedProjectId = val);
              loadDashboard();
            },
          ),
        ),
        const SizedBox(width: 10),
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
              loadDashboard();
            }
          },
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 5),
              Text(formattedDate),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _buildFilters(),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _card(
                        "Total Cost",
                        "₹${totalCost.toStringAsFixed(0)}",
                        Icons.currency_rupee,
                      ),
                      _card(
                        "Labour",
                        "₹${labourCost.toStringAsFixed(0)}",
                        Icons.people,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      _card(
                        "Material",
                        "₹${materialCost.toStringAsFixed(0)}",
                        Icons.inventory, // 🔥 better icon
                      ),
                      _card(
                        "Issues",
                        issuesCount.toString(),
                        Icons.warning,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      _card(
                        "Requests",
                        requestsCount.toString(),
                        Icons.request_page,
                      ),
                      const Spacer(), // keeps layout clean
                    ],
                  ),

                  _buildProjectBreakdown(),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectBreakdown() {
    if (projectBreakdown.isEmpty) {
      return const Text("No project data");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          selectedProjectId == null ? "Project Breakdown" : "Project Summary",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),

        ...projectBreakdown.map((p) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListTile(
              title: Text(p['name']),
              subtitle: Text(
                "L: ₹${p['labour'].toStringAsFixed(0)} | M: ₹${p['material'].toStringAsFixed(0)} | Issues: ${p['issues']}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "₹${p['cost'].toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),

              // 🔥 DRILL-DOWN NAVIGATION
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(
                      projectId: p['id'],
                      projectName: p['name'],
                      isReadOnly: true,
                      initialDate: formattedDate,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
