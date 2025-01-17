import 'package:flutter/material.dart';

class UnassignedCases extends StatelessWidget {
  const UnassignedCases({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unassigned Cases'),
      ),
      body: const Center(
        child: Text(
          'This is the Unassigned Cases screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
