import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'loginPage.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  // Controllers for form input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Core Registration Function ---
  Future<void> _handleRegistration() async {
    // 1. Basic Form Validation
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match.', Colors.red);
      return;
    }
    if (!_agreedToTerms) {
      _showSnackBar('You must agree to the Terms of Service.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --- Step 1: Firebase Authentication (Email/Password) ---
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // --- Step 2: Cloud Firestore (Save Profile Data) ---
        await _firestore.collection('Users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': _usernameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Success and navigate to login
        _showSnackBar('Registration Successful! Please Log In.', Colors.green);

        // Navigate to LoginPage
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Registration Failed: ${e.message}', Colors.red);
    } catch (e) {
      print('General error during registration: $e');
      _showSnackBar('An unknown error occurred.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join the Movement'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Create Your Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // --- Email Field (FIX 1) ---
            TextField( // Removed 'const'
              controller: _emailController, // 👈 Link Controller
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Username Field (FIX 1) ---
            TextField( // Removed 'const'
              controller: _usernameController, // 👈 Link Controller
              decoration: const InputDecoration(
                labelText: 'Public Username',
                hintText: 'Choose a display name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Password Field (FIX 1) ---
            TextField( // Removed 'const'
              controller: _passwordController, // 👈 Link Controller
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter a secure password (min 8 characters)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Confirm Password Field (FIX 1) ---
            TextField( // Removed 'const'
              controller: _confirmPasswordController, // 👈 Link Controller
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: Icon(Icons.lock_reset),
                border: OutlineInputBorder(),
              ),
            ),

            // Phone number field (FIX 1)
            const SizedBox(height: 24),
            TextField( // Removed 'const'
              controller: _phoneController, // 👈 Link Controller
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter Phone number',
                prefixIcon: Icon(Icons.call),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // --- Terms and Conditions Checkbox (FIX 2) ---
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms, // 👈 Read state
                  onChanged: (bool? newValue) {
                    setState(() {
                      _agreedToTerms = newValue ?? false; // 👈 Write state
                    });
                  },
                ),
                const Flexible(
                  child: Text(
                    'I agree to the Terms of Service and Privacy Policy.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Primary Action Button (FIX 3 & 4) ---
            ElevatedButton(
              // Call the registration function, disabled if loading
              onPressed: _isLoading ? null : _handleRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox( // Show loading indicator
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3),
              )
                  : const Text( // Show Sign Up text
                'Sign Up',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),

            // --- Existing User Link ---
            TextButton(
              // This button should just navigate/pop to LoginPage
              onPressed: () {
                Navigator.pop(
                    context); // Assumes LoginPage is beneath Registration
              },
              child: const Text('Already have an account? Log In'),
            ),
          ],
        ),
      ),
    );
  }
}