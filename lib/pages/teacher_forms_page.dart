import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherFormInboxPage extends StatefulWidget {
  final String teacherClass; // Pass "K1.1"
  const TeacherFormInboxPage({super.key, required this.teacherClass});

  @override
  State<TeacherFormInboxPage> createState() => _TeacherFormInboxPageState();
}

class _TeacherFormInboxPageState extends State<TeacherFormInboxPage> {
  final TextEditingController _noteController = TextEditingController();

  // Function to Update Status
  Future<void> _updateFormStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('forms').doc(docId).update({
      'status': newStatus,
      'teacherNote': _noteController.text.trim(),
    });
    _noteController.clear();
    if (mounted) Navigator.pop(context); // Close dialog
  }

  // Dialog to Add Teacher Note before accepting/rejecting
  void _showActionDialog(String docId, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$action Form"),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(hintText: "Add a note (optional)..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => _updateFormStatus(docId, action),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == "Accepted" ? Colors.green : Colors.red,
            ),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Inbox"), 
        backgroundColor: Colors.orange[900], 
        foregroundColor: Colors.white
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('forms')
            .where('classId', isEqualTo: widget.teacherClass)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No forms submitted yet."));

          // Sort locally to avoid "failed-precondition" index requirement error
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = aData['createdDate'] as Timestamp?;
            final bDate = bData['createdDate'] as Timestamp?;
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate); // Newest first
          });

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final status = data['status'];

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(status),
                          Text(data['type'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(data['header'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(data['content'] ?? ""),
                      const Divider(height: 25),

                      if (status == "Pending")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _showActionDialog(docId, "Rejected"),
                              child: const Text("Reject", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _showActionDialog(docId, "Accepted"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Accept", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        )
                      else
                        Text("Note: ${data['teacherNote']}", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == "Accepted") color = Colors.green;
    if (status == "Rejected") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
