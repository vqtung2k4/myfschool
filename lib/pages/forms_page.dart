import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ParentFormMainPage extends StatefulWidget {
  final String childId;
  const ParentFormMainPage({super.key, required this.childId});

  @override
  State<ParentFormMainPage> createState() => _ParentFormMainPageState();
}

class _ParentFormMainPageState extends State<ParentFormMainPage> {
  String? classId;
  bool isLoading = true;

  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = "Attendance";
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(widget.childId).get();
      if (mounted) {
        setState(() {
          classId = studentDoc.data()?['class'] ?? studentDoc.data()?['classId'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading student context: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text("Requests & Forms", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: "HISTORY", icon: Icon(Icons.history)),
                      Tab(text: "NEW FORM", icon: Icon(Icons.note_add_rounded)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            Expanded(
              child: Container(
                transform: Matrix4.translationValues(0, -20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : TabBarView(
                  children: [
                    _buildHistoryTab(),
                    _buildSubmitTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forms')
          .where('childId', isEqualTo: widget.childId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No requests sent yet."));

        docs.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['createdDate'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['createdDate'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? "Pending";
            return _buildHistoryCard(data, status);
          },
        );
      },
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text("Request Type", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTypeChip("Attendance"),
              const SizedBox(width: 10),
              _buildTypeChip("Other"),
            ],
          ),
          const SizedBox(height: 25),
          _buildTextField(_headerController, "Header", "e.g. Sick Leave"),
          const SizedBox(height: 20),
          _buildTextField(_contentController, "Content", "Write your reason...", maxLines: 5),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Form", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, String status) {
    Color statusColor = status == "Accepted" ? Colors.green : (status == "Rejected" ? Colors.red : Colors.orange);
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      elevation: 0,
      child: ExpansionTile(
        title: Text(data['header'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['type'] ?? ""),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['content'] ?? "", style: const TextStyle(color: Colors.black87)),
                if (data['teacherNote'] != null && data['teacherNote'].toString().isNotEmpty) ...[
                  const Divider(height: 30),
                  Text("Teacher Note:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900])),
                  const SizedBox(height: 5),
                  Text(data['teacherNote'], style: const TextStyle(fontStyle: FontStyle.italic)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    bool isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedType = type),
      selectedColor: Colors.orange,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_headerController.text.isEmpty || _contentController.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('forms').add({
        'childId': widget.childId,
        'classId': classId,
        'type': _selectedType,
        'header': _headerController.text.trim(),
        'content': _contentController.text.trim(),
        'status': "Pending",
        'teacherNote': "",
        'createdDate': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _isSending = false;
          _headerController.clear();
          _contentController.clear();
        });
        DefaultTabController.of(context).animateTo(0);
      }
    } catch (e) {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
