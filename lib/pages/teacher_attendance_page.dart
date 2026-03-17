import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  Map<String, bool> attendance = {};
  bool _isLoaded = false;
  String teacherClass = "";

  String get formattedDate {
    final today = DateTime.now();
    return "${today.day}/${today.month.toString().padLeft(2, '0')}/${today.year}";
  }

  String get _dateId {
    final today = DateTime.now();
    return "d${today.day}m${today.month.toString().padLeft(2, '0')}y${(today.year % 100).toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        teacherClass = userDoc['class'] ?? "";
      }

      final attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_dateId)
          .get();

      if (attendanceDoc.exists) {
        attendance = Map<String, bool>.from(attendanceDoc.data()!);
      }
      
      setState(() {
        _isLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  Future<void> saveAttendance() async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(_dateId)
        .set(attendance);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Take Attendance - $formattedDate"),
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('class', isEqualTo: teacherClass)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs;

                if (students.isEmpty) {
                  return const Center(child: Text("No students found for this class"));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final studentId = student.id;
                          final name = student['name'];

                          attendance.putIfAbsent(studentId, () => false);

                          return CheckboxListTile(
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            activeColor: Colors.orange[800],
                            value: attendance[studentId],
                            onChanged: (value) {
                              setState(() {
                                attendance[studentId] = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saveAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Save Attendance", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
