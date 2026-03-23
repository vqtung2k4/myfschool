import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateAssignmentPage extends StatefulWidget {
  const CreateAssignmentPage({super.key});

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedClass;
  String? _selectedSubject;
  DateTime? _selectedDueDate;
  bool _isSaving = false;
  bool _isLoadingClass = true;

  final List<String> _subjects = [
    "Japanese",
    "Mathematics",
    "Science",
    "English",
    "Art",
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherClass();
  }

  Future<void> _loadTeacherClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _selectedClass = doc.data()?['class'];
            _isLoadingClass = false;
          });
        } else {
          setState(() => _isLoadingClass = false);
        }
      } catch (e) {
        setState(() => _isLoadingClass = false);
      }
    } else {
      setState(() => _isLoadingClass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Assignment"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingClass
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Class",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      hint: const Text("No class assigned"),
                      decoration: _dropdownStyle(),
                      // Only provide the teacher's assigned class as an option
                      items: _selectedClass == null
                          ? []
                          : [
                              DropdownMenuItem(
                                value: _selectedClass,
                                child: Text(_selectedClass!),
                              ),
                            ],
                      onChanged: null,
                      // Keep it disabled as they only have one class
                      validator: (val) => val == null
                          ? "No class assigned to your profile"
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // --- 2. Subject Dropdown ---
                    _buildLabel("Select Subject"),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('subjects')
                          .where('active', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            "Error: Check your Firestore rules",
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator(
                            color: Colors.orange,
                          );
                        }

                        // Check if the collection actually has documents
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            "No subjects found in Firestore 'subjects' collection.",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          );
                        }

                        // Get the Document IDs
                        var items = snapshot.data!.docs
                            .map((doc) => doc.id)
                            .toList();

                        return _buildDropdown(
                          _selectedSubject,
                          items,
                          "Choose a subject",
                          (val) {
                            setState(() => _selectedSubject = val);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- 3. Title & Description ---
                    _buildLabel("Title"),
                    _buildTextField(_titleController, "e.g. Workbook Page 10"),
                    const SizedBox(height: 20),
                    _buildLabel("Description"),
                    _buildTextField(_descController, "Details...", maxLines: 3),

                    const SizedBox(height: 25),

                    // --- 4. Date Picker ---
                    _buildDatePickerRow(),

                    const SizedBox(height: 40),

                    // --- 5. Submit Button ---
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _dropdownStyle() => InputDecoration(
    filled: true,
    fillColor: Colors.grey[200],
    // Slightly darker to indicate read-only status
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _buildDropdown(
    String? value,
    List<String> items,
    String hint,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Required" : null,
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDatePickerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Due Date",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedDueDate == null
                  ? "Not selected"
                  : DateFormat('dd/MM/yyyy').format(_selectedDueDate!),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (date != null) setState(() => _selectedDueDate = date);
          },
          child: const Text("Pick Date"),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSaving ? null : _saveToFirestore,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Post Assignment",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveToFirestore() async {
    if (!_formKey.currentState!.validate() || _selectedDueDate == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('assignments').add({
        'classId': _selectedClass,
        'subject': _selectedSubject,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'dueDate': Timestamp.fromDate(_selectedDueDate!),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
