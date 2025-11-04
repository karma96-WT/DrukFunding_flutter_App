import 'package:flutter/material.dart';
import 'homePage.dart';
import 'registration.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController emailControler = TextEditingController();
  final TextEditingController passwordControler = TextEditingController();

  // Firebase instance and loading state
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void Login() async {
    // 1. Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Call Firebase Sign In
      await _auth.signInWithEmailAndPassword(
        email: emailControler.text.trim(),
        password: passwordControler.text.trim(),
      );

      // 3. Success: Navigate to the main app (CrowdfundingApp)
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CrowdfundingApp())
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = 'Login Failed. Invalid email or password.';

      // Customize error messages
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many login attempts. Try again later.';
      }

      // Show error to the user
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red)
      );

    } catch (e) {
      // Catch any unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unknown error occurred.'), backgroundColor: Colors.red)
      );
    } finally {
      // 4. Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void Register(){
    // push to registration page
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const Registration())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Welcome to DrukFunding!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue
                ),
              ),
              const Text(' Your partner to bring your idea alive!!',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                    controller: emailControler,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.email)
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: passwordControler,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)
                    ),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              ElevatedButton(
                onPressed: Login,
                child: const Text('LOGIN',
                    style: TextStyle(fontSize: 18,color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                    )
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(onPressed: Register, child: Text('Click Here!')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}