import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String studentId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (mounted) {
        setState(() {
          studentId = userDoc.data()?['childId'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading student data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Center(
                    child: Text(
                      "Learning Results",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : _buildResultsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (studentId.isEmpty) {
      return const Center(child: Text("No student associated with this account."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .doc(studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No results available yet."));
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final subjectsMap = data['subjects'] as Map<String, dynamic>? ?? {};

        if (subjectsMap.isEmpty) {
          return const Center(child: Text("No subject scores found."));
        }

        final subjectNames = subjectsMap.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          itemCount: subjectNames.length,
          itemBuilder: (context, index) {
            final name = subjectNames[index];
            final scores = subjectsMap[name] as Map<String, dynamic>? ?? {};
            
            return SubjectResultCard(
              subjectName: name,
              scores: scores,
            );
          },
        );
      },
    );
  }
}

class SubjectResultCard extends StatelessWidget {
  final String subjectName;
  final Map<String, dynamic> scores;

  const SubjectResultCard({super.key, required this.subjectName, required this.scores});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: const Icon(Icons.assessment, color: Colors.orange),
        children: [
          _buildScoreRow("Oral Examination", scores['oral']),
          _buildScoreRow("15 Minutes Test", scores['test15min']),
          _buildScoreRow("45 Minutes Test", scores['test45min']),
          _buildScoreRow("Mid-term Test", scores['midTest']),
          _buildScoreRow("Final Test", scores['finalTest']),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, dynamic score) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            score?.toString() ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
          ),
        ],
      ),
    );
  }
}
