import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _noHandPhoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _storage = Storage(_client);
    _account = Account(_client);
    _databases = Databases(_client);

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      _session = await _account.getSession(sessionId: 'current');
      _currentUser = await _account.get();

      final userId = _currentUser?.$id;
      if (userId != null) {
        final profileDoc = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: userId,
        );

        final profileImageId = profileDoc.data['profile_image'];
        if (profileImageId != null) {
          final fileViewUrl =
              'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/$profileImageId/view?project=$projectId';
          setState(() {
            _profileImageUrl = fileViewUrl;
          });
        }

        setState(() {});

        // Fetch username from a different collection
        final userNameDoc = await _databases.getDocument(
          databaseId: databaseId,
          collectionId:
              '684083800031dfaaecad', // Different collection for username
          documentId: userId,
        );

        final userName = userNameDoc.data['name'];
        final userEmail = userNameDoc.data['email'];
        final noHp = userNameDoc.data['noHandphone'];

        setState(() {
          _userName = userName;
          _userEmail = userEmail;
          _noHp = noHp;
        });

        // Set the text fields with the fetched data
        _nameController.text = _userName ?? '';
        _emailController.text = _userEmail ?? '';
        _noHandPhoneController.text = _noHp ?? '';
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final updatedName = _nameController.text.trim();
      final updatedEmail = _emailController.text.trim();
      final updatedNoHandphone = _noHandPhoneController.text.trim();
      final updatedPassword = _passwordController.text;

      // Validation
      if (updatedName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama tidak boleh kosong')),
        );
        return;
      }

      if (updatedEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email tidak boleh kosong')),
        );
        return;
      }

      if (updatedPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password diperlukan untuk update profil')),
        );
        return;
      }

      final user = await _account.get();
      if (user != null) {
        // Only update email if it's different from current email
        if (updatedEmail != _userEmail) {
          await _account.updateEmail(
            email: updatedEmail,
            password: updatedPassword,
          );
        }

        // Update the database
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: profil,
          documentId: user.$id,
          data: {
            'name': updatedName,
            'email': updatedEmail,
            'noHandphone': updatedNoHandphone,
          },
        );

        setState(() {
          _userName = updatedName;
          _userEmail = updatedEmail;
          _noHp = updatedNoHandphone;
          _isEditing = false;
        });

        // Clear password field
        _passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile berhasil diperbarui')),
        );

        // Only logout if email was changed
        if (updatedEmail != _userEmail) {
          await _account.deleteSession(sessionId: 'current');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email diperbarui. Silakan login kembali.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SplashScreen()),
          );
        }

        print("Profile updated successfully.");
      }
    } catch (e) {
      print('Error updating profile: $e');
      String errorMessage = 'Error updating profile';

      if (e.toString().contains('user_target_already_exists')) {
        errorMessage = 'Email sudah digunakan oleh user lain';
      } else if (e.toString().contains('user_invalid_credentials')) {
        errorMessage = 'Password salah';
      } else if (e.toString().contains('user_invalid_email')) {
        errorMessage = 'Format email tidak valid';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
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

      final fileViewUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${result.$id}/view?project=$projectId';

      setState(() {
        _profileImageUrl = fileViewUrl;
      });

      await _saveProfileImage(result.$id);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    final user = await _account.get();
    if (user != null) {
      try {
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.$id,
          data: {'profile_image': fileId},
        );
        print("Profile image updated in the database successfully.");
      } catch (e) {
        print('Error saving profile image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0072BC),
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Text('Akun', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      child: _profileImageUrl != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: NetworkImage(_profileImageUrl!))
                          : const CircleAvatar(
                              radius: 60, child: Icon(Icons.person)),
                    ),
                  ),
                ),
                SizedBox(height: 50),
                _isEditing
                    ? Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _noHandPhoneController,
                            decoration: InputDecoration(
                              labelText: 'No Handphone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      // Reset controllers to original values
                                      _nameController.text = _userName ?? '';
                                      _emailController.text = _userEmail ?? '';
                                      _noHandPhoneController.text = _noHp ?? '';
                                      _passwordController.clear();
                                    });
                                  },
                                  child: Text('Batal'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Color(0xFF8DC63F),
                                    elevation: 0,
                                    side: BorderSide(
                                      color: Color(0xFF8DC63F),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
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
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            // Section Nama
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Nama',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF8DC63F)),
                              ),
                            ),
                            _buildMenuItem(_userName ?? 'Guest'),
                            Divider(color: Colors.black, height: 0),
                            SizedBox(height: 30),

                            // Section Email
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF8DC63F)),
                              ),
                            ),
                            _buildMenuItem(_userEmail ?? 'Guest'),
                            Divider(color: Colors.black, height: 0),
                            SizedBox(height: 30),

                            // Section No Handphone
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No Handphone',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF8DC63F)),
                              ),
                            ),
                            _buildMenuItem(_noHp ?? '-'),
                            Divider(color: Colors.black, height: 0),

                            SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: Text('Edit Profile',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8DC63F),
                                  minimumSize: Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                          ],
                        ),
                      ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {Function()? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      title: Text(title),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.black,
        size: 15,
      ),
      onTap: onTap,
    );
  }
}
