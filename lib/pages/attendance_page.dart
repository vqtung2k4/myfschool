
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      body: StreamBuilder(stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('student', isEqualTo: studentId)
          .snapshots(), 
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data!.docs;
            
            if (records.isEmpty) {
              return const Center(child: Text("No attendance data"),);
            }
            
            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final data = records[index];
                final date = data['date'];
                final status = data['status'];
                
                return ListTile(
                  leading: Icon(
                    status == true ? Icons.check_circle : Icons.cancel,
                    color: status == true ? Colors.green : Colors.red,
                  ),
                  
                  title: Text(date.toDate().toString()),
                  subtitle: Text(status == true ? "Present" : "Absent"),
                );
              },
            );
          }),
    );
  }
}
