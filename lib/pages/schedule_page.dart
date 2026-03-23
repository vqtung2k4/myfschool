import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  final String studentId;
  const SchedulePage({super.key, required this.studentId});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Map<String, dynamic>? schedule;
  bool isLoading = true;
  DateTime currentViewDate = DateTime.now();
  final List<String> weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  List<String> activeSubjects = [];

  @override
  void initState() {
    super.initState();
    currentViewDate = _normalize(DateTime.now());
    loadSchedule();
  }

  DateTime _getStartOfWeek(DateTime date) => DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> loadSchedule() async {
    setState(() => isLoading = true);
    try {
      final subjectsSnap = await FirebaseFirestore.instance.collection('subjects').where('active', isEqualTo: true).get();
      activeSubjects = subjectsSnap.docs.map((doc) => doc.id).toList();

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(widget.studentId).get();
      final classId = studentDoc.data()?['class'] ?? studentDoc.data()?['classId'];

      final targetMonday = _getStartOfWeek(currentViewDate);
      final weeksQuery = await FirebaseFirestore.instance.collection('schedule').doc(classId.toString()).collection('weeks').get();

      DocumentSnapshot? targetWeek;
      for (var doc in weeksQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startDateTimestamp = data['startDate'] as Timestamp?;
        if (startDateTimestamp != null) {
          final start = _normalize(startDateTimestamp.toDate());
          if (start.isAtSameMomentAs(targetMonday)) {
            targetWeek = doc;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          schedule = targetWeek?.data() as Map<String, dynamic>?;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading schedule: $e");
      if (mounted) setState(() => isLoading = false);
    }
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
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange])),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                        TextButton.icon(
                          onPressed: () { setState(() => currentViewDate = _normalize(DateTime.now())); loadSchedule(); },
                          icon: const Icon(Icons.today, color: Colors.white, size: 18),
                          label: const Text("Today", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () { setState(() => currentViewDate = currentViewDate.subtract(const Duration(days: 7))); loadSchedule(); }),
                      Column(
                        children: [
                          const Text("Weekly Schedule", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("${DateFormat('dd/MM/yyyy').format(weekStart)} - ${DateFormat('dd/MM/yyyy').format(weekEnd)}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20), onPressed: () { setState(() => currentViewDate = currentViewDate.add(const Duration(days: 7))); loadSchedule(); }),
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
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : (schedule == null) ? _buildNoDataState() : TabBarView(children: weekDays.map((day) => _buildDayContent(day)).toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() => const Center(child: Text("No schedule found for this week", style: TextStyle(color: Colors.grey)));

  Widget _buildDayContent(String day) {
    if (schedule == null) return const SizedBox();
    final rawSubjects = (schedule![day.toLowerCase()] ?? []) as List;
    final filteredSubjects = rawSubjects.where((s) => activeSubjects.contains(s.toString())).toList();

    if (filteredSubjects.isEmpty) return Center(child: Text("No active classes scheduled for ${day.substring(0, 1).toUpperCase()}${day.substring(1)}", style: const TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredSubjects.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_book_rounded, color: Colors.orange)),
          title: Text(filteredSubjects[index].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Duration: 45 mins"),
        ),
      ),
    );
  }
}
