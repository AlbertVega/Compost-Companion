import 'package:flutter/material.dart';

class CreateScreen extends StatelessWidget {
  final Function(String) onSave;
  const CreateScreen({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: const Center(child: Text('Create screen placeholder')),
    );
  }
}