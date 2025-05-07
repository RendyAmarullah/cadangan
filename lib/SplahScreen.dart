import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/homescreen.dart';
import 'package:pemesanan/main.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  bool _showImage = false;
  bool _showForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();

    // Delay before logo animation
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showImage = true;
        _controller.forward();
      });
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _showForm = true;
    });
  }

  // Function to handle login
  void _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If login is successful, navigate to the main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to Home Screen
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _toggleForm,
        child: Stack(
          children: [
            Center(
              child: _showImage
                  ? SlideTransition(
                      position: _animation,
                      child: Image.asset(
                        'images/login.png',
                        width: 1000,
                        height: 1000,
                      ),
                    )
                  : Image(image: AssetImage("images/logo.PNG")),
            ),
            // Form from the bottom
            if (_showForm)
              AnimatedPositioned(
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                bottom: 0,
                left: 0,
                right: 0,
                height: 350,
                child: Container(
                  height: 450,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(254, 254, 254, 0.843), // Light green
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          "Enter Your Account",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Colors.grey,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        obscureText: true,
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Colors.grey,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Action for forgot password
                          },
                          child: Text(
                            "Lupa Password",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 0),
                      Center(
                        child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final userCredential = await _auth.signInWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                  //     if (userCredential.user != null) {
                  //   final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
                  //   final role = userDoc['role'];
                  //   if (role == 'admin') {
                  //     Navigator.pushReplacement(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => MainScreen()),
                  //     );
                  //   } else {
                  //     Navigator.pushReplacement(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => MainScreen()),
                  //     );
                  //   }
                  // };
                    } catch (error) {
                      print(error.toString());  
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text("LOGIN", style: TextStyle(color: Colors.white),),
                  // child: const Text('Sign In'),
                  // style: ButtonStyle(
                  //     shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.zero))),
                ),

                        
                        // child: ElevatedButton(
                        //   onPressed: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(builder: (context) => MainScreen()),
                        //     );
                        //   }, // Trigger the login action
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.blue,
                        //     shape: StadiumBorder(),
                        //     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        //   ),
                        //   child: Text("LOGIN", style: TextStyle(color: Colors.white)),
                        // ),
                      ),
                      SizedBox(height: 1),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpScreen()),
                            );
                          },
                          child: Text(
                            "Sign up",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
