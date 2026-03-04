import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherHomepage extends StatefulWidget {
  const TeacherHomepage({super.key});

  @override
  State<TeacherHomepage> createState() => _TeacherHomepageState();
}

class _TeacherHomepageState extends State<TeacherHomepage> {
  String teacherName = "";

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        teacherName = doc['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: teacherName.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $teacherName 👋",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// Attendance Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to attendance page
                      },
                      child: const Text("Mark Attendance"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
