// add_tier_dialog.dart

import 'package:flutter/material.dart';

// 1. Define the callback function type
typedef OnTierAdded = void Function(RewardTier tier);

// 2. Define the RewardTier structure (must be accessible here)
class RewardTier {
  String name;
  double amount;
  String description;
  int? limit;
  bool isFlexible;

  RewardTier({
    required this.name,
    required this.amount,
    required this.description,
    this.limit,
    this.isFlexible = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'description': description,
      'limit': limit,
      'isFlexible': isFlexible,
      'backedCount': 0,
    };
  }
}


class AddTierDialog extends StatefulWidget {
  final OnTierAdded onTierAdded;

  const AddTierDialog({super.key, required this.onTierAdded});

  @override
  State<AddTierDialog> createState() => _AddTierDialogState();
}

class _AddTierDialogState extends State<AddTierDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers are now LOCAL to this dialog's state!
  final TextEditingController _tierNameController = TextEditingController();
  final TextEditingController _tierAmountController = TextEditingController();
  final TextEditingController _tierDescriptionController = TextEditingController();
  final TextEditingController _tierLimitController = TextEditingController();

  bool _isFlexiblePledge = false;

  // 1. Logic to add and return the tier
  void _submitTier() {
    if (_formKey.currentState!.validate()) {
      final newTier = RewardTier(
        name: _tierNameController.text.trim(),
        amount: double.parse(_tierAmountController.text),
        description: _tierDescriptionController.text.trim(),
        limit: _tierLimitController.text.isEmpty
            ? null
            : int.tryParse(_tierLimitController.text),
        isFlexible: _isFlexiblePledge,
      );

      // Call the callback function defined in CreatePage
      widget.onTierAdded(newTier);

      // Close the dialog
      Navigator.of(context).pop();
    }
  }

  // 2. Dispose of the controllers when this dialog widget is removed
  @override
  void dispose() {
    _tierNameController.dispose();
    _tierAmountController.dispose();
    _tierDescriptionController.dispose();
    _tierLimitController.dispose();
    super.dispose();
  }

  // Helper for text fields (can reuse the one from CreatePage or define simply here)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required.' : null,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Reward Tier'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Is Flexible Pledge?'),
                value: _isFlexiblePledge,
                onChanged: (bool value) {
                  setState(() {
                    _isFlexiblePledge = value;
                    if (value) {
                      _tierAmountController.text = '1.0';
                      _tierLimitController.clear();
                    } else {
                      _tierAmountController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 10),

              _buildTextFormField(
                controller: _tierNameController,
                labelText: 'Tier Title',
                icon: Icons.label,
              ),
              const SizedBox(height: 10),

              _buildTextFormField(
                controller: _tierAmountController,
                labelText: _isFlexiblePledge ? 'Minimum Pledge (Nu.)' : 'Pledge Amount (Nu.)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid positive amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              _buildTextFormField(
                controller: _tierDescriptionController,
                labelText: 'Reward Description',
                icon: Icons.description,
              ),
              const SizedBox(height: 10),

              if (!_isFlexiblePledge)
                _buildTextFormField(
                  controller: _tierLimitController,
                  labelText: 'Quantity Limit (Optional)',
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                      return 'Enter a valid number.';
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _submitTier,
          child: const Text('Add Tier'),
        ),
      ],
    );
  }
}