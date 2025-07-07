import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/SplahScreen.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  late Client _client;
  late Storage _storage;
  late Account _account;
  late Databases _databases;

  File? _imageFile;
  String? _profileImageUrl;
  String? _userName;
  String? _userEmail;
  String? _noHp;
  models.Session? _session;
  models.User? _currentUser;

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '681aa352000e7e9b76b5';
  final String profil = '684083800031dfaaecad';
  final String bucketId = '681aa16f003054da8969';
  final String projectId = '681aa0b70002469fc157';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noHandPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
    _loadProfileData();
  }

  void _initializeAppwrite() {
    _client = Client()
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _storage = Storage(_client);
    _account = Account(_client);
    _databases = Databases(_client);
  }

  Future<void> _loadProfileData() async {
    try {
      _session = await _account.getSession(sessionId: 'current');
      _currentUser = await _account.get();

      final userId = _currentUser?.$id;
      if (userId == null) return;

      await _loadProfileImage(userId);
      await _loadUserData(userId);
      _setControllerValues();
    } catch (e) {
      print('Tidak dapat memuat profil data: $e');
    }
  }

  Future<void> _loadProfileImage(String userId) async {
    try {
      final profileDoc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: userId,
      );

      final profileImageId = profileDoc.data['profile_image'];
      if (profileImageId != null) {
        setState(() {
          _profileImageUrl = _buildImageUrl(profileImageId);
        });
      }
    } catch (e) {
      print('Tidak dapat memuat gambar profil: $e');
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userNameDoc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: profil,
        documentId: userId,
      );

      setState(() {
        _userName = userNameDoc.data['name'];
        _userEmail = userNameDoc.data['email'];
        _noHp = userNameDoc.data['noHandphone'];
      });
    } catch (e) {
      print('Tidak dapat memuat data user: $e');
    }
  }

  void _setControllerValues() {
    _nameController.text = _userName ?? '';
    _emailController.text = _userEmail ?? '';
    _noHandPhoneController.text = _noHp ?? '';
  }

  String _buildImageUrl(String fileId) {
    return 'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/$fileId/view?project=$projectId';
  }

  Future<void> _updateProfile() async {
    try {
      final updatedName = _nameController.text.trim();
      final updatedEmail = _emailController.text.trim();
      final updatedNoHandphone = _noHandPhoneController.text.trim();
      final updatedPassword = _passwordController.text;

      if (!_validateInput(updatedName, updatedEmail, updatedPassword)) return;

      final user = await _account.get();
      if (user == null) return;

      final emailChanged = updatedEmail != _userEmail;

      if (emailChanged) {
        await _account.updateEmail(
          email: updatedEmail,
          password: updatedPassword,
        );
      }

      await _updateUserDatabase(
          user.$id, updatedName, updatedEmail, updatedNoHandphone);
      _updateState(updatedName, updatedEmail, updatedNoHandphone);
      _showSuccessMessage();

      if (emailChanged) {
        await _handleEmailChange();
      }
    } catch (e) {
      _handleUpdateError(e);
    }
  }

  bool _validateInput(String name, String email, String password) {
    if (name.isEmpty) {
      _showSnackBar('Nama tidak boleh kosong');
      return false;
    }
    if (email.isEmpty) {
      _showSnackBar('Email tidak boleh kosong');
      return false;
    }
    if (password.isEmpty) {
      _showSnackBar('Password diperlukan untuk update profil');
      return false;
    }
    return true;
  }

  Future<void> _updateUserDatabase(
      String userId, String name, String email, String noHandphone) async {
    await _databases.updateDocument(
      databaseId: databaseId,
      collectionId: profil,
      documentId: userId,
      data: {
        'name': name,
        'email': email,
        'noHandphone': noHandphone,
      },
    );
  }

  void _updateState(String name, String email, String noHandphone) {
    setState(() {
      _userName = name;
      _userEmail = email;
      _noHp = noHandphone;
      _isEditing = false;
    });
    _passwordController.clear();
  }

  void _showSuccessMessage() {
    _showSnackBar('Profil berhasil diperbarui');
  }

  Future<void> _handleEmailChange() async {
    await _account.deleteSession(sessionId: 'current');
    _showSnackBar('Email berhasil diperbarui. Silakan login kembali.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  void _handleUpdateError(dynamic error) {
    String errorMessage = 'Tidak dapat memperbarui profil';

    final errorString = error.toString();
    if (errorString.contains('user_target_already_exists')) {
      errorMessage = 'Email sudah digunakan oleh user lain';
    } else if (errorString.contains('user_invalid_credentials')) {
      errorMessage = 'Password salah';
    } else if (errorString.contains('user_invalid_email')) {
      errorMessage = 'Email tidak sesuai';
    }

    _showSnackBar(errorMessage);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      final inputFile = InputFile.fromPath(path: _imageFile!.path);

      final result = await _storage.createFile(
        bucketId: bucketId,
        file: inputFile,
        fileId: fileId,
      );

      setState(() {
        _profileImageUrl = _buildImageUrl(result.$id);
      });

      await _saveProfileImage(result.$id);
    } catch (e) {
      print('Tidak dapat mengunggah gambar: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    final user = await _account.get();
    if (user == null) return;

    try {
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: user.$id,
        data: {'profile_image': fileId},
      );
    } catch (e) {
      print('Tidak dapat menyimpan gambar: $e');
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _setControllerValues();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF0072BC),
      iconTheme: IconThemeData(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      title: Text('Akun', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileImage(),
              SizedBox(height: 50),
              _isEditing ? _buildEditForm() : _buildProfileView(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 60,
          child: _profileImageUrl != null
              ? CircleAvatar(
                  radius: 60, backgroundImage: NetworkImage(_profileImageUrl!))
              : const CircleAvatar(radius: 60, child: Icon(Icons.person)),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField(_nameController, 'Nama'),
        SizedBox(height: 10),
        _buildTextField(_emailController, 'Email', TextInputType.emailAddress),
        SizedBox(height: 10),
        _buildTextField(
            _noHandPhoneController, 'No Handphone', TextInputType.phone),
        SizedBox(height: 10),
        _buildTextField(_passwordController, 'Konfirmasi Password', null, true),
        SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType? keyboardType, bool obscureText = false]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _cancelEdit,
            child: Text('Batal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF8DC63F),
              elevation: 0,
              side: BorderSide(color: Color(0xFF8DC63F), width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _updateProfile,
            child: Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8DC63F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          _buildProfileSection('Nama', _userName ?? 'Guest'),
          SizedBox(height: 30),
          _buildProfileSection('Email', _userEmail ?? 'Guest'),
          SizedBox(height: 30),
          _buildProfileSection('No Handphone', _noHp ?? '-'),
          SizedBox(height: 40),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String label, String value) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF8DC63F)),
          ),
        ),
        _buildMenuItem(value),
        Divider(color: Colors.black, height: 0),
      ],
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isEditing = true;
        });
      },
      child: Text('Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF8DC63F),
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 15),
    );
  }
}
