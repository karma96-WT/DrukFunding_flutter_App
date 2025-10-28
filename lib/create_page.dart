import 'package:flutter/material.dart';
// Assuming Project model is in this path
import 'package:drukfunding/model/project.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  // Global key for the Form widget to enable validation and reset
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for capturing user input
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _creatorController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  // State for the dropdown field
  String? _selectedCategory;
  final List<String> _categories = [
    'Sustainable',
    'Gaming',
    'Fashion',
    'Food',
    'Art',
    'Technology',
  ];

  @override
  void dispose() {
    // Dispose of controllers when the widget is removed from the widget tree
    _titleController.dispose();
    _creatorController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  // Helper widget to build a standardized text input field
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required.';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 10.0,
        ),
      ),
    );
  }

  // Helper widget to build the category dropdown
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        hintText: 'Select a project category',
        prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedCategory,
      hint: const Text('Select a category'),
      isExpanded: true,
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(value: category, child: Text(category));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a category.';
        }
        return null;
      },
    );
  }

  // Mock function to handle form submission
  void _submitProject() {
    if (_formKey.currentState!.validate()) {
      // Form fields are valid, proceed to create the project object
      final newProject = Project(
        title: _titleController.text,
        creator: _creatorController.text,
        // Mocked data for simplicity in a creation form
        imageUrl: 'https://placehold.co/600x400/3498db/FFFFFF?text=New+Project',
        category: _selectedCategory!,
        raised: 0.0, // Starts at 0 when created
        goal: double.parse(_goalController.text),
        creatorImageUrl: 'https://placehold.co/50x50/3498db/FFFFFF?text=ME',
      );

      // In a real application, you would send this 'newProject' data to a database.

      // Show confirmation SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Success! Project "${newProject.title}" launched with a \$${newProject.goal.toStringAsFixed(0)} goal.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Optionally reset the form after successful submission
      _formKey.currentState!.reset();
      _titleController.clear();
      _creatorController.clear();
      _goalController.clear();
      setState(() {
        _selectedCategory = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launch a New Project'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      // Use ListView to ensure the form is scrollable and avoids keyboard overflow
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Header
            Text(
              'Tell us about your idea!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill out the details below to start crowdfunding.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // Project Title Field
            _buildTextFormField(
              controller: _titleController,
              labelText: 'Project Title',
              hintText: 'e.g., The Next-Gen 3D Printer',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 20),

            // Creator Name Field
            _buildTextFormField(
              controller: _creatorController,
              labelText: 'Your Name/Company',
              hintText: 'e.g., Innovate Labs',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            _buildCategoryDropdown(),
            const SizedBox(height: 20),

            // Funding Goal Field
            _buildTextFormField(
              controller: _goalController,
              labelText: 'Funding Goal (\$)',
              hintText: 'e.g., 50000',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a funding goal.';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid positive number.';
                }
                return null;
              },
            ),

            // Note on Image/Description (would be more complex fields in a real app)
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                '*Additional fields for Project Description and Image Upload would be added here.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            ElevatedButton(
              onPressed: _submitProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Launch Project',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
