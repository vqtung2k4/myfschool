import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfschool/home/parent_homepage.dart';
import 'package:myfschool/home/teacher_homepage.dart';
import 'package:myfschool/pages/child_selection.dart';

class RoleChecker extends StatefulWidget {
  const RoleChecker({super.key});

  @override
  State<RoleChecker> createState() => _RoleCheckerState();
}

class _RoleCheckerState extends State<RoleChecker> {
  String? selectedChildId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not authenticated. Please log in again.")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        // If the document doesn't exist, the user exists in Auth but not in Firestore users collection
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, size: 80, color: Colors.orange),
                    const SizedBox(height: 20),
                    const Text(
                      "User profile not found in database.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "UID: ${user.uid}\nPhone: ${user.phoneNumber}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900]),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text("Log Out & Try Another Account", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'];

        if (role == 'parent') {
          if (selectedChildId != null) {
            return ParentHomepage(
              selectedChildId: selectedChildId!,
              onBackToSelection: () {
                setState(() {
                  selectedChildId = null;
                });
              },
            );
          }
          return ChildSelectionPage(
            onChildSelected: (id) {
              setState(() {
                selectedChildId = id;
              });
            },
          );
        }
        if (role == 'teacher') {
          return const TeacherHomepage();
        }

        return const Scaffold(
          body: Center(child: Text("Unknown user role assigned.")),
        );
      },
    );
  }
}
