import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/HomeScreenKaryawan.dart';
import 'package:pemesanan/LupaPasswordScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/homescreen.dart';
import 'package:pemesanan/main.dart';
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
  bool _isLoading = false;
  bool _obscureText = true;

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

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _checkExistingSession();

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showImage = true;
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final user = await account.get();
      if (user != null) {
        final isAccountActive = await _checkAccountStatus(user.$id);
        if (!isAccountActive) {
          await account.deleteSession(sessionId: 'current');
          return;
        }
        await _navigateBasedOnRole(user);
      }
    } catch (e) {
      print("Tidak ada session aktif: $e");
    }
  }

  Future<bool> _checkAccountStatus(String userId) async {
    try {
      final response = await database.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: userId,
      );
      final status = response.data['status'] ?? 'Aktif';
      return status == 'Aktif';
    } catch (e) {
      print("Error checking account status: $e");
      return true;
    }
  }

  Future<void> _navigateBasedOnRole(models.User user) async {
    try {
      final userId = user.$id;
      final response = await database.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: userId,
      );

      final roles = List<String>.from(response.data['roles'] ?? []);

      if (roles.contains('karyawan')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreenKaryawan(userId: userId)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(userId: userId)),
        );
      }
    } catch (e) {
      print("Error getting user role: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  void _toggleForm() {
    setState(() {
      _showForm = true;
    });
  }

  Future<void> _login() async {
    if (_isLoading) return;

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar('Email dan password harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      try {
        await account.deleteSession(sessionId: 'current');
      } catch (e) {
        print("Tidak ada session aktif untuk dihapus: $e");
      }

      final session = await account.createEmailPasswordSession(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = await account.get();
      final isAccountActive = await _checkAccountStatus(user.$id);

      if (!isAccountActive) {
        await account.deleteSession(sessionId: 'current');
        _showAccountInactiveDialog();
        return;
      }

      await _navigateBasedOnRole(user);
    } on AppwriteException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 401:
          errorMessage = 'Email atau password salah';
          break;
        case 429:
          errorMessage = 'Terlalu banyak percobaan login. Coba lagi nanti';
          break;
        default:
          errorMessage = 'Login gagal: ${e.message}';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      print("Unexpected error: $e");
      _showSnackBar('Terjadi kesalahan tidak terduga');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAccountInactiveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Akun Nonaktif'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akun Anda telah dinonaktifkan oleh admin.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Silakan daftar kembali untuk menggunakan aplikasi.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8DC63F),
              ),
              child: Text(
                'Daftar Kembali',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: _showForm ? null : _toggleForm,
        child: Stack(
          children: [
            _buildBackground(),
            if (_showImage && !_showForm) _buildSwipeUpIndicator(),
            if (_showForm) _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: _showImage
          ? SlideTransition(
              position: _animation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('images/login.png', fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.3)),
                ],
              ),
            )
          : Image.asset("images/logo.PNG", fit: BoxFit.cover),
    );
  }

  Widget _buildSwipeUpIndicator() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            "Geser Ke Atas",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Untuk Masuk",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 10),
          Icon(
            Icons.keyboard_arrow_up,
            size: 30,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Masukkan Akun Anda",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.black),
                    decoration: _inputDecoration("Email"),
                    enabled: !_isLoading,
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    obscureText: _obscureText,
                    controller: _passwordController,
                    style: TextStyle(color: Colors.black),
                    decoration: _inputDecoration("Password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  _buildActionButtons(),
                  SizedBox(height: 10),
                  _buildLoginButton(),
                  if (_isLoading) ...[
                    SizedBox(height: 10),
                    Text(
                      "Sedang masuk...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  ),
          child: Text(
            "Daftar",
            style: TextStyle(color: Color(0xFF8DC63F)),
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LupaPasswordScreen()),
                  ),
          child: Text(
            "Lupa Password",
            style: TextStyle(color: Color(0xFF8DC63F)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              "MASUK",
              style: TextStyle(color: Colors.white),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.grey[300],
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }
}
