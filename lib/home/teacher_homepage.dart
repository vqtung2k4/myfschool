
import 'package:flutter/material.dart';

class TeacherHomepage extends StatelessWidget {
  const TeacherHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Home"),),
      body: const Center(
        child: Text("Welcome Teacher"),
      ),
    );
  }
}
