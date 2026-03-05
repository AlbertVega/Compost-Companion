import 'package:flutter/material.dart';
import 'package:compost_companion/data/services/ingredient_service.dart';

class IngredientCreateScreen extends StatefulWidget {
  const IngredientCreateScreen({super.key});

  @override
  State<IngredientCreateScreen> createState() => _IngredientCreateScreenState();
}

class _IngredientCreateScreenState extends State<IngredientCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _moistureController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _carbonController = TextEditingController();
  final _service = IngredientService();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _moistureController.dispose();
    _nitrogenController.dispose();
    _carbonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final created = await _service.createIngredient(
        name: _nameController.text.trim(),
        moistureContent: double.parse(_moistureController.text.trim()),
        nitrogenContent: double.parse(_nitrogenController.text.trim()),
        carbonContent: double.parse(_carbonController.text.trim()),
      );

      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateNumber(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ingredient'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _moistureController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Moisture content',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateNumber(value, 'Moisture content'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nitrogenController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Nitrogen content',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateNumber(value, 'Nitrogen content'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carbonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Carbon content',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateNumber(value, 'Carbon content'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save ingredient'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
