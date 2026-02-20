
import 'package:flutter/material.dart';

class ParentHomepage extends StatelessWidget {
  const ParentHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Home"),),
      body: const Center(
        child: Text("Welcome Parent"),
      ),
    );
  }
}
