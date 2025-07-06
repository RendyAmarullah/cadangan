import 'package:flutter/material.dart';

class LupaPasswordScreen extends StatefulWidget {
  @override
  _LupaPasswordScreenState createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isEmailSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();

      // Tampilkan dialog sukses untuk email
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Email Terkirim'),
            content: Text('Link reset password telah dikirim ke email Anda.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isEmailSubmitted = true; // Ubah status setelah email dikirim
                  });
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      print('Reset password untuk email: $email');
    }
  }

  void _submitNewPassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      // Tampilkan pesan error jika password tidak cocok
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Password dan konfirmasi password tidak cocok.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Implementasi logika untuk reset password
      String newPassword = _newPasswordController.text.trim();
      // Tampilkan dialog sukses
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Password Berhasil Diperbarui'),
            content: Text('Password Anda telah berhasil diperbarui.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Kembali ke halaman login
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      print('Password berhasil diperbarui: $newPassword');
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password harus lebih dari 6 karakter';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=880&q=80'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan tombol back
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                    ],
                  ),

                  // Spacer untuk mendorong form ke tengah
                  Spacer(flex: 2),

                  // Form Section
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Instruksi
                        Container(
                          margin: EdgeInsets.only(bottom: 30),
                          child: Text(
                            _isEmailSubmitted
                                ? 'Masukkan password baru Anda'
                                : 'Masukkan email Anda untuk menerima link reset password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Email TextField (tampil hanya jika email belum dikirim)
                        if (!_isEmailSubmitted)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),

                        // Password TextFields (tampil setelah email dikirim)
                        if (_isEmailSubmitted) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _newPasswordController,
                              obscureText: true,
                              validator: _validatePassword,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password Baru',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              validator: _validatePassword,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Konfirmasi Password',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 30),

                        // Submit Button
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF2196F3),
                                Color(0xFF1976D2),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2196F3).withOpacity(0.4),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isEmailSubmitted
                                ? _submitNewPassword
                                : _submitEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              _isEmailSubmitted ? 'GANTI PASSWORD' : 'SUBMIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(flex: 3),

                  // Footer text
                  Center(
                    child: Text(
                      'Ingat password Anda?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Kembali ke Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
