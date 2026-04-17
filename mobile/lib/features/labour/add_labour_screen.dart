import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddLabourScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? existingData;
  final String? docId;

  // ✅ ADD THIS (fix for date consistency)
  final String selectedDate;

  const AddLabourScreen({
    super.key,
    required this.projectId,
    required this.selectedDate,
    this.existingData,
    this.docId,
  });

  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  final skilledController = TextEditingController();
  final helperController = TextEditingController();
  final machineController = TextEditingController();
  final amountController = TextEditingController();
  final remarkController = TextEditingController();

  List<Map<String, dynamic>> workTypes = [];

  String? selectedType;
  String? selectedDescription;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final data = widget.existingData!;

      selectedType = data['typeOfWork'];
      selectedDescription = data['description'];

      skilledController.text = data['skilledCount'].toString();
      helperController.text = data['helperCount'].toString();
      machineController.text = data['machineHours'].toString();
      amountController.text = data['totalAmount'].toString();
      remarkController.text = data['remark'] ?? "";
    }

    fetchWorkTypes();
  }

  Future<void> fetchWorkTypes() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('work_types')
        .get();

    setState(() {
      workTypes = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> saveLabour() async {
    final data = {
      "projectId": widget.projectId,

      // ✅ FIXED (IMPORTANT)
      "date": widget.selectedDate,

      "typeOfWork": selectedType,
      "description": selectedDescription,
      "skilledCount": int.tryParse(skilledController.text) ?? 0,
      "helperCount": int.tryParse(helperController.text) ?? 0,
      "machineHours": int.tryParse(machineController.text) ?? 0,
      "totalAmount": int.tryParse(amountController.text) ?? 0,
      "remark": remarkController.text,
      "createdAt": Timestamp.now(),
    };

    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('labour_entries')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('labour_entries').add(data);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Labour")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 TYPE
            DropdownButtonFormField<String>(
              hint: const Text("Select Type of Work"),
              value: selectedType,
              items: workTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['name'],
                  child: Text(type['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                  selectedDescription = null;
                });
              },
            ),

            const SizedBox(height: 10),

            /// 🔹 DESCRIPTION (dependent)
            DropdownButtonFormField<String>(
              hint: const Text("Select Description"),
              value: selectedDescription,
              items: selectedType == null
                  ? []
                  : workTypes
                        .firstWhere(
                          (t) => t['name'] == selectedType,
                        )['descriptions']
                        .map<DropdownMenuItem<String>>((desc) {
                          return DropdownMenuItem<String>(
                            value: desc,
                            child: Text(desc),
                          );
                        })
                        .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDescription = value;
                });
              },
            ),

            const SizedBox(height: 10),

            TextField(
              controller: skilledController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Skilled Count"),
            ),

            TextField(
              controller: helperController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Helper Count"),
            ),

            TextField(
              controller: machineController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Machine Hours"),
            ),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Amount"),
            ),

            TextField(
              controller: remarkController,
              decoration: const InputDecoration(labelText: "Remark"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setState(() => isSaving = true);

                      try {
                        await saveLabour();
                      } catch (e) {
                        setState(() => isSaving = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
