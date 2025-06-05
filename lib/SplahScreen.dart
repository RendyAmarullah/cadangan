import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/homescreen.dart';
import 'appwrite_service.dart';

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

  final Client client = Client();
  late Account account;
  late Databases database;

  final String projectId = '681aa0b70002469fc157';
  final String endpoint = 'https://cloud.appwrite.io/v1';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '684083800031dfaaecad';

  @override
  void initState() {
    super.initState();

    client.setEndpoint(endpoint).setProject(projectId);

    account = Account(client);
    database = Databases(client);

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

  void _login() async {
    try {
      await AppwriteService.account.deleteSession(sessionId: 'current');

      await AppwriteService.account.createEmailPasswordSession(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = await AppwriteService.account.get();

      print("Login berhasil: ${user.email}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on AppwriteException catch (e) {
      print("Login error: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: ${e.message}')),
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
            if (_showForm)
              AnimatedPositioned(
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                bottom: 0,
                left: 0,
                right: 0,
                height: 350,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(254, 254, 254, 0.843),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
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
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration("Email"),
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        obscureText: true,
                        controller: _passwordController,
                        decoration: _inputDecoration("Password"),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text("Lupa Password",
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final session =
                                  await account.createEmailPasswordSession(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                              );

                              Navigator.pushReplacementNamed(context, '/home');
                              ;
                            } on AppwriteException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Login gagal: ${e.message}')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: StadiumBorder(),
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("LOGIN",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpScreen()),
                            );
                          },
                          child: Text("Sign up",
                              style: TextStyle(color: Colors.black)),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black),
      filled: true,
      fillColor: Colors.grey[300],
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }
}
