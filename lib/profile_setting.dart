import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // 1. Controllers for input fields (all must be disposed)
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController(); // NEW
  final TextEditingController _imageUrlController = TextEditingController();

  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 2. CRITICAL: Dispose controllers
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // --- Firestore Data Handling ---

  Future<void> _fetchUserData() async {
    if (currentUser == null) return;

    final userId = currentUser!.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Email is always retrieved from FirebaseAuth for accuracy
      _emailController.text = currentUser!.email ?? '';

      if (userDoc.exists) {
        final data = userDoc.data()!;
        // Populate controllers with data from Firestore
        _usernameController.text = data['username'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? ''; // NEW: Retrieve phone number
        _imageUrlController.text = "https://th.bing.com/th/id/OIP.Zvs5IHgOO5kip7A32UwZJgHaHa?o=7&cb=ucfimg2rm=3&ucfimg=1&rs=1&pid=ImgDetMain&o=7&rm=3";
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data.')),
      );
    }
  }

  Future<void> _updateUserData() async {
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = currentUser!.uid;

      // Data to be saved to Firestore
      final updatedData = {
        'username': _usernameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(), // NEW: Save phone number
        'profileImageUrl': _imageUrlController.text.trim(),
      };

      // Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        updatedData,
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ⭐ NEW: Password Reset Functionality
  Future<void> _resetPassword() async {
    if (currentUser == null || currentUser!.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found to reset password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to ${currentUser!.email}'),
          backgroundColor: Colors.orange,
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Widget Builders ---

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Please log in to view settings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 47, 117, 223),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Image Preview
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage( _imageUrlController.text),
                  backgroundColor: Colors.grey.shade200,
                  // Note: No onBackgroundImageError in StatelessWidget, simplified for preview
                ),
              ),
            ),

            // Username Field
            _buildInputField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person,
            ),

            // Phone Number Field (NEW)
            _buildInputField(
              controller: _phoneNumberController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),

            // Email Field (Non-editable, retrieved from FirebaseAuth)
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              enabled: false, // Email is non-editable
            ),

            // Profile Image URL Field
            _buildInputField(
              controller: _imageUrlController,
              label: 'Profile Image URL',
              icon: Icons.link,
            ),

            const SizedBox(height: 30),

            const Divider(),
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}