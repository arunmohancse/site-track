import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPhotoScreen extends StatefulWidget {
  final String projectId;
  final String selectedDate;

  const AddPhotoScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
  });

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  final picker = ImagePicker();
  bool isUploading = false;

  Future<void> pickAndUpload() async {
    try {
      // 🔹 Pick image
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      // 🔥 CHECK LIMIT (max 5 photos)
      var existing = await FirebaseFirestore.instance
          .collection('site_photos')
          .where('projectId', isEqualTo: widget.projectId)
          .where('date', isEqualTo: widget.selectedDate)
          .get();

      if (existing.docs.length >= 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Maximum 5 photos allowed")),
        );
        return;
      }

      // 🔹 Start uploading
      setState(() => isUploading = true);

      File file = File(picked.path);

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      var ref = FirebaseStorage.instance
          .ref()
          .child("site_photos/${widget.projectId}/${widget.selectedDate}/$fileName.jpg");

      // 🔹 Upload
      await ref.putFile(file);

      // 🔹 Get URL
      String url = await ref.getDownloadURL();

      // 🔹 Save to Firestore
      await FirebaseFirestore.instance.collection('site_photos').add({
        "projectId": widget.projectId,
        "date": widget.selectedDate,
        "imageUrl": url,
        "createdAt": Timestamp.now(),
      });

      // 🔹 Stop loader
      if (mounted) {
        setState(() => isUploading = false);

        // ✅ Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo uploaded successfully")),
        );

        // ✅ Go back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Photo")),
      body: Center(
        child: isUploading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          onPressed: pickAndUpload,
          icon: const Icon(Icons.photo),
          label: const Text("Select Photo"),
        ),
      ),
    );
  }
}