import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Map<String, dynamic> schedule = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final studentId = userDoc['childId'];
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .get();

    final classId = studentDoc['class'];
    final scheduleDoc = await FirebaseFirestore.instance
        .collection('schedule')
        .doc(classId)
        .get();

    setState(() {
      schedule = scheduleDoc.data() ?? {};
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (schedule.isEmpty) {
      return const Scaffold(body: Center(child: Text("No schedule found")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Schedule")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: schedule.keys.map((day) {
          final subjects = schedule[day] as List;

          return Card(
            margin: const EdgeInsets.only(bottom: 15),

            child: Padding(
              padding: const EdgeInsetsGeometry.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsetsGeometry.symmetric(vertical: 4),
                      child: Text("• $subject"),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
