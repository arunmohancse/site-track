import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();

  String? selectedSupervisorId;

  List<Map<String, dynamic>> supervisors = [];

  @override
  void initState() {
    super.initState();
    fetchSupervisors();
  }

  Future<void> fetchSupervisors() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'SUPERVISOR')
        .get();

    setState(() {
      supervisors = snapshot.docs
          .map((doc) => {"uid": doc['uid'], "name": doc['name']})
          .toList();
    });
  }

  Future<void> createProject() async {
    await FirebaseFirestore.instance.collection('projects').add({
      "name": nameController.text,
      "location": locationController.text,
      "supervisorId": selectedSupervisorId,
      "createdAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Project created")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Project")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Project Name"),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              hint: const Text("Select Supervisor"),
              value: selectedSupervisorId,
              items: supervisors.map((sup) {
                return DropdownMenuItem<String>(
                  value: sup['uid'],
                  child: Text(sup['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSupervisorId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createProject,
              child: const Text("Create Project"),
            ),
          ],
        ),
      ),
    );
  }
}
