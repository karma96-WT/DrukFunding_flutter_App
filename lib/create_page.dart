import 'package:flutter/material.dart';
import 'package:drukfunding/model/project.dart';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();

  // variable to hold selected image
  XFile? _selectedImage;

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    } else {
      // Show a message if user canceled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection canceled.')),
      );
    }
  }

  // Helper widget to build the image picker section
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ MODIFIED: Wrap the button in a SizedBox for full width
        SizedBox(
          width: double.infinity, // Forces the button to take maximum width
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.file_upload, color: Colors.white),
            label: Text(
              _selectedImage == null ? 'Upload Image' : 'Change Image',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Validation/Status text
        if (_selectedImage == null)
          // Ensure this text aligns with the start of the button
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4.0,
            ), // Optional: Match button's internal text padding
            child: Text(
              'Please select an image for your project.',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
            ), // Optional: Match button's internal text padding
            child: Text(
              'Image Selected: ${_selectedImage!.name}',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
          ),
      ],
    );
  }

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
        title: Center(child: const Text('Create campaign here')),
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
              'Describe your idea',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill correct details to get verified faster!!',
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

            // Project Description Field
            _buildTextFormField(
              controller: _descriptionController,
              labelText: 'Project Description',
              hintText: 'e.g., This project aims to revolutionize...',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 20),

            // Project Tagline Field
            _buildTextFormField(
              controller: _taglineController,
              labelText: 'Project Tagline',
              hintText: 'e.g., Innovating the Future',
              icon: Icons.tag,
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            _buildCategoryDropdown(),
            const SizedBox(height: 20),

            // Funding Goal Field
            _buildTextFormField(
              controller: _goalController,
              labelText: 'Funding Goal (Nu.)',
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
            _buildImagePicker(),
            const SizedBox(height: 30),
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
