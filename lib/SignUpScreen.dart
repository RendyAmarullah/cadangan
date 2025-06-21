import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/SplahScreen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  final Client _client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('681aa0b70002469fc157');

  late final Account _account = Account(_client);
  late final Databases _databases = Databases(_client);

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String usersCollectionId = '684083800031dfaaecad';
  String status = 'Aktif';
  List<String> roles = ['pelanggan'];


  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      await _databases.createDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: user.$id,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'status' : status,
          'roles' : roles,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Akun berhasil dibuat!')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal daftar: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Background tidak naik saat keyboard muncul
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/signup.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    Image.asset(
                      'images/logotanpanama.png',
                      width: 150,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Buat Akun",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            validator: (value) => value == null || value.isEmpty
                                ? "Masukkan nama"
                                : null,
                            decoration: _inputDecoration("Name"),
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: _emailController,
                            validator: (value) =>
                                value != null && value.contains("@")
                                    ? null
                                    : "Masukkan email yang valid",
                            decoration: _inputDecoration("Email"),
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) =>
                                value != null && value.length >= 6
                                    ? null
                                    : "Minimal 6 karakter",
                            decoration: _inputDecoration("Password"),
                          ),
                          SizedBox(height: 20),
                          _isLoading
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: StadiumBorder(),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 12),
                                  ),
                                  child: Text(
                                    "DAFTAR",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Already have an account? Login",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
