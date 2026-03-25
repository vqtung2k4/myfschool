import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  String classId = "";
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

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final studentDoc = await FirebaseFirestore.instance.collection("students").doc(widget.selectedChildId).get();

      if (mounted) {
        setState(() {
          parentName = userDoc.data()?['name'] ?? "Parent";
          studentName = studentDoc.data()?['name'] ?? "Unknown Student";
          classId = studentDoc.data()?['class'] ?? ""; // 🔥 Get classId for notifications
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
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
            colors: [Colors.orange[900]!, Colors.orange[800]!, Colors.orange[400]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isLoading ? "Loading..." : "$studentName's Dashboard",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  // 🔔 THE NOTIFICATION BELL
                  if (!isLoading)
                    _buildNotificationBell(),

                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 25,
                    children: [
                      _buildMenuCard(icon: Icons.check_circle_outline, title: "Attendance", onTap: () {}),
                      _buildMenuCard(icon: Icons.assignment_outlined, title: "Assignment", onTap: () {}),
                      _buildMenuCard(icon: Icons.description_outlined, title: "Forms", onTap: () {}),
                      _buildMenuCard(icon: Icons.poll_outlined, title: "Result", onTap: () {}),
                      _buildMenuCard(icon: Icons.calendar_today_outlined, title: "Schedule", onTap: () {}),
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

  // --- 🔔 Notification Logic ---
  Widget _buildNotificationBell() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        // 1. Get the last read timestamp
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        Timestamp lastRead = userData?['lastReadNotifications'] ?? Timestamp.fromDate(DateTime(2020));

        // 2. Listen to Assignments newer than lastRead
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .where('classId', isEqualTo: classId)
              .where('createdAt', isGreaterThan: lastRead)
              .snapshots(),
          builder: (context, assignmentSnap) {

            // 3. Listen to Form Status Updates newer than lastRead
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forms')
                  .where('childId', isEqualTo: widget.selectedChildId)
                  .where('status', whereIn: ['Accepted', 'Rejected'])
              // Note: Ensure your form docs have a 'createdDate' or 'updatedDate' field
                  .where('createdDate', isGreaterThan: lastRead)
                  .snapshots(),
              builder: (context, formSnap) {

                // Calculate total unread items
                int assignmentCount = assignmentSnap.data?.docs.length ?? 0;
                int formCount = formSnap.data?.docs.length ?? 0;
                int totalCount = assignmentCount + formCount;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                      onPressed: () => _showNotificationPanel(context),
                    ),
                    if (totalCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            totalCount > 9 ? '9+' : '$totalCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Updates", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'lastReadNotifications': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Clear All", style: TextStyle(color: Colors.deepOrange)),
                ),
              ],
            ),
            const Divider(),

            Expanded(
              child: StreamBuilder<List<QueryDocumentSnapshot>>(
                stream: _getCombinedNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading updates: ${snapshot.error}"));
                  }

                  final allDocs = snapshot.data ?? [];
                  if (allDocs.isEmpty) {
                    return const Center(child: Text("No recent updates found."));
                  }

                  return ListView.builder(
                    itemCount: allDocs.length,
                    itemBuilder: (context, index) {
                      final doc = allDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      bool isAssignment = data.containsKey('subject');
                      return _buildNotificationItem(isAssignment, data);
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

  Stream<List<QueryDocumentSnapshot>> _getCombinedNotifications() {
    // Note: If you haven't created the composite index yet, this query might fail.
    // I recommend creating the index using the link in your console.
    var assignmentStream = FirebaseFirestore.instance
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .snapshots();

    var formStream = FirebaseFirestore.instance
        .collection('forms')
        .where('childId', isEqualTo: widget.selectedChildId)
        .where('status', whereIn: ['Accepted', 'Rejected'])
        .snapshots();

    return FirebaseFirestore.instance
        .collection('assignments')
        .snapshots() // Dummy trigger
        .asyncMap((_) async {
      final aSnap = await assignmentStream.first;
      final fSnap = await formStream.first;

      List<QueryDocumentSnapshot> combined = [...aSnap.docs, ...fSnap.docs];

      combined.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        Timestamp tA = dataA['createdAt'] ?? dataA['createdDate'] ?? Timestamp.now();
        Timestamp tB = dataB['createdAt'] ?? dataB['createdDate'] ?? Timestamp.now();
        return tB.compareTo(tA);
      });

      return combined;
    });
  }

  Widget _buildNotificationItem(bool isAssignment, Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      color: isAssignment ? Colors.orange.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAssignment ? Colors.orange : (data['status'] == "Accepted" ? Colors.green : Colors.red),
          child: Icon(
            isAssignment ? Icons.assignment : (data['status'] == "Accepted" ? Icons.check : Icons.close),
            color: Colors.white, size: 18,
          ),
        ),
        title: Text(
          isAssignment
              ? "New ${data['subject']} Assignment"
              : "Request ${data['status']}: ${data['header']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          isAssignment ? data['title'] ?? "" : "Note: ${data['teacherNote'] ?? 'No feedback'}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.orange[900]),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
