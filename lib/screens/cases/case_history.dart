import 'package:flutter/material.dart';

class CaseHistoryScreen extends StatelessWidget {
  const CaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case History'),
      ),
      body: const Center(
        child: Text(
          'This is the Case History screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
