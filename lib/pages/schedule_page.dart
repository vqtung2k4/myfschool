import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Map<String, dynamic>? schedule;
  bool isLoading = true;
  DateTime currentViewDate = DateTime.now();

  final List<String> weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

  @override
  void initState() {
    super.initState();
    // Normalize today's date
    currentViewDate = _normalize(DateTime.now());
    loadSchedule();
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Returns the Monday of the week containing the given date
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> loadSchedule() async {
    setState(() => isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Get Student ID
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final studentId = userDoc.data()?['childId'];

      if (studentId == null) throw "No childId found for user";

      // 2. Get Class ID from Student document
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
      final studentData = studentDoc.data();
      final classId = studentData?['class'] ?? studentData?['classId'] ?? studentData?['className'];

      if (classId == null) throw "No class found for student $studentId";

      // 3. Find the Monday of the week we are currently viewing
      final targetMonday = _getStartOfWeek(currentViewDate);
      debugPrint("DEBUG: Searching for schedule for Class: $classId, Week starting: $targetMonday");

      // 4. Fetch all weeks for this class
      final weeksQuery = await FirebaseFirestore.instance
          .collection('schedule')
          .doc(classId.toString())
          .collection('weeks')
          .get();

      DocumentSnapshot? targetWeek;
      for (var doc in weeksQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('startDate')) continue;

        final start = _normalize((data['startDate'] as Timestamp).toDate());
        
        // If the Monday of this document matches the Monday of our view date, it's the right week
        if (start.isAtSameMomentAs(targetMonday)) {
          targetWeek = doc;
          debugPrint("DEBUG: Found matching week: ${doc.id}");
          break;
        }
      }

      setState(() {
        schedule = targetWeek?.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Schedule Load Error: $e");
      setState(() {
        schedule = null;
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getStartOfWeek(currentViewDate);
    final weekEnd = weekStart.add(const Duration(days: 4));

    return DefaultTabController(
      length: weekDays.length,
      initialIndex: (currentViewDate.weekday > 5) ? 0 : currentViewDate.weekday - 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                        TextButton.icon(
                          onPressed: () {
                            setState(() => currentViewDate = _normalize(DateTime.now()));
                            loadSchedule();
                          },
                          icon: const Icon(Icons.today, color: Colors.white, size: 18),
                          label: const Text("Today", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() => currentViewDate = currentViewDate.subtract(const Duration(days: 7)));
                          loadSchedule();
                        },
                      ),
                      Column(
                        children: [
                          const Text("Weekly Schedule",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            "${_formatDate(weekStart)} - ${_formatDate(weekEnd)}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() => currentViewDate = currentViewDate.add(const Duration(days: 7)));
                          loadSchedule();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: weekDays.map((day) => Tab(text: day.substring(0, 3).toUpperCase())).toList(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                transform: Matrix4.translationValues(0, -20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : (schedule == null)
                    ? _buildNoDataState()
                    : TabBarView(
                  children: weekDays.map((day) => _buildDayContent(day)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No schedule found for this week", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDayContent(String day) {
    if (schedule == null) return const SizedBox();
    
    final List subjects = (schedule![day.toLowerCase()] ?? schedule![day] ?? []) as List;

    if (subjects.isEmpty) {
      return Center(
        child: Text("No classes scheduled for ${day.substring(0, 1).toUpperCase()}${day.substring(1)}", 
          style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.orange),
            ),
            title: Text(
              subjects[index].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Duration: 45 mins"),
          ),
        );
      },
    );
  }
}
