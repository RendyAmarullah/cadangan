import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pemesanan/SplahScreen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _signUp() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get the current user
      User? user = userCredential.user;

      // If user is successfully created, update their display name
      if (user != null) {
        // Update user display name
        await user.updateDisplayName(_nameController.text.trim());

        // Add user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akun berhasil dibuat!')),
        );

        // Navigate to the login page
        Navigator.pop(context); // Return to login screen
      }
    } on FirebaseAuthException catch (e) {
      // Show error message if signup fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'images/signup.jpg', // Replace this with your image path
              fit: BoxFit.cover,
            ),
          ),
          // Centered SignUp Box
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0), // Semi-transparent white background
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Align(
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          'images/logosignup.png',
                          width: 150,
                        ),
                      ),
                      SizedBox(height: 5),
                      
                      Center(
                        child: Text(
                          "Create an Account",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Name Input
                      TextFormField(
                        controller: _nameController,
                        validator: (value) => value == null || value.isEmpty ? "Masukkan nama" : null,
                        decoration: _inputDecoration("Name"),
                      ),
                      SizedBox(height: 15),
                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        validator: (value) => value != null && value.contains("@")
                            ? null
                            : "Masukkan email yang valid",
                        decoration: _inputDecoration("Email"),
                      ),
                      SizedBox(height: 15),
                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : "Minimal 6 karakter",
                        decoration: _inputDecoration("Password"),
                      ),
                      SizedBox(height: 20),
                      // Sign Up Button
                      Center(
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                    onPressed: () async {
                        try {
                    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    
                    // Simpan data tambahan ke Firestore
                    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                      'email': _emailController.text,
                      'name': _nameController.text,
                      'password' : _passwordController.text,
                      
              
                    });
              
                    Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => SplashScreen()),
                        );
                  } catch (e) {
                    print(e);
                  }
                },
               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text("LOGIN", style: TextStyle(color: Colors.white),),
                  ),
                           
                            // : ElevatedButton(
                            //     onPressed: _signUp,
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.green,
                            //       shape: StadiumBorder(),
                            //       padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            //     ),
                            //     child: Text("SIGN UP", style: TextStyle(color: Colors.white)),
                            //   ),
                      ),
                      SizedBox(height: 10),
                      // Login Text Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Already have an account? Login",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }
}
