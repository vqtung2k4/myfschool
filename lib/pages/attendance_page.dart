import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String studentId;
  const AttendancePage({super.key, required this.studentId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _parseDate(String id) {
    try {
      final matchDate = RegExp(r'd(\d+)m(\d+)y(\d+)').firstMatch(id);
      if (matchDate != null) {
        int day = int.parse(matchDate.group(1)!);
        int month = int.parse(matchDate.group(2)!);
        int year = 2000 + int.parse(matchDate.group(3)!);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint("Error in parsing date: $e");
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
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
              return data.containsKey(widget.studentId);
            }).toList();

            if (records.isEmpty) {
              return const Center(child: Text("No attendance data found."));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final doc = records[index];
                final data = doc.data() as Map<String, dynamic>;
                final date = _parseDate(doc.id);
                final isPresent = data[widget.studentId] == true;

                final formattedDate = DateFormat('MMM dd, yyyy').format(date);

                return ListTile(
                  leading: Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                  title: Text(formattedDate),
                  subtitle: Text(isPresent ? "Present" : "Absent"),
                );
              },
            );
          }),
    );
  }
}
