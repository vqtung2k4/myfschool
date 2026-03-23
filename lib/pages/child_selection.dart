import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfschool/home/parent_homepage.dart';

class ChildSelectionPage extends StatefulWidget {
  const ChildSelectionPage({super.key});

  @override
  State<ChildSelectionPage> createState() => _ChildSelectionPageState();
}

class _ChildSelectionPageState extends State<ChildSelectionPage> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
              ),
              const Text("Select Your Child",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Choose a profile to view reports",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),

              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                    if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Profile not found", style: TextStyle(color: Colors.white)));

                    // Get the list of IDs
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    List<dynamic> childrenIds = data?['childId'] is List ? data!['childId'] : [];

                    if (childrenIds.isEmpty) {
                      return const Center(child: Text("No children linked to this account", style: TextStyle(color: Colors.white)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      itemCount: childrenIds.length,
                      itemBuilder: (context, index) {
                        return _buildChildCard(childrenIds[index].toString());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(String childId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('students').doc(childId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final name = snapshot.data?['name'] ?? "Unknown";
        final className = snapshot.data?['class'] ?? snapshot.data?['classId'] ?? "";

        return GestureDetector(
          onTap: () {
            // Navigate to Parent Homepage and PASS the selected child data
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ParentHomepage(selectedChildId: childId))
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.orange[100], child: const Icon(Icons.person, color: Colors.orange)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Class: $className", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
