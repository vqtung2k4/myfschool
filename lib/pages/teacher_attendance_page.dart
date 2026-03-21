import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  Map<String, bool> attendance = {};
  bool _isLoaded = false;
  String teacherClass = "";

  // --- NEW: Search Controller & Query String ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String get formattedDate {
    final today = DateTime.now();
    return "${today.day}/${today.month.toString().padLeft(2, '0')}/${today.year}";
  }

  String get _dateId {
    final today = DateTime.now();
    return "d${today.day}m${today.month.toString().padLeft(2, '0')}y${(today.year % 100).toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // --- NEW: Dispose controller to prevent memory leaks ---
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        teacherClass = userDoc['class'] ?? "";
      }

      final attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_dateId)
          .get();

      if (attendanceDoc.exists) {
        attendance = Map<String, bool>.from(attendanceDoc.data()!);
      }

      setState(() => _isLoaded = true);
    } catch (e) {
      setState(() => _isLoaded = true);
    }
  }

  Future<void> saveAttendance() async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(_dateId)
        .set(attendance);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance - $formattedDate"),
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
        children: [
          // --- NEW: Search Box UI ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search student name...",
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('class', isEqualTo: teacherClass)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // --- NEW: Local Filtering Logic ---
                final allStudents = snapshot.data!.docs;
                final filteredStudents = allStudents.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(
                    child: Text("No students match your search"),
                  );
                }

                return ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final studentId = student.id;
                    final name = student['name'];

                    attendance.putIfAbsent(studentId, () => false);

                    return CheckboxListTile(
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: Colors.orange[800],
                      value: attendance[studentId],
                      onChanged: (value) {
                        setState(() {
                          attendance[studentId] = value!;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Save Button Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Save Attendance",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}