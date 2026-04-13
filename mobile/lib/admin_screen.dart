import 'package:flutter/material.dart';
import 'package:mobile/create_project_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
            );
          },
          child: const Text("Create Project"),
        ),
      ),
    );
  }
}
