import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../project/project_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Projects")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .where('supervisorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var projects = snapshot.data!.docs;

          if (projects.isEmpty) {
            return const Center(child: Text("No projects assigned"));
          }

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              var project = projects[index];

              return ListTile(
                title: Text(project['name']),
                subtitle: Text(project['location']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(
                        projectId: project.id,
                        projectName: project['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
