// create_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_tier.dart';


class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  // Global key for the Form widget
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Main Project Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _creatorController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // Tier Management State (uses the imported RewardTier class)
  final List<RewardTier> _rewardTiers = [];

  // Image and Category state
  XFile? _selectedImage;
  String? _selectedCategory;
  final List<String> _categories = [
    'Innovation', 'Gaming', 'Fashion', 'Food', 'Art', 'Technology', 'Culture',
  ];

  // --- METHODS ---

  void _removeRewardTier(int index) {
    setState(() {
      _rewardTiers.removeAt(index);
    });
  }

  void _showAddTierDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Uses the imported AddTierDialog
        return AddTierDialog(
          onTierAdded: (newTier) {
            // This callback receives the validated tier from the dialog
            setState(() {
              _rewardTiers.add(newTier);
            });
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection canceled.')),
      );
    }
  }

  Future<void> _submitProject() async {
    if (_formKey.currentState!.validate()) {

      // ⭐ CRITICAL FIX: Image Validation Check Added
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload an image before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_rewardTiers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please define at least one reward tier.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final projectData = {
          'title': _titleController.text.trim(),
          'creator': _creatorController.text.trim(),
          'description': _descriptionController.text.trim(),
          'tagline': _taglineController.text.trim(),
          'category': _selectedCategory,
          'goal': double.parse(_goalController.text),
          'raised': 0.0,
          'duration': _durationController.text.trim(),
          'userId': userId,
          'status': 'pending',
          'imageUrl': 'https://placehold.co/600x400/3498db/FFFFFF?text=New+Project', // Replace with actual uploaded URL later
          'creatorImageUrl': 'https://placehold.co/50x50/3498db/FFFFFF?text=ME',
          'createdAt': Timestamp.now(),
        };

        // 2. Save main Project document
        final newProjectRef = await FirebaseFirestore.instance.collection('Projects').add(projectData);

        // 3. Save Tiers to the 'Tiers' subcollection using a Batch
        final batch = FirebaseFirestore.instance.batch();
        for (var tier in _rewardTiers) {
          batch.set(newProjectRef.collection('Tiers').doc(), tier.toMap());
        }
        await batch.commit(); // ✅ THIS SAVES THE TIER DATA TO FIRESTORE

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Success! Project "${_titleController.text}" submitted with ${_rewardTiers.length} tiers.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _titleController.clear();
        _creatorController.clear();
        _goalController.clear();
        _descriptionController.clear();
        _taglineController.clear();
        _durationController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedImage = null;
          _rewardTiers.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // CRITICAL: Dispose all main controllers
  @override
  void dispose() {
    _titleController.dispose();
    _creatorController.dispose();
    _goalController.dispose();
    _descriptionController.dispose();
    _taglineController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // --- WIDGET BUILDERS (Helper Methods) ---

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedImage == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Please select an image for your project.',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Image Selected: ${_selectedImage!.name}',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
          ),
      ],
    );
  }

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
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) { return 'This field is required.'; }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2.0)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Center(
              child: Text('Describe your idea', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800])),
            ),
            const SizedBox(height: 30),

            _buildTextFormField(controller: _titleController, labelText: 'Project Title', hintText: 'e.g., The Next-Gen 3D Printer', icon: Icons.lightbulb_outline),
            const SizedBox(height: 20),
            _buildTextFormField(controller: _creatorController, labelText: 'Your Name/Company', hintText: 'e.g., Innovate Labs', icon: Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextFormField(controller: _descriptionController, labelText: 'Project Description', hintText: 'e.g., This project aims to revolutionize...', icon: Icons.description_outlined),
            const SizedBox(height: 20),
            _buildTextFormField(controller: _taglineController, labelText: 'Project Tagline', hintText: 'e.g., Innovating the Future', icon: Icons.tag),
            const SizedBox(height: 20),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _goalController, labelText: 'Funding Goal (Nu.)', hintText: 'e.g., Nu. 50000', icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) { if (double.tryParse(value ?? '') == null || double.parse(value!) <= 0) { return 'Enter a valid positive number.'; } return null; },
            ),
            const SizedBox(height: 20),
            _buildTextFormField(controller: _durationController, labelText: 'Project Duration (e.g., 30 days)', hintText: 'e.g., 15 days', icon: Icons.timelapse),
            const SizedBox(height: 20),

            // --- REWARD TIER SECTION ---
            Text('Reward Tiers Defined (${_rewardTiers.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800])),
            const SizedBox(height: 10),

            // Display current list of tiers
            ..._rewardTiers.asMap().entries.map((entry) {
              final tier = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                elevation: 1,
                child: ListTile(
                  leading: Icon(tier.isFlexible ? Icons.favorite_border : Icons.star, color: tier.isFlexible ? Colors.red : Colors.amber),
                  title: Text(tier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    tier.isFlexible
                        ? 'Pledge Min: Nu. ${tier.amount.toStringAsFixed(2)}'
                        : 'Pledge: Nu. ${tier.amount.toStringAsFixed(2)} ' + (tier.limit != null ? ' (Limit: ${tier.limit})' : ''),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeRewardTier(entry.key),
                  ),
                ),
              );
            }).toList(),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddTierDialog,
                icon: const Icon(Icons.add_box),
                label: const Text('Add Reward Tier'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.blue.shade200)),
              ),
            ),
            // --- END REWARD TIER SECTION ---

            const SizedBox(height: 30),
            _buildImagePicker(),
            const SizedBox(height: 30),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Project', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}