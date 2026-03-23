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

  // --- CALCULATION LOGIC ---

  double calculateSubjectAverage(Map<String, dynamic> scores) {
    double totalPoints = 0;
    double totalWeight = 0;

    // Weights for GPA calculation
    Map<String, int> weights = {
      'oral': 1,
      'test15min': 1,
      'test45min': 2,
      'midTest': 3,
      'finalTest': 3,
    };

    scores.forEach((key, value) {
      if (weights.containsKey(key) && value != null) {
        double score = double.tryParse(value.toString()) ?? 0.0;
        totalPoints += (score * weights[key]!);
        totalWeight += weights[key]!;
      }
    });

    return totalWeight == 0 ? 0.0 : totalPoints / totalWeight;
  }

  double calculateOverallGPA(Map<String, dynamic> allSubjects) {
    double gpaSum = 0;
    int subjectCount = 0;

    allSubjects.forEach((subjectName, scores) {
      if (scores is Map<String, dynamic>) {
        double avg = calculateSubjectAverage(scores);
        if (avg > 0) {
          gpaSum += avg;
          subjectCount++;
        }
      }
    });

    return subjectCount == 0 ? 0.0 : gpaSum / subjectCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: studentId.isEmpty
            ? null
            : FirebaseFirestore.instance.collection('results').doc(studentId).snapshots(),
        builder: (context, snapshot) {
          double overallGPA = 0.0;
          Map<String, dynamic> subjectsMap = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            subjectsMap = data['subjects'] as Map<String, dynamic>? ?? {};
            overallGPA = calculateOverallGPA(subjectsMap);
          }

          return Column(
            children: [
              // Header with Overall GPA
              Container(
                height: 240, // Increased height to prevent overflow
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              "Academic Report",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer for balance
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Overall Average",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        overallGPA == 0.0 ? "-.-" : overallGPA.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Results List
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
                      : _buildContent(subjectsMap),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> subjectsMap) {
    if (studentId.isEmpty) {
      return const Center(child: Text("No student associated with this account."));
    }

    if (subjectsMap.isEmpty) {
      return const Center(child: Text("No scores recorded yet."));
    }

    final subjectNames = subjectsMap.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: subjectNames.length,
      itemBuilder: (context, index) {
        final name = subjectNames[index];
        final scores = subjectsMap[name] as Map<String, dynamic>;
        final subjectAvg = calculateSubjectAverage(scores);

        return SubjectResultCard(
          subjectName: name,
          scores: scores,
          average: subjectAvg,
        );
      },
    );
  }
}

class SubjectResultCard extends StatelessWidget {
  final String subjectName;
  final Map<String, dynamic> scores;
  final double average;

  const SubjectResultCard({
    super.key,
    required this.subjectName,
    required this.scores,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.orange, size: 20),
        ),
        title: Text(
          subjectName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "Average: ${average.toStringAsFixed(2)}",
          style: TextStyle(
            color: Colors.orange.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          const Divider(height: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            score?.toString() ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
