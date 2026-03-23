import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherScoreEntryPage extends StatefulWidget {
  final String teacherClass; // Pass "K1.1" from TeacherHomepage
  const TeacherScoreEntryPage({super.key, required this.teacherClass});

  @override
  State<TeacherScoreEntryPage> createState() => _TeacherScoreEntryPageState();
}

class _TeacherScoreEntryPageState extends State<TeacherScoreEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _scoreController = TextEditingController();

  String? _selectedStudentId;
  String? _selectedSubject;
  String? _selectedTestType;
  bool _isSaving = false;

  // The 5 specific test types you requested
  final Map<String, String> _testTypes = {
    'oral': 'Oral Examination',
    'test15min': '15 Minutes Test',
    'test45min': '45 Minutes Test',
    'midTest': 'Mid-term Test',
    'finalTest': 'Final Test',
  };

  Future<void> _saveScore() async {
    if (!_formKey.currentState!.validate() ||
        _selectedStudentId == null ||
        _selectedSubject == null ||
        _selectedTestType == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Use set with merge: true to avoid overwriting other subjects or other test types
      await FirebaseFirestore.instance
          .collection('results')
          .doc(_selectedStudentId)
          .set({
        'classId': widget.teacherClass,
        'subjects': {
          _selectedSubject: {
            _selectedTestType: double.tryParse(_scoreController.text) ?? 0.0,
          }
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Score updated successfully!")),
        );
        _scoreController.clear();
      }
    } catch (e) {
      debugPrint("Error saving score: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Student Scores"),
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Select Student from Teacher's Class
              _buildLabel("1. Select Student"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('class', isEqualTo: widget.teacherClass)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  var students = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    hint: const Text("Choose a student"),
                    items: students.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s['name']))).toList(),
                    onChanged: (val) => setState(() => _selectedStudentId = val),
                    decoration: _inputStyle(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2. Select Subject (Filtered by active: true)
              _buildLabel("2. Select Subject"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subjects')
                    .where('active', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  var subjects = snapshot.data!.docs.map((doc) => doc.id).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    hint: const Text("Choose subject"),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedSubject = val),
                    decoration: _inputStyle(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 3. Select Test Type
              _buildLabel("3. Test Category"),
              DropdownButtonFormField<String>(
                value: _selectedTestType,
                hint: const Text("Select test type"),
                items: _testTypes.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value))).toList(),
                onChanged: (val) => setState(() => _selectedTestType = val),
                decoration: _inputStyle(),
              ),

              const SizedBox(height: 20),

              // 4. Input Score
              _buildLabel("4. Score (0 - 10)"),
              TextFormField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputStyle().copyWith(hintText: "Enter score..."),
                validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Score", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  );

  InputDecoration _inputStyle() => InputDecoration(
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}
