
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String studentId = "";

  @override
  void initState() {
    super.initState();
    loadStudentId();
  }

  Future<void> loadStudentId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      studentId = userDoc['childId'];
    });
  }

  DateTime _parseDate(String id) {
    try {
      final matchDate = RegExp(r'd(\d+)m(\d+)y(\d+)').firstMatch(id);
      if (matchDate != null) {
        int day = int.parse(matchDate.group(1)!);
        int month = int.parse(matchDate.group(2)!);
        int year = 2000 + int.parse(matchDate.group(3)!);
        return DateTime(year,month,day);
      }
    } catch (e) {
      debugPrint("Error in parsing date: $e");
    }
    return DateTime.now();
  }

  Widget build(BuildContext context) {
    if (studentId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(),),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
          .collection('attendance')
          .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<QueryDocumentSnapshot> records = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey(studentId);
            }).toList();

            if (records.isEmpty) {
              return const Center(child: Text("No attendance data"),);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final doc = records[index];
                final data = doc.data() as Map<String, dynamic>;
                final date = _parseDate(doc.id);
                final isPresent = data[studentId] == true;

                final formattedDate = DateFormat('MMM dd, yyyy').format(date);

                return ListTile(
                  leading: Icon(
                    isPresent == true ? Icons.check_circle : Icons.cancel,
                    color: isPresent == true ? Colors.green : Colors.red,
                  ),

                  title: Text(formattedDate),
                  subtitle: Text(isPresent == true ? "Present" : "Absent"),
                );
              },
            );
          }),
    );
  }
}
