import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'loginPage.dart'; // Import your LoginPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions(
        apiKey: "AIzaSyDBVSuDwe2yyj01UUMgZW9cMyf1tzvNCCo",
        authDomain: "drukfunding-2.firebaseapp.com",
        projectId: "drukfunding-2",
        storageBucket: "drukfunding-2.firebasestorage.app",
        messagingSenderId: "556852971215",
        appId: "1:556852971215:web:6db6276765cb9e691b19ba"));
  }
  else{
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DrukFunding App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Set the LoginPage as the initial screen
      home: const LoginPage(),
    );
  }
}