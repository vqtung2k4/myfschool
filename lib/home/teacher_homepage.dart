import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfschool/pages/teacher_assignments_page.dart';
import 'package:myfschool/pages/teacher_attendance_page.dart';
import 'package:myfschool/pages/teacher_forms_page.dart';
import 'package:myfschool/pages/teacher_result_page.dart';

class TeacherHomepage extends StatefulWidget {
  const TeacherHomepage({super.key});

  @override
  State<TeacherHomepage> createState() => _TeacherHomepageState();
}

class _TeacherHomepageState extends State<TeacherHomepage> {
  String teacherName = "";
  String teacherClass = ""; 

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          teacherName = doc.data()?['name'] ?? "";
          teacherClass = doc.data()?['class'] ?? "";
        });
      }
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
            colors: [Colors.orange[900]!, Colors.orange[800]!, Colors.orange[400]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // Increased for status bar

            // 🔥 Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherName.isEmpty ? "Hello 👋" : "Hello, $teacherName 👋",
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          "Teacher's Dashboard",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  if (teacherClass.isNotEmpty) _buildTeacherNotificationBell(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 Main Menu Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                ),
                child: ClipRRect( // Ensures GridView doesn't draw outside rounded corners
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 40, 25, 0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _buildMenuCard(
                          icon: Icons.how_to_reg,
                          title: "Attendance",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAttendancePage())),
                        ),
                        _buildMenuCard(
                          icon: Icons.assignment_outlined,
                          title: "Assignments",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentPage())),
                        ),
                        _buildMenuCard(
                          icon: Icons.bar_chart,
                          title: "Results",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherScoreEntryPage(teacherClass: teacherClass))),
                        ),
                        _buildMenuCard(
                          icon: Icons.description_outlined,
                          title: "Forms",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherFormInboxPage(teacherClass: teacherClass))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.orange[900]),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherNotificationBell() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        Timestamp lastRead = userData?['lastReadForms'] ?? Timestamp.fromDate(DateTime(2020));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('forms')
              .where('classId', isEqualTo: teacherClass)
              .where('status', isEqualTo: 'Pending')
              .where('createdDate', isGreaterThan: lastRead)
              .snapshots(),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                  onPressed: () => _showTeacherNotificationPanel(context),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTeacherNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pending Forms", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({'lastReadForms': FieldValue.serverTimestamp()});
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Clear All", style: TextStyle(color: Colors.deepOrange)),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('forms')
                    .where('classId', isEqualTo: teacherClass)
                    .where('status', isEqualTo: 'Pending')
                    .orderBy('createdDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text("No new requests."));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.orange.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.description, color: Colors.white, size: 18)),
                          title: Text("${data['type']}: ${data['header']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Student: ${data['studentName'] ?? 'ID: ' + data['childId']}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherFormInboxPage(teacherClass: teacherClass)));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
