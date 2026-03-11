import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfschool/home/parent_homepage.dart';
import 'package:myfschool/home/teacher_homepage.dart';

class RoleChecker extends StatelessWidget {
  const RoleChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data!['role'];

        if (role == 'parent') {
          return const ParentHomepage();
        }
        if (role == 'teacher') {
          return const TeacherHomepage();
        }

        return const Scaffold(body: Center(child: Text("Unknown role")));
      },
    );
  }
}
