import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfschool/pages/assignments_page.dart';
import 'package:myfschool/pages/forms_page.dart';
import 'package:myfschool/pages/result_page.dart';

import '../pages/attendance_page.dart';
import '../pages/schedule_page.dart';

class ParentHomepage extends StatefulWidget {
  final String selectedChildId;
  final VoidCallback onBackToSelection;

  const ParentHomepage({
    super.key,
    required this.selectedChildId,
    required this.onBackToSelection,
  });

  @override
  State<ParentHomepage> createState() => _ParentHomepageState();
}

class _ParentHomepageState extends State<ParentHomepage> {
  String parentName = "";
  String studentName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Fetch Parent Data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Fetch Selected Child Data
      final studentDoc = await FirebaseFirestore.instance
          .collection("students")
          .doc(widget.selectedChildId)
          .get();

      if (mounted) {
        setState(() {
          parentName = userDoc.data()?['name'] ?? "Parent";
          studentName = studentDoc.data()?['name'] ?? "Unknown Student";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading parent/student data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.orange[900]!,
              Colors.orange[800]!,
              Colors.orange[400]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 🔥 Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBackToSelection,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentName.isEmpty ? "Hello 👋" : "Hello, $parentName 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLoading 
                              ? "Loading child..." 
                              : "$studentName's Dashboard",
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white,),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 White Container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 25,
                    children: [
                      _buildMenuCard(
                        icon: Icons.check_circle_outline,
                        title: "Attendance",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendancePage(studentId: widget.selectedChildId),
                            ),
                          );
                        },
                      ),

                      _buildMenuCard(
                        icon: Icons.assignment_outlined,
                        title: "Assignment",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentPage(studentId: widget.selectedChildId),
                            ),
                          );
                        },
                      ),

                      _buildMenuCard(
                        icon: Icons.assignment_outlined,
                        title: "Forms",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentFormMainPage(childId: widget.selectedChildId),
                            ),
                          );
                        },
                      ),

                      _buildMenuCard(
                        icon: Icons.poll_outlined,
                        title: "Result",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultPage(studentId: widget.selectedChildId),
                            ),
                          );
                        },
                      ),

                      _buildMenuCard(
                        icon: Icons.calendar_today_outlined,
                        title: "Schedule",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SchedulePage(studentId: widget.selectedChildId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.orange[900]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
