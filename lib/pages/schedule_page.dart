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
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    setState(() => isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final studentId = userDoc['childId'];

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
      final classId = studentDoc['class'] ?? studentDoc['classId'];

      final weekQuery = await FirebaseFirestore.instance
          .collection('schedule')
          .doc(classId)
          .collection('weeks')
          .where('startDate', isLessThanOrEqualTo: currentViewDate)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (weekQuery.docs.isNotEmpty) {
        final data = weekQuery.docs.first.data();
        DateTime endDate = (data['endDate'] as Timestamp).toDate();

        if (currentViewDate.isBefore(endDate.add(const Duration(days: 1)))) {
          setState(() {
            schedule = data;
            isLoading = false;
          });
        } else {
          setState(() { schedule = null; isLoading = false; });
        }
      } else {
        setState(() { schedule = null; isLoading = false; });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: weekDays.length,
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
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => currentViewDate = DateTime.now());
                        loadSchedule();
                      },
                      icon: const Icon(Icons.today, color: Colors.white, size: 18),
                      label: const Text("Today", style: TextStyle(color: Colors.white)),
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
                          if (schedule != null)
                            Text(
                              "${_formatDate(schedule!['startDate'])} - ${_formatDate(schedule!['endDate'])}",
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
          const Text("No schedule listed for this week", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDayContent(String day) {
    final List subjects = schedule![day] ?? [];

    if (subjects.isEmpty) {
      return const Center(child: Text("No classes scheduled for this day"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
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